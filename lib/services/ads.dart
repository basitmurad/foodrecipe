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
/// Release builds use the real ad units below; an empty ID turns that ad
/// type off. Debug and profile builds always use Google's test ads, so you
/// never tap your own live ads while developing (AdMob suspends accounts
/// for that). The AdMob *app* ID lives in android/gradle.properties.
class Ads extends ChangeNotifier {
  // Stepwise Kitchen ad units (AdMob → Apps → Stepwise Kitchen → Ad units).
  static const _bannerId = 'ca-app-pub-7477364225383856/6975107429';
  static const _interstitialId = 'ca-app-pub-7477364225383856/9437619236';

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

  /// The unit to request, or null if this ad type is off in this build.
  static String? _unit(String real, String testAndroid, String testIos) {
    if (!kReleaseMode) return Platform.isIOS ? testIos : testAndroid;
    return real.isEmpty ? null : real;
  }

  String? get bannerUnitId =>
      _unit(_bannerId, _testBannerAndroid, _testBannerIos);

  String? get _interstitialUnitId =>
      _unit(_interstitialId, _testInterstitialAndroid, _testInterstitialIos);

  /// Runs the consent flow, then initialises ads if allowed. Call after the
  /// first frame, because the consent form needs a visible activity.
  Future<void> start() async {
    if (!_enabled) return;
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
    final unit = _interstitialUnitId;
    if (!_ready || _interstitial != null || unit == null) return;
    InterstitialAd.load(
      adUnitId: unit,
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
    final unit = widget.ads.bannerUnitId;
    if (!mounted || !widget.ads.ready || unit == null) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width == _width) return;
    _width = width;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;
    _banner?.dispose();
    _loaded = false;
    _banner = BannerAd(
      adUnitId: unit,
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
