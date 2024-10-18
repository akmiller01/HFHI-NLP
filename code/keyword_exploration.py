from datasets import Dataset, load_dataset
from sklearn.feature_extraction.text import TfidfVectorizer
import numpy as np
import nltk
import re
from sklearn.feature_extraction.text import TfidfVectorizer
from nltk.corpus import stopwords
import pandas as pd

# import nltk
# nltk.download('punkt_tab')


def remove_string_special_characters(s):
    # removes special characters with ' '
    stripped = re.sub(r'[^\w\s]', ' ', s)

    # Change any white space to one space
    stripped = re.sub('\s+', ' ', stripped)

    # Remove start and end white spaces
    stripped = stripped.strip()
    if stripped != '':
            return stripped.lower()
    
def remove_stop_words(s):
    stop_words = set(stopwords.words('english')) | set(stopwords.words('spanish')) | set(stopwords.words('french')) | set(stopwords.words('german'))
    try:
        return ' '.join([word for word in nltk.word_tokenize(s) if word not in stop_words])
    except TypeError:
         return ' '
    

def features(vectorizer, result):
    feature_array = np.array(vectorizer.get_feature_names_out())
    flat_values = result.toarray().flatten()
    zero_indices = np.where(flat_values == 0)[0]
    tfidf_sorting = np.argsort(flat_values)[::-1]
    masked_tfidf_sorting = np.delete(tfidf_sorting, zero_indices, axis=0)

    return feature_array[masked_tfidf_sorting].tolist()


def clean_text(example):
    textual_data_list = [
        example['project_title'],
        example['short_description'],
        example['long_description']
    ]
    textual_data_list = [str(textual_data) for textual_data in textual_data_list if textual_data is not None]
    text = " ".join(textual_data_list)
    example['text'] = remove_stop_words(remove_string_special_characters(text))
    return example



dataset = load_dataset("csv", data_files="large_input/crs_text_2018_2022.csv", split="train")
dataset = dataset.map(clean_text, num_proc=8, remove_columns=['project_title', 'short_description', 'long_description'], new_fingerprint="abdce")

# De-duplicate
df = pd.DataFrame(dataset)
print(df.shape)
df = df.drop_duplicates(subset=['text'])
print(df.shape)
dataset = Dataset.from_pandas(df, preserve_index=False)

basic_keywords = ['housing', 'informal settlement', 'slum', 'shelter']

housing = dataset.filter(lambda example: any([keyword in example['text'] for keyword in basic_keywords]))

# housing = dataset.filter(lambda example: example['purpose_code'] in [16030, 16040])

vectorizer = TfidfVectorizer(ngram_range=(2, 2))
vectorizer.fit(dataset['text'])


housing_result = vectorizer.transform([" ".join(housing['text'])])
top_housing = features(vectorizer, housing_result)
top_housing = top_housing[:250]


print("Housing frequent words:\n")
print(top_housing)

# By purpose code (16030, 16040)
## ngram (1, 1)
## ['housing', 'urban', 'construcción', 'digna', 'capacities', 'enhancing', 'network', 'specifically', 'sostenibles', 'conocimiento', 'nombre', 'expansion', 'divers', 'mtptc', 'mobilisation', 'proceeds', '90', 'totogalpa', 'georgia', 'éstas', 'exchanges', 'khc', 'nadacia', 'fikri', 'simbólicos', 'largo', 'edificaciones', 'mts', 'montevideo', 'spatiale', 'especificos', 'quedando', 'erupción', 'éstos', 'resistance', 'podgorica', 'empleadores', 'privatization', 'paving', 'estudiante', 'coop', 'impactos', 'juridique', 'placed', 'must', 'latrines', 'tratarla', 'hombresen', 'czz2111', 'plusvalã', 'critieria', 'enteros', 'relacionesfamiliares', 'means', 'oga', 'dalmatia', 'scetor', 'patronato', 'súas', 'jacques', 'periferia', 'zdrowotnej', '184', 'metodológica', 'comprendidas', 'ésta', 'revitalizing', 'representan', 'builders', 'diez', 'smartphone', 'andaluces', 'actrices', 'especialización', 'vient', 'bloque', 'mohammed', 'sr', 'estancia', 'rencontres', 'fabrication', 'eg', 'upstream', 'développées', 'emergencias', 'accomplished', 'budgets', 'toward', 'educativo', 'advice', 'agreements', 'enreda', 'enrichments', 'enrollment', 'entraîneurs', 'entra', 'entr', 'entregaría', 'enterotoxaemia', 'ensurig', 'enterpries', 'enterprenurial', 'czz2658', 'entfernung', 'enmatériels', 'ennuestro', 'engagementer', 'eraturi', 'erhalten', 'equilibrium', 'equilibriosocial', 'czm1011', 'czerwca', 'equipoeuropa', 'erythree', 'esa6', 'ersetzt', 'escal', 'escalonadas', 'errichtet', 'erradicação', 'environnementaux', 'environnment', 'envoie', 'entrevoir', 'eolienne', 'eowe', 'eov', 'electrifikation', 'electrònica', 'electroencephalogram', 'electroencephalog', 'electrophoresis', 'elaborate', 'elaborat', 'dalla', 'eksportu', 'elabor', 'elbahrawy', 'elektro', 'elisée', 'elkartasunak', 'elkartasuna', 'elkaar', 'daholobe', 'ellaspara', 'ellun', 'dakma', 'elektroniczny', 'elhorario', 'elgobaa', 'elevados', 'elfin', 'egyptalum', 'eiaidmp', 'damns', 'eficiência', 'egne', 'eksperckie', 'ekologistak', 'ekologii', 'einterrelacionar', 'eijkelkamp', 'ejecutandoasocolvas', 'emsf', 'emprunteur', 'enacting', 'enakopravnih', 'empoderamientoen', 'daame', 'emprenderlas', 'd8', 'côtes', 'endangere', 'encounter', 'endommagée', 'endosomal', 'endoscopy', 'encargó', 'encargos', 'encajan', 'enconomic', 'enclavées', 'dagga', 'embattled', 'dafc', 'embriones', 'emcc', 'elásticos', 'elrp', 'embalse', 'embaglio', 'emigrante', 'f21ap01545', 'fa10232517', 'f9', 'extrapolate', 'extremidad', 'facilities4', 'faciltiate', 'faciltation', 'faciltate', 'facilityate', 'currículo', 'facilite', 'fading', 'fadel', 'fadcanic', 'fables', 'curumbá', 'fa9415023', 'cursus', 'facente', 'fasrb', 'fasoespecífico', 'fasting', 'fasi', 'fapiz', 'fandora', 'fancs', 'fang', 'curables', 'fanm', 'farinha', 'farmacéuticas', 'farmacológicala', 'farmaco', 'cupboard', 'faragouaran', 'farafina', 'faracho', 'farabi', 'fardeaux', 'estils', 'estimulan', 'esterilizador', 'esterilización', 'estereotipadas', 'cy2019', 'estiamte', 'estevanell', 'estrategiasprincipales', 'estratategia', 'estrangers', 'estrattivo', 'estirpe', 'estimulándose', 'estoimatifs', 'estampadas', 'estambul']

## ngram (2, 2)
## ['municipal development', 'land surface', 'complex qasar', 'san juan', 'core 2019', 'sanitation impoverished', 'expenditure strengthening', 'urbamonde sénégal', 'delivery installation', 'construction materials', 'citizens bosnia', 'involuntary resettlement', 'neighbourhoods along', 'blocoplastico project', 'habitat related', 'two slum', 'green asean', 'team technicians', 'promoting habitat', 'familiares mismo', 'recycling resources', 'socioeconomic development', 'desarrollo proyecto', 'verification contract', 'community siddarampuram', 'part funding', 'assistance support', 'drafts tor', 'within cooperating', 'mub management', 'diagnóstico criterios', 'patronato municipal', 'institution housing', 'cuanto reducción', 'así romper', 'urbano edu', 'tecnológicos generación', 'quedando desarrollar', 'temat uprawy', 'incrementando llegar', 'conjuntamente dirección', 'uzbekistan social', 'system neighborhood', 'area intermediate', 'municipalities kumanovo', 'inclusion investments', 'rural japla', 'apartadó mejora', 'letrinas constituyendo', 'comunidades cubana', 'zwiekszenie wiedzy', 'system adb', 'casado elias', 'salut proyecto', 'companies co', 'bio construction', 'beneficiarias podrán', 'dhaka construction', 'inhabitants south', 'total 160', 'funding improvement', 'risk provision', 'communities indirect', 'morocco energy', '48 mujeres', 'coste total', '2017 main', 'activities include', 'chaînes production', 'resto población', 'government salvador', 'finance market', 'including global', 'improvement social', 'economic challenges', 'coastal marine', 'sector specific', 'personnes besoin', 'equality gender', 'environnement adoptent', 'environnement selon', 'equality accession', 'environnement cela', 'environnement socioculturel', 'equality granting', 'environnement jeunesse', 'environnement instable', 'equality coverage', 'environments actors', 'environments activity', 'equally emphasized', 'equally afcfta', 'environments construction', 'equi bureau', 'environments stories', 'equality pro', 'environments senegal', 'environnantes activités', 'equality koloriang', 'environments wide', 'environments iran', 'equality volunteer', 'equality reduces', 'environments middle', 'equality rural', 'enza goal', 'epidemic community', 'epd afines', 'epa com', 'epa business', 'epi formation', 'eo left', 'eo ir', 'eom albania', 'epsg 2022', 'eprisecab eprisecab', 'environnementaux considérables', 'environnemental missions', 'environnemental brings', 'environnementale centre', 'environnementale alimentaire', 'eqpts entret', 'envisages accountable', 'environnemtale sociale', 'epmc 532596', 'envisage contribuer', 'envisage consolidation', 'entonces prioritariamente', 'entorns saludables', 'entrada pandillas', 'entorno minería', 'entornos digitales', 'entitats feministes', 'entitled uchaguzi', 'entity execution', 'entitled bringing', 'entrepreneuralism facilitiate', 'entrepreneurs businesswomen', 'entrepreneurs filière', 'entrepreneuriat renforcement', 'entrepreneurs 955', 'entrepreneurs 85', 'entraîné mort', 'entregados proyectos', 'entrave accès', 'entreprenariat formation', 'entremujeres hombres', 'enteras visto', 'enterprise reconstruction', 'ensuring long', 'entenderse sujetos', 'entails opds', 'entier pays', 'enterprises activities', 'enterprises kenya', 'enterprises main', 'enterprises program', 'environ nementaux', 'environment ac_764_3', 'environment addressing', 'environmental behaviour', 'environment today', 'environment tougtuang', 'environment yemen', 'environmental licensing', 'environmental physical', 'environmental performance', 'environmental liability', 'environment portuguese', 'environment needed', 'environment serbia', 'environment sidi', 'environment think', 'environment sweden', 'environment proyecto', 'entrepreneurs merchants', 'entrepreneurs wgdp', 'entrepreneurship achieving', 'entrepreneurship age', 'entreprises technologiques', 'entretantos huerta', 'entretien sous', 'entretien hygiène', 'espèces plus', 'esri establish', 'ess tánger', 'ess preveu', 'espera establecido', 'esperados proyecto', 'establecemos modelo', 'essex ohchr', 'essentiels secteur', 'estabilidad área', 'essential preserve', 'essential pillar', 'essential sexual', 'essential enabler', 'essential keep', 'essentielles noix', 'essentielles centres', 'essentiels neuf', 'essentials modern', 'essentiel expliquer', 'especializados gestión', 'especially hiv', 'especially femal', 'especially concerning', 'espectacle música', 'especialmente proveniente', 'especialmente significativo', 'específico fortalecimeinto', 'especially regular', 'especially relate', 'especially rights', 'especially returning', 'especially resurgence', 'especially solar', 'especialmente dan', 'especialmente oportuno', 'estimado producción', 'estima aumento', 'estelí autoridades', 'establishment multi', 'establishments thailand', 'estimating total', 'estonian tax', 'estonian supporters', 'estrada abertura', 'estr health', 'estosobjetivos desarrollar', 'estonia learn', 'estimate inca', 'estimate etb', 'estimates 310', 'estimated clf', 'established cases', 'established procedures', 'establish resistant', 'establish identification', 'establishment caricom', 'establishment improved', 'establishment habitat', 'establishment fisheries', 'establishing centers', 'establishing 14', 'establishing heating', 'establishing formalising', 'equipts securite', 'equitable health', 'equipping testing']

# By basic keywords ['housing', 'informal settlement', 'slum', 'shelter']
## ngram (1, 1)
## ['housing', 'shelter', 'cities', 'population', 'réfugiés', 'income', 'city', 'state', 'legal', 'iraq', 'build', 'inl', 'design', 'critical', 'knowledge', 'pakistan', 'challenges', 'core', 'gaza', 'touchées', 'beneficiaries', 'respond', 'personas', 'form', 'disabilities', 'drc', 'centers', 'decision', '500', 'governments', 'covered', 'mothers', 'would', 'identify', 'ocean', 'squatter', 'hum', 'nfis', 'package', 'mexico', 'collective', 'base', '15', 'active', 'unaccompanied', 'aids', 'smart', 'fourniture', 'derechos', 'nombre', 'alternative', 'cases', 'experiences', 'various', 'zimbabwe', 'scheme', 'contributing', 'owned', '2013', 'facilitating', 'known', 'coastal', 'ainsi', 'widespread', 'generate', 'vénézuéliens', 'resistant', 'proposes', 'plant', 'liberia', 'survival', 'lima', 'sauver', 'output', 'cohesion', 'gangs', 'increases', 'prestation', 'map', 'disciplinary', 'plusieurs', 'sistema', 'diagnosis', 'assets', 'cap', 'akkar', 'modern', 'aged', 'nationals', '90', 'territories', 'movement', 'actively', 'aida', 'trans', 'commun', '58', 'additionally', 'neighbourhood', 'companies', 'sustenance', 'reported', 'sickle', 'égalité', 'regulatory', 'days', 'pro', 'upv', 'hub', 'clear', 'directorate', 'commitments', 'projekt', 'lateral', 'mejoradas', 'karabakh', 'tiempo', 'secretariat', 'longstanding', 'patterns', 'fondamentaux', 'abilities', 'white', 'strategically', 'whole', 'indirect', 'países', 'wide', 'losses', 'dominican', 'batey', 'construir', 'efectivo', 'either', 'forma', 'orphanage', 'grave', 'tonga', 'australia', 'peshkopi', 'net', 'kyrgyz', 'donner', 'impaired', 'rude', 'treating', 'mnt', 'manila', 'daesh', 'thinking', 'posed', 'oversight', 'administering', 'secteurs', 'dac', 'obra', 'died', 'commodity', 'collectives', 'luhansk', 'poorly', 'hostilities', 'relevance', 'favoriser', 'vers', 'gran', 'cum', 'comes', 'lieu', 'supplied', 'aldeas', 'blanket', 'durres', 'beneficjentów', 'malnourished', 'complexe', 'kukula', 'juja', 'adamwa', 'hpp', 'tneps', 'dcap', 'planners', 'activism', 'length', 'sccs', 'mulemba', 'mochila', 'sécuritaires', 'rdt', 'ciutat', 'followed', 'night', 'cuales', 'trauma', 'escolar', 'adapting', 'sixth', 'outils', 'supportive', 'paving', 'chittagong', 'concernées', 'usg', 'marawi', 'shade', 'garments', 'painting', 'implements', 'question', 'nuevos', 'dedicated', 'ajouter', 'gis', '1yr', 'consolidate', 'krisan', 'accommodations', 'settle', 'temas', 'puerto', 'compare', 'began', 'lucia', 'usage', 'defensa', 'british', 'outre', 'accés', 'niño', 'interpreting', 'individuales', 'geneva', 'screened', 'ngwerere', 'taxing', 'quotas', 'lbn', 'smoke', 'christmas', 'specialization', 'taxation', 'délivrance', 'guajira', 'raqqa', 'codes', 'pregnancies', 'dri', 'desaster', 'jawf']

## ngram (2, 2)
## ['enabled adopt', 'wash shelter', 'emergency food', 'health care', 'women girls', 'urban development', 'three million', 'protection needs', 'paid work', 'program provide', 'durable mali', 'housing rights', 'disaster preparedness', 'near eastern', 'construction social', 'shelter access', 'croix rouge', 'bae org', 'conflict drought', 'affected population', 'long term', 'housing welcome', 'populations affected', 'assistance build', 'burkina faso', 'classified subobject', 'non alimentaires', 'displaced populations', 'relief early', 'women families', 'housing vulnerable', 'sexual violence', 'social economic', 'economic recovery', 'women shelter', 'children youth', 'support vulnerable', 'disaster conflict', 'venezuela crisis', 'affected conflict', 'refugees host', 'refugees asylum', 'owned effective', 'republic congo', 'health nutrition', 'redacted housing', 'vulnerable families', 'refugees vulnerable', 'families rural', 'health wash', 'service delivery', 'victims trafficking', 'rights defenders', 'national housing', 'construction shelter', 'saving assistance', 'private sector', 'prevention response', 'response conflict', 'usaid ofda', 'displacement affected', 'pavement squatter', 'efficient housing', '500 000', 'efsp 2017', '2018 2022', 'quality programming', 'change results', 'climate resilient', 'sectoral humanitarian', 'mercy corps', 'vat bureau', 'protection support', 'leurs besoins', 'reconstruction project', 'including health', 'basic assistance', 'familias pertenecientes', 'increasing access', 'shelter training', 'assistance including', 'housing community', 'vicitms worldwide', 'states population', 'support providing', 'emergency shelters', 'affected typhoon', 'access education', 'situation humanitaire', 'support government', 'urban rural', 'specific objective', 'humanitaire crise', '2021 2025', 'access safe', 'sierra leone', 'india título', 'agriculture food', 'protection emergency', 'rehabilitation housing', 'safe shelter', 'donor country', '2017 award', 'south west', 'headed households', 'meet needs', 'yemen emergency', 'financial resources', 'habitat agenda', 'housing management', 'fund ocha', 'autres articles', 'intérieur pays', 'ofda grant', 'march 2019', 'sudden needs', 'dar albaraka', 'inl covers', 'acute unmet', 'forge peaceful', 'financial sector', 'refugee crisis', 'life skills', 'populations nigeria', 'accueillir plus', 'provision basic', 'nbsp nbsp', 'persons asylum', 'cash work', 'sector education', 'affordable houses', 'provides assistance', 'rights violations', 'asile réfugiés', 'conflit armé', 'training shelter', 'estimated million', 'raise awareness', 'loose pack', 'seekers instances', 'crisis neighbouring', 'baggage personal', 'multisectoral emergency', 'research projects', 'pays autres', 'réfugiés personnes', 'shelter household', 'living housing', 'education housing', 'refugee women', 'support preparation', 'health system', 'women led', 'north lebanon', 'get timely', 'fulfilling meaningful', 'programme fund', 'social cohesion', 'doctors etc', 'response south', 'lebanon currently', 'fournit aide', 'emergency cash', 'armed groups', 'scale disasters', 'municipalities group', 'refugee host', 'inl bpa', 'humanitarian services', 'food item', 'groups lead', 'core relief', 'temporary housing', 'nearly million', 'providing skills', 'project seeks', 'early childhood', 'relief clwr', 'endowment democracy', 'primary healthcare', 'play role', 'cccm shelter', 'returnees host', 'projet vise', 'housing facilities', '2018 19', 'response recovery', 'help groups', 'co operative', 'maintenant plus', 'services essentiels', 'services secure', 'nationals research', 'million réfugiés', 'haul charges', 'flood protection', 'fund project', 'accès services', 'countries colombia', 'maternal newborn', 'donateurs projet', 'infrastructure improvement', 'infrastructure services', 'populations north', 'conditions informal', 'humanity inclusion', 'hygiene support', 'well basic', 'searches lasting', 'responses expected', 'high level', 'lebanon phase', 'mukuru slum', '2021 2030', 'livelihoods benefit', 'town south', 'environment effective', 'assembly promote', 'amc développement', 'section hope', 'purpose cyclone', 'schooling feeding', 'housing materials', 'prevent forced', 'gbv prevention', 'gender norms', 'coordination unit', 'ministry finance', 'protection displaced', 'family welfare', '2022 pakistan', 'provide additional', 'assistance hiv', 'displaced violence', 'africa middle', 'health wellbeing', 'residential care', 'regional development', '2025 drc', 'support goal', 'familias empobrecidas', 'country operations', 'mandate protect', 'soins médicaux', 'opportunities accelerate', 'link humanitarian', 'jordanie liban', 'response displacement', 'youth urban', 'environment residents']
