#!/usr/bin/env python3
"""Convert the UniTools World Recipes dataset into the app's recipe format.

Source:  https://github.com/farcrak/unitools-recipes (unitools-recipes-v1.json)
Licence: CC BY-SA 4.0 — "Recipe data: UniTools, CC BY-SA 4.0". The output file
         is an adaptation and is distributed under the same licence.

Usage:
    python3 tool/import_unitools.py path/to/unitools-recipes-v1.json

Writes assets/data/unitools-recipes.json. English text only; recipes that
duplicate one in assets/data/recipes.json are skipped.
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OURS = ROOT / 'assets/data/recipes.json'
OUT = ROOT / 'assets/data/unitools-recipes.json'

# --- categories --------------------------------------------------------------

SEAFOOD = {'fish', 'prawns', 'shrimp', 'salmon', 'cod', 'tuna', 'squid',
           'octopus', 'mussels', 'clams', 'crab', 'lobster', 'anchovies',
           'sardines', 'mackerel', 'herring', 'scallops', 'seabass', 'trout',
           'whitefish', 'saltcod', 'driedshrimp', 'catfish', 'tilapia',
           'snapper', 'eel', 'seafood', 'fishfillet', 'smokedfish', 'carp',
           'pike', 'perch', 'halibut', 'haddock', 'pollock', 'hake'}
POULTRY = {'chicken', 'chickenthighs', 'chickenbreast', 'chickenlegs',
           'wholechicken', 'chickenwings', 'hen'}
MEAT = {'beef', 'lamb', 'pork', 'mutton', 'veal', 'goat', 'bacon', 'porkbelly',
        'sausage', 'ham', 'mince', 'lard', 'chorizo', 'oxtail', 'liver',
        'venison', 'rabbit', 'duck', 'turkey', 'goose', 'minced', 'groundbeef',
        'porkshoulder', 'beefmince', 'lambmince', 'porkmince', 'ribs',
        'salo', 'pancetta', 'guanciale', 'offal', 'tripe', 'kidney', 'horse',
        'yak', 'camel', 'reindeer', 'elk', 'bone', 'marrowbone', 'brisket',
        'sirloin', 'steak', 'shank', 'shoulder', 'meat', 'blacksausage'}
NOODLE_WORDS = r'\b(pasta|spaghetti|noodles?|ramen|udon|soba|macaroni|lasagn[ae]|' \
               r'penne|tagliatelle|fettuccine|gnocchi|ravioli|vermicelli|' \
               r'linguine|orzo|pad thai|lo mein|chow mein|laksa|japchae|' \
               r'pho|bucatini|orecchiette|trofie|pappardelle|tortellini|' \
               r'rigatoni|fusilli|kuy teav|mee|mie|bihun|pancit)\b'


def category(r):
    c = r['category']
    if c == 'soup':
        return 'Soup'
    if c == 'dessert':
        return 'Dessert'
    if c in ('breakfast', 'drink'):
        return 'Breakfast'
    if c == 'bread':
        return 'Breads & Baking'
    if c in ('salad', 'side'):
        return 'Salads & Sides'
    if c in ('snack', 'sauce'):
        return 'Snacks & Sauces'
    # Main courses: sort by what the dish is built around.
    ids = {i['id'] for i in r['ingredients']}
    text = (r['name']['en'] + ' ' + ' '.join(i['name']['en'] for i in r['ingredients'])).lower()
    if re.search(NOODLE_WORDS, r['name']['en'].lower()) or \
            re.search(r'\b(spaghetti|pasta|noodles|udon|soba|ramen|macaroni|lasagne)\b', text):
        return 'Pasta & Noodles'
    if ids & SEAFOOD:
        return 'Seafood'
    if ids & POULTRY or re.search(r'\bchicken\b', text):
        return 'Chicken'
    if ids & MEAT or 'vegetarian' not in r['diets'] and 'vegan' not in r['diets'] \
            and re.search(r'\b(beef|lamb|pork|mutton|veal|meat|sausage|bacon)\b', text):
        return 'Meat'
    if 'vegetarian' in r['diets'] or 'vegan' in r['diets']:
        return 'Vegetarian'
    return 'Meat'


# --- emoji -------------------------------------------------------------------

# Checked in order against the dish name, then the summary, then ingredients.
NAME_RULES = [
    (r'\b(ramen|pho|laksa|udon|soba|noodle soup|kuy teav)\b', '🍜'),
    (r'\b(dumplings?|gyoza|momo|pelmeni|khinkali|manti|pierogi|vareniki|'
     r'jiaozi|mandu|wontons?|buuz|xiaolongbao|baozi|gua bao|siomay|shumai|chuchvara)\b', '🥟'),
    (r'\b(tacos?)\b', '🌮'),
    (r'\b(burritos?|shawarma|doner|gyros?|wraps?|durum)\b', '🌯'),
    (r'\b(tamales?)\b', '🫔'),
    (r'\b(pizza|lahmacun|pide|khachapuri)\b', '🍕'),
    (r'\b(burgers?|hamburger)\b', '🍔'),
    (r'\b(sandwich|banh mi|bocadillo|toast|tostada)\b', '🥪'),
    (r'\b(hot dogs?)\b', '🌭'),
    (r'\b(sushi|maki|sashimi|poke)\b', '🍣'),
    (r'\b(onigiri)\b', '🍙'),
    (r'\b(fondue|raclette)\b', '🫕'),
    (r'\b(curry|korma|vindaloo|masala|rendang|tikka|dal|dhal|daal|biryani|'
     r'massaman|sambar|vindalho|nihari|karahi|rogan josh|jalfrezi)\b', '🍛'),
    (r'\b(rice|paella|risotto|pilaf|plov|pilau|pulao|jollof|nasi|congee|'
     r'arroz|polo|kabsa|mandi|maqluba|machboos|bibimbap|jambalaya|onigiri|'
     r'donburi|katsudon|gyudon|oyakodon|thieboudienne|chelow|kedgeree)\b', '🍚'),
    (r'\b(spaghetti|pasta|lasagn[ae]|macaroni|gnocchi|penne|fettuccine|'
     r'tagliatelle|ravioli|tortellini|carbonara|bolognese|linguine|orzo|'
     r'bucatini|orecchiette|pappardelle|rigatoni|fusilli)\b', '🍝'),
    (r'\b(noodles?|pad thai|lo mein|chow mein|japchae|mee|mie|pancit|bihun)\b', '🍜'),
    (r'\b(salad|slaw|tabbouleh|fattoush|som tam|ensalada|salat|salata)\b', '🥗'),
    (r'\b(pancakes?|crepes?|crêpes?|blini|blinchiki|hotteok|dosa|injera|'
     r'syrniki|oladyi|palacinke|pannukakku|poffertjes|hoppers|appam|cachapa)\b', '🥞'),
    (r'\b(waffles?)\b', '🧇'),
    (r'\b(bagels?)\b', '🥯'),
    (r'\b(pretzels?|brezel)\b', '🥨'),
    (r'\b(croissants?)\b', '🥐'),
    (r'\b(flatbread|naan|roti|chapati|paratha|lavash|pita|tortillas?|'
     r'arepas?|pupusas?|msemen|bolani|gozleme|gözleme|lefse|puri|bhatura)\b', '🫓'),
    (r'\b(bread|loaf|baguette|focaccia|brioche|challah|sourdough|rolls?|'
     r'buns?|scones?|soda bread|cornbread|damper|pão|pan de|pan|chipa|'
     r'kulich|pogača|pogacha|borodinsky)\b', '🍞'),
    (r'\b(cheesecake)\b', '🍰'),
    (r'\b(cakes?|torte|gateau|gâteau|sponge|lamington|pavlova|tres leches|'
     r'napoleon|medovik|sachertorte|kuchen|bolo)\b', '🍰'),
    (r'\b(cupcakes?|muffins?)\b', '🧁'),
    (r'\b(pies?|tarts?|tarte|quiche|galette|pasty|pasties|börek|borek|burek|'
     r'banitsa|spanakopita|empanadas?|samosas?|pastel|pastilla|bastilla|'
     r'kurnik|pirozhki|piroshki|meat pie|strudel)\b', '🥧'),
    (r'\b(cookies?|biscuits?|shortbread|ma.amoul|alfajores?|kourabiedes|'
     r'polvorones|speculaas|pepparkakor|gingerbread)\b', '🍪'),
    (r'\b(puddings?|flan|custard|crème|creme|panna cotta|kheer|payasam|'
     r'sütlaç|sutlac|mahalabia|muhallebi|arroz con leche|brûlée|brulee|'
     r'malva|tapioca|che|bubur)\b', '🍮'),
    (r'\b(ice cream|gelato|kulfi|sorbet|halo-halo|halo halo|granita|'
     r'dondurma|paleta)\b', '🍨'),
    (r'\b(doughnuts?|donuts?|churros?|beignets?|loukoumades|sufganiyot|'
     r'berliner|malasadas?|bomboloni|puff-puff|puff puff|mandazi|'
     r'koeksisters?|jalebi|zalabia|oliebollen|chak-chak|chak chak|'
     r'gulab jamun|balushahi|sfenj|pączki|paczki|bunuelos|buñuelos)\b', '🍩'),
    (r'\b(chocolate|brigadeiros?|brownies?|truffles?)\b', '🍫'),
    (r'\b(baklava|halva|halwa|turkish delight|lokum|nougat|fudge|'
     r'barfi|burfi|ladoo|laddu|mochi|candy|toffee|brittle|pastila|'
     r'chikki|kaju katli|mithai)\b', '🍬'),
    (r'\b(falafel|fritters?|pakoras?|bhajis?|vadas?|akara|croquettes?|'
     r'kroketten|arancini|kibbeh|koftas?|köfte|kofte|patties|latkes?|'
     r'draniki|rösti|rosti|hash browns?|tod mun)\b', '🧆'),
    (r'\b(kebabs?|kabobs?|skewers?|satay|sate|shashlik|souvlaki|'
     r'yakitori|anticuchos?|suya|brochettes?|chuanr|khorovats|kababs?|'
     r'mtsvadi|seekh|shish|cevapi|ćevapi|cevapcici|mici|mititei)\b', '🍢'),
    (r'\b(omelet(te)?|frittata|tortilla española|eggs?|shakshuka|menemen|'
     r'huevos|tamagoyaki|chakchouka|kuku|kookoo|çılbır|cilbir)\b', '🍳'),
    (r'\b(porridge|oats|oatmeal|muesli|granola|kasha|grits|'
     r'champurrado|atole|mingau|genfo|ugali|nshima|pap|sadza|fufu|banku|'
     r'kenkey|polenta|mamaliga|mămăligă|tsampa|cou-cou|coucou)\b', '🥣'),
    (r'\b(tea|chai|tsai)\b', '🍵'),
    (r'\b(smoothie|lassi|shake|ayran|doogh|horchata|api|chicha|kvass|'
     r'kompot|drink|juice|lemonade|mors|sahlab|salep|boza)\b', '🥤'),
    (r'\b(stew|goulash|gulyás|gulasch|tagine|tajine|casserole|cassoulet|'
     r'bigos|chili|chilli|feijoada|pot|hotpot|hot pot|khoresh|khoresht|'
     r'ragout|ragù|ragu|daube|bourguignon|estofado|guisado|sancocho|'
     r'pepperpot|potjiekos|waterzooi|carbonnade|stifado|kapama|'
     r'chakhokhbili|chanakhi|azu|solyanka|shurpa|lagman|jjigae|jjim)\b', '🍲'),
    (r'\b(soup|borscht|borsch|broth|chowder|bisque|gazpacho|salmorejo|'
     r'caldo|sopa|shchi|okroshka|ukha|kharcho|harira|avgolemono|'
     r'minestrone|ribollita|pozole|menudo|sinigang|tom yum|tom kha|'
     r'miso|zurek|żurek|rassolnik|consommé|consomme|velouté|veloute|'
     r'potage|dashi|mulligatawny|callaloo|egusi|pepper soup|chorba|'
     r'çorba|corba|ciorbă|ciorba|juha|polévka|polevka|leves)\b', '🍲'),
    (r'\b(hummus|baba ghanoush|baba ganoush|mutabal|dip|tzatziki|'
     r'guacamole|salsa|pesto|chimichurri|sambol|sambal|ajvar|chutney|'
     r'raita|sauce|mole|aioli|toum|harissa|zhug|skhug|adjika|ajika|'
     r'tkemali|pebre|muhammara|tapenade|romesco|mojo|nuoc cham|'
     r'relish|pickles?|achar|atchar|kimchi|sauerkraut|lutenitsa|ljutenica)\b', '🥫'),
    (r'\b(prawns?|shrimps?|camarões|camarones|gambas)\b', '🍤'),
    (r'\b(crabs?)\b', '🦀'),
    (r'\b(lobsters?)\b', '🦞'),
    (r'\b(squid|octopus|calamari|pulpo|polbo)\b', '🦑'),
    (r'\b(oysters?|mussels?|clams?|moules|scallops?)\b', '🦪'),
    (r'\b(fish|cod|salmon|herring|ceviche|tuna|trout|mackerel|sardines?|'
     r'anchov(y|ies)|bacalhau|bacalao|gravlax|gravlaks|poisson|pescado|'
     r'carp|pike|eel|tilapia|catfish|snapper|sea bass|seabass|hake|'
     r'haddock|halibut|plaice|sole|kipper|lutefisk|rakfisk|surströmming)\b', '🐟'),
    (r'\b(chicken|duck|goose|turkey|hen|poulet|pollo|frango|coq|'
     r'yassa|tabaka|satsivi|chkmeruli)\b', '🍗'),
    (r'\b(bacon)\b', '🥓'),
    (r'\b(sausages?|bratwurst|wurst|chorizo|kielbasa|kiełbasa|boerewors|'
     r'longganisa|merguez|sucuk|lukanka|kupaty)\b', '🌭'),
    (r'\b(steak|beef|pork|lamb|mutton|veal|ribs|roast|meatballs?|'
     r'meatloaf|schnitzel|goulash|brisket|bulgogi|galbi|asado|churrasco|'
     r'carnitas|barbacoa|cochinita|lechon|lechón|adobo|rendang|'
     r'stroganoff|pot roast|rouladen|rinderrouladen|sauerbraten|'
     r'schweinshaxe|haxe|kotlet|kotlety|cutlets?|chops?|shank|'
     r'mechado|kaldereta|bistec|lomo|picanha|biltong|haggis|'
     r'dolma|dolmades|sarma|golubtsy|gołąbki|'
     r'stuffed cabbage|cabbage rolls?|stuffed peppers?)\b', '🥩'),
    (r'\b(fries|chips|frites)\b', '🍟'),
    (r'\b(potato(es)?|patatas|papas|kartoffel|gratin|pierogi ruskie|'
     r'colcannon|stamppot|rösti|poutine|aloo|batata)\b', '🥔'),
    (r'\b(corn|maize|elote|esquites|humitas?|cachapa|sadza)\b', '🌽'),
    (r'\b(avocado)\b', '🥑'),
    (r'\b(beans?|lentils?|chickpeas?|frijoles|ful|foul|feijão|feijao|'
     r'rajma|chana|chole|chholay|lobio|misir|mercimek|gigantes|'
     r'fasolada|fasole|pasulj|moros|gallo pinto|rice and peas|'
     r'red red|koshari|kushari|mujaddara)\b', '🫘'),
    (r'\b(cheese|halloumi|paneer|queso|fromage|syr|sirne|'
     r'mac and cheese|käsespätzle|kasespatzle)\b', '🧀'),
    (r'\b(mushrooms?|funghi|champignons?|porcini|chanterelles?)\b', '🍄'),
    (r'\b(aubergines?|eggplants?|brinjal|baingan|imam bayildi|'
     r'imam bayıldı|melitzanosalata|zaalouk|begun|moussaka|musaka)\b', '🍆'),
    (r'\b(tomato(es)?|pomodoro|tomate)\b', '🍅'),
    (r'\b(peppers?|paprika|lecsó|lecso|piperade|pimientos?)\b', '🫑'),
    (r'\b(cabbage|kale|spinach|greens|chard|collard|saag|palak|'
     r'callaloo|sukuma|efo|horta)\b', '🥬'),
    (r'\b(carrots?|gajar|morkov)\b', '🥕'),
    (r'\b(cucumbers?|pickled cucumbers?)\b', '🥒'),
    (r'\b(onions?)\b', '🧅'),
    (r'\b(garlic)\b', '🧄'),
    (r'\b(olives?)\b', '🫒'),
    (r'\b(coconut)\b', '🥥'),
    (r'\b(bananas?|plantains?|matoke|tostones|maduros|kelewele|alloco|'
     r'dodo|mofongo)\b', '🍌'),
    (r'\b(apples?)\b', '🍎'),
    (r'\b(pears?)\b', '🍐'),
    (r'\b(lemons?|limes?)\b', '🍋'),
    (r'\b(mangos?|mangoes)\b', '🥭'),
    (r'\b(peach(es)?|apricots?)\b', '🍑'),
    (r'\b(cherr(y|ies))\b', '🍒'),
    (r'\b(strawberr(y|ies))\b', '🍓'),
    (r'\b(blueberr(y|ies)|berr(y|ies)|lingonberr(y|ies)|cranberr(y|ies)|'
     r'bilberr(y|ies)|currants?)\b', '🫐'),
    (r'\b(pineapple)\b', '🍍'),
    (r'\b(grapes?)\b', '🍇'),
    (r'\b(melon|watermelon)\b', '🍉'),
    (r'\b(honey)\b', '🍯'),
    (r'\b(peanuts?|groundnuts?)\b', '🥜'),
    (r'\b(chestnuts?)\b', '🌰'),
    (r'\b(sweet potato|yam|cassava|taro)\b', '🍠'),
    (r'\b(broccoli)\b', '🥦'),
    (r'\b(herbs?|parsley|dill|basil|mint|sorrel)\b', '🌿'),
    (r'\b(chil(l)?i|jalape[nñ]o|habanero|scotch bonnet|peri-peri|piri piri)\b', '🌶️'),
    (r'\b(tofu|tempeh)\b', '🍱'),
    (r'\b(bento|teishoku)\b', '🍱'),
    (r'\b(egg|eggs)\b', '🥚'),
]

INGREDIENT_RULES = [
    (SEAFOOD & {'prawns', 'shrimp', 'driedshrimp'}, '🍤'),
    ({'squid', 'octopus'}, '🦑'),
    ({'crab'}, '🦀'),
    ({'mussels', 'clams', 'scallops'}, '🦪'),
    (SEAFOOD, '🐟'),
    (POULTRY | {'duck', 'turkey', 'goose'}, '🍗'),
    (MEAT, '🥩'),
    ({'rice', 'basmati', 'jasminerice', 'shortgrainrice', 'glutinousrice'}, '🍚'),
    ({'lentils', 'redlentils', 'chickpeas', 'beans', 'blackbeans',
      'kidneybeans', 'whitebeans', 'favabeans', 'mungbeans', 'blackeyedpeas'}, '🫘'),
    ({'potato', 'potatoes'}, '🥔'),
    ({'aubergine', 'eggplant'}, '🍆'),
    ({'mushrooms'}, '🍄'),
    ({'cheese', 'feta', 'halloumi', 'paneer', 'cottagecheese', 'tvorog',
      'ricotta', 'mozzarella', 'parmesan', 'sulguni', 'brynza'}, '🧀'),
    ({'cabbage', 'spinach', 'kale'}, '🥬'),
    ({'egg', 'eggs'}, '🍳'),
    ({'corn', 'cornmeal', 'maize', 'masa', 'masaharina'}, '🌽'),
    ({'plantain', 'banana', 'bananas'}, '🍌'),
    ({'apple', 'apples'}, '🍎'),
    ({'tomato', 'tomatoes'}, '🍅'),
    ({'coconutmilk', 'coconut'}, '🥥'),
    ({'flour', 'yeast'}, '🍞'),
]

CATEGORY_EMOJI = {
    'Breakfast': '🍳', 'Chicken': '🍗', 'Meat': '🥩', 'Seafood': '🐟',
    'Vegetarian': '🥦', 'Pasta & Noodles': '🍝', 'Soup': '🍲',
    'Salads & Sides': '🥗', 'Snacks & Sauces': '🥫', 'Breads & Baking': '🍞',
    'Dessert': '🍰',
}


def _match_text(text):
    t = text.lower()
    for pattern, e in NAME_RULES:
        if re.search(pattern, t):
            return e
    return None


def _match_ingredients(ids, rules):
    for group, e in rules:
        if ids & group:
            return e
    return None


PROTEIN_RULES = INGREDIENT_RULES[:7]  # seafood, poultry and meat groups


def emoji(r, cat):
    ids = {i['id'] for i in r['ingredients']}
    # The dish name is the most reliable signal, then its native name.
    found = _match_text(r['name']['en']) or _match_text(r.get('nativeName') or '')
    # For meat, chicken and seafood mains, the protein beats words in the
    # summary (which often mentions sides: "...served with dumplings").
    if not found and cat in ('Meat', 'Chicken', 'Seafood'):
        found = _match_ingredients(ids, PROTEIN_RULES)
    return (found
            or _match_text(r['summary']['en'])
            or _match_ingredients(ids, INGREDIENT_RULES)
            or CATEGORY_EMOJI[cat])


# --- ingredients -------------------------------------------------------------

FRACTIONS = {0.25: '¼', 0.33: '⅓', 0.5: '½', 0.67: '⅔', 0.75: '¾'}
COUNTABLE = {  # unit -> (singular, plural)
    'clove': ('clove', 'cloves'),
    'sprig': ('sprig', 'sprigs'),
    'slice': ('slice', 'slices'),
    'pinch': ('pinch', 'pinches'),
}


def fmt_number(q, allow_fraction=True):
    if q is None:
        return ''
    whole = int(q)
    frac = round(q - whole, 2)
    if frac == 0:
        return str(whole)
    if allow_fraction and frac in FRACTIONS:
        return (str(whole) if whole else '') + FRACTIONS[frac]
    return f'{q:g}'


def measure(i):
    q, unit = i['quantity'], i['unit']
    if unit == 'toTaste' or q is None:
        return 'To taste'
    if unit in ('g', 'ml', 'kg', 'l'):
        return f'{fmt_number(q, allow_fraction=unit in ("kg", "l"))} {unit}'
    if unit in ('tbsp', 'tsp'):
        return f'{fmt_number(q)} {unit}'
    if unit == 'piece':
        return fmt_number(q)
    if unit in COUNTABLE:
        one, many = COUNTABLE[unit]
        return f'{fmt_number(q)} {one if q <= 1 else many}'
    return f'{fmt_number(q)} {unit}'


def title_case(name):
    # UniTools uses sentence case ("Spaghetti carbonara"); match the app's titles.
    small = {'a', 'an', 'and', 'or', 'of', 'the', 'with', 'in', 'on', 'al',
             'alla', 'de', 'del', 'di', 'la', 'le', 'con', 'en', 'au', 'aux',
             'à', 'e', 'y', 'da', 'do', 'dos', 'das', 'el', 'los', 'las',
             'na', 'ne', 'ni', 'no', 'ya', 'wa', 'za', 'po', 'na', 'z', 'ze',
             'i', 'u', 's', 'v', 've', 'och', 'og', 'met', 'mit', 'und',
             'van', 'von', 'der', 'des', 'du', 'et', 'ou', 'com', 'sa', 'ng',
             'ke', 'ki', 'ka', 'ko', 'o'}
    words = name.split(' ')
    out = []
    for n, w in enumerate(words):
        if n and w.lower() in small:
            out.append(w.lower())
        elif w[:1].islower():
            out.append(w[:1].upper() + w[1:])
        else:
            out.append(w)
    return ' '.join(out)


def normalise(s):
    return re.sub(r'[^a-z]', '', s.lower())


def convert(src):
    data = json.loads(Path(src).read_text())
    cuisines = {c['code']: re.sub(r'\s+cuisine$', '', c['cuisine']['en']).strip()
                for c in data['countries']}
    countries = {c['code']: c['name']['en'] for c in data['countries']}
    ours = json.loads(OURS.read_text())['recipes']
    our_names = [normalise(r['name']) for r in ours]

    recipes, skipped = [], []
    for r in data['recipes']:
        n = normalise(r['name']['en'])
        if any(n in o or o in n for o in our_names):
            skipped.append(r['name']['en'])
            continue
        cat = category(r)
        cuisine = cuisines.get(r['country'], countries.get(r['country'], 'International'))
        tags = [{'vegetarian': 'Vegetarian', 'vegan': 'Vegan',
                 'gluten-free': 'Gluten-free', 'pescatarian': 'Pescatarian'}[d]
                for d in r['diets']]
        if r['prepMinutes'] + r['cookMinutes'] <= 30:
            tags.append('Quick')
        ingredients = []
        for i in r['ingredients']:
            entry = [measure(i), i['name']['en']]
            note = (i.get('note') or {}).get('en')
            if note:
                entry.append(note)
            ingredients.append(entry)
        n_per = r['nutritionPerServing']
        recipes.append({
            'id': 'ut-' + r['slug'],
            'name': title_case(r['name']['en']),
            'nativeName': r.get('nativeName'),
            'category': cat,
            'cuisine': cuisine,
            'emoji': emoji(r, cat),
            'prepMinutes': r['prepMinutes'],
            'cookMinutes': r['cookMinutes'],
            'servings': r['baseServings'],
            'difficulty': r['difficulty'].capitalize(),
            'tags': tags,
            'description': r['summary']['en'],
            'ingredients': ingredients,
            'steps': [s['text']['en'] for s in r['steps']],
            'stepMinutes': [s.get('minutes') for s in r['steps']],
            'nutrition': {
                'calories': n_per['calories'],
                'protein': n_per['protein'],
                'fat': n_per['fat'],
                'carbs': n_per['carbs'],
            },
            'source': {'name': 'UniTools', 'url': r['url']},
        })
        if not recipes[-1]['nativeName'] or \
                normalise(recipes[-1]['nativeName']) == normalise(recipes[-1]['name']):
            del recipes[-1]['nativeName']

    out = {
        'source': {
            'name': 'UniTools World Recipes',
            'version': data['version'],
            'homepage': data['homepage'],
            'license': 'CC BY-SA 4.0',
            'licenseUrl': 'https://creativecommons.org/licenses/by-sa/4.0/',
            'attribution': 'Recipe data: UniTools (theunitools.com), CC BY-SA 4.0',
            'changes': 'English text only; converted to the app format; '
                       'categories, emoji and tags added; quantities formatted; '
                       'duplicates of the app\'s own recipes removed.',
        },
        'recipes': recipes,
    }
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1) + '\n')
    return recipes, skipped


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    recipes, skipped = convert(sys.argv[1])
    print(f'Wrote {len(recipes)} recipes to {OUT.relative_to(ROOT)}; '
          f'skipped {len(skipped)} duplicates: {", ".join(skipped)}')
