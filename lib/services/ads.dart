import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Decides when a full-screen ad may show: at most once per [every] recipes
/// closed, and never within [cooldown] of the previous one.
class InterstitialPacer {
  final int every;
  final Duration cooldown;
  final DateTime Function() _now;
  int _sinceLast = 0;
  DateTime? _lastShown;

  InterstitialPacer({
    this.every = 4,
    this.cooldown = const Duration(minutes: 3),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Records a closed recipe; returns true if an ad should show now.
  bool recipeClosed() {
    _sinceLast++;
    final last = _lastShown;
    return _sinceLast >= every &&
        (last == null || _now().difference(last) >= cooldown);
  }

  void markShown() {
    _sinceLast = 0;
    _lastShown = _now();
  }
}

/// AdMob ads: a bottom banner, plus an occasional full-screen ad when the user
/// leaves a recipe. Ads are only requested after Google's consent flow (UMP)
/// says it's allowed.
///
/// Real ad unit IDs are passed at build time and used only in release builds:
///   flutter build appbundle --release \
///     --dart-define=ADMOB_BANNER_ID=ca-app-pub-xxx/yyy \
///     --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-xxx/zzz
/// Debug builds, and release builds without those defines, use Google's test
/// IDs, so you never click your own live ads while developing.
class Ads extends ChangeNotifier {
  static const _bannerId = String.fromEnvironment('ADMOB_BANNER_ID');
  static const _interstitialId = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');

  // https://developers.google.com/admob/android/test-ads
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/9214589741';
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2435281174';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

  final bool _enabled;
  bool _ready = false;
  bool _privacyOptionsRequired = false;
  InterstitialAd? _interstitial;
  final _pacer = InterstitialPacer();

  Ads() : _enabled = true;

  /// No ads at all, for tests.
  Ads.disabled() : _enabled = false;

  /// True once consent allows ads and the SDK is initialised.
  bool get ready => _ready;

  /// Whether the About screen must offer "Ad privacy settings" (e.g. in the EEA/UK).
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  static bool get _useRealIds =>
      kReleaseMode && _bannerId.isNotEmpty && _interstitialId.isNotEmpty;

  String get bannerUnitId => _useRealIds
      ? _bannerId
      : (Platform.isIOS ? _testBannerIos : _testBannerAndroid);

  String get _interstitialUnitId => _useRealIds
      ? _interstitialId
      : (Platform.isIOS ? _testInterstitialIos : _testInterstitialAndroid);

  /// Runs the consent flow, then initialises ads if allowed. Call after the
  /// first frame, because the consent form needs a visible activity.
  Future<void> start() async {
    if (!_enabled) return;
    if (kReleaseMode && !_useRealIds) {
      debugPrint('Ads: release build without ADMOB_* ids, showing test ads.');
    }
    // Consent from a previous session may already allow ads.
    await _initialiseIfAllowed();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((error) {
              if (error != null) {
                debugPrint('Ads: consent form: ${error.message}');
              }
            });
          } catch (e) {
            debugPrint('Ads: consent form failed: $e');
          }
          await _initialiseIfAllowed();
        },
        (error) async {
          debugPrint('Ads: consent update failed: ${error.message}');
          await _initialiseIfAllowed();
        },
      );
    } catch (e) {
      debugPrint('Ads: consent unavailable: $e');
    }
  }

  /// Ads must never break the app: any SDK or plugin failure (for example a
  /// MissingPluginException after a hot restart) just means no ads.
  Future<void> _initialiseIfAllowed() async {
    try {
      _privacyOptionsRequired = await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      if (!_ready && await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.initialize();
        _ready = true;
        _loadInterstitial();
      }
    } catch (e) {
      debugPrint('Ads: not available: $e');
    }
    notifyListeners();
  }

  /// Lets the user review or change their ad consent.
  Future<void> showPrivacyOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) debugPrint('Ads: privacy options: ${error.message}');
      });
    } catch (e) {
      debugPrint('Ads: privacy options unavailable: $e');
    }
    await _initialiseIfAllowed();
  }

  void _loadInterstitial() {
    if (!_ready || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) =>
            debugPrint('Ads: interstitial failed: ${error.message}'),
      ),
    );
  }

  /// Called when the user leaves a recipe page, which is a natural break.
  /// Shows a full-screen ad only if enough recipes and time have passed.
  void onRecipeClosed() {
    if (!_ready) return;
    final due = _pacer.recipeClosed();
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    if (!due) return;
    _interstitial = null;
    _pacer.markShown();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }
}

/// Anchored adaptive banner. Takes no space until an ad has loaded, and
/// shows nothing when ads are disabled or not yet allowed.
class AdBanner extends StatefulWidget {
  final Ads ads;

  const AdBanner({super.key, required this.ads});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _banner;
  bool _loaded = false;
  int? _width;

  @override
  void initState() {
    super.initState();
    widget.ads.addListener(_maybeLoad);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoad();
  }

  Future<void> _maybeLoad() async {
    if (!mounted || !widget.ads.ready) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width == _width) return;
    _width = width;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;
    _banner?.dispose();
    _loaded = false;
    _banner = BannerAd(
      adUnitId: widget.ads.bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _banner = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    widget.ads.removeListener(_maybeLoad);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!_loaded || banner == null) return const SizedBox.shrink();
    return SizedBox(
      width: banner.size.width.toDouble(),
      height: banner.size.height.toDouble(),
      child: AdWidget(ad: banner),
    );
  }
}
