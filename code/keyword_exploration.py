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
dataset = dataset.map(clean_text, num_proc=8, remove_columns=['project_title', 'short_description', 'long_description'])

# De-duplicate
df = pd.DataFrame(dataset)
print(df.shape)
df = df.drop_duplicates(subset=['text'])
print(df.shape)
dataset = Dataset.from_pandas(df, preserve_index=False)

basic_keywords = ['housing', 'informal settlements', 'slums', 'shelter']

not_housing = dataset.filter(lambda example: not any([keyword in example['text'] for keyword in basic_keywords]))
housing = dataset.filter(lambda example: any([keyword in example['text'] for keyword in basic_keywords]))

vectorizer = TfidfVectorizer(ngram_range=(1, 1))
vectorizer.fit(dataset['text'])

not_housing_result = vectorizer.transform([" ".join(not_housing['text'])])
top_not_housing = features(vectorizer, not_housing_result)
top_not_housing = top_not_housing[:250]

housing_result = vectorizer.transform([" ".join(housing['text'])])
top_housing = features(vectorizer, housing_result)
top_housing = [word for word in top_housing if word not in top_not_housing]
top_housing = top_housing[:250]


print("Housing purpose code frequent words:\n")
print(top_housing)

# By purpose code (16030, 16040)
## ngram (1, 1)
## ['housing', 'construcción', 'digna', 'enhancing', 'specifically', 'sostenibles', 'conocimiento', 'nombre', 'expansion', 'divers', 'mtptc', 'mobilisation', 'proceeds', '90', 'totogalpa', 'georgia', 'éstas', 'exchanges', 'khc', 'nadacia', 'fikri', 'simbólicos', 'largo', 'edificaciones', 'mts', 'montevideo', 'spatiale', 'especificos', 'quedando', 'erupción', 'éstos', 'resistance', 'podgorica', 'empleadores', 'privatization', 'paving', 'estudiante', 'coop', 'impactos', 'juridique', 'placed', 'must', 'latrines', 'tratarla', 'hombresen', 'czz2111', 'plusvalã', 'critieria', 'enteros', 'relacionesfamiliares', 'means', 'oga', 'dalmatia', 'scetor', 'patronato', 'súas', 'jacques', 'periferia', 'zdrowotnej', '184', 'metodológica', 'comprendidas', 'ésta', 'revitalizing', 'representan', 'builders', 'diez', 'smartphone', 'andaluces', 'actrices', 'especialización', 'vient', 'bloque', 'mohammed', 'sr', 'estancia', 'rencontres', 'fabrication', 'eg', 'upstream', 'développées', 'emergencias', 'accomplished', 'budgets', 'toward', 'educativo', 'advice', 'agreements', 'enreda', 'enrichments', 'enrollment', 'entraîneurs', 'entra', 'entr', 'entregaría', 'enterotoxaemia', 'ensurig', 'enterpries', 'enterprenurial', 'czz2658', 'entfernung', 'enmatériels', 'ennuestro', 'engagementer', 'eraturi', 'erhalten', 'equilibrium', 'equilibriosocial', 'czm1011', 'czerwca', 'equipoeuropa', 'erythree', 'esa6', 'ersetzt', 'escal', 'escalonadas', 'errichtet', 'erradicação', 'environnementaux', 'environnment', 'envoie', 'entrevoir', 'eolienne', 'eowe', 'eov', 'electrifikation', 'electrònica', 'electroencephalogram', 'electroencephalog', 'electrophoresis', 'elaborate', 'elaborat', 'dalla', 'eksportu', 'elabor', 'elbahrawy', 'elektro', 'elisée', 'elkartasunak', 'elkartasuna', 'elkaar', 'daholobe', 'ellaspara', 'ellun', 'dakma', 'elektroniczny', 'elhorario', 'elgobaa', 'elevados', 'elfin', 'egyptalum', 'eiaidmp', 'damns', 'eficiência', 'egne', 'eksperckie', 'ekologistak', 'ekologii', 'einterrelacionar', 'eijkelkamp', 'ejecutandoasocolvas', 'emsf', 'emprunteur', 'enacting', 'enakopravnih', 'empoderamientoen', 'daame', 'emprenderlas', 'd8', 'côtes', 'endangere', 'encounter', 'endommagée', 'endosomal', 'endoscopy', 'encargó', 'encargos', 'encajan', 'enconomic', 'enclavées', 'dagga', 'embattled', 'dafc', 'embriones', 'emcc', 'elásticos', 'elrp', 'embalse', 'embaglio', 'emigrante', 'f21ap01545', 'fa10232517', 'f9', 'extrapolate', 'extremidad', 'facilities4', 'faciltiate', 'faciltation', 'faciltate', 'facilityate', 'currículo', 'facilite', 'fading', 'fadel', 'fadcanic', 'fables', 'curumbá', 'fa9415023', 'cursus', 'facente', 'fasrb', 'fasoespecífico', 'fasting', 'fasi', 'fapiz', 'fandora', 'fancs', 'fang', 'curables', 'fanm', 'farinha', 'farmacéuticas', 'farmacológicala', 'farmaco', 'cupboard', 'faragouaran', 'farafina', 'faracho', 'farabi', 'fardeaux', 'estils', 'estimulan', 'esterilizador', 'esterilización', 'estereotipadas', 'cy2019', 'estiamte', 'estevanell', 'estrategiasprincipales', 'estratategia', 'estrangers', 'estrattivo', 'estirpe', 'estimulándose', 'estoimatifs', 'estampadas', 'estambul', 'cyberfactory', 'estbalishment', 'estecaso']

## ngram (2, 2)
## ['municipal development', 'land surface', 'complex qasar', 'san juan', 'core 2019', 'sanitation impoverished', 'expenditure strengthening', 'urbamonde sénégal', 'delivery installation', 'construction materials', 'citizens bosnia', 'involuntary resettlement', 'neighbourhoods along', 'blocoplastico project', 'habitat related', 'two slum', 'green asean', 'team technicians', 'promoting habitat', 'familiares mismo', 'recycling resources', 'socioeconomic development', 'desarrollo proyecto', 'verification contract', 'community siddarampuram', 'part funding', 'assistance support', 'drafts tor', 'within cooperating', 'mub management', 'diagnóstico criterios', 'patronato municipal', 'institution housing', 'cuanto reducción', 'así romper', 'urbano edu', 'tecnológicos generación', 'quedando desarrollar', 'temat uprawy', 'incrementando llegar', 'conjuntamente dirección', 'uzbekistan social', 'system neighborhood', 'area intermediate', 'municipalities kumanovo', 'inclusion investments', 'rural japla', 'apartadó mejora', 'letrinas constituyendo', 'comunidades cubana', 'zwiekszenie wiedzy', 'system adb', 'casado elias', 'salut proyecto', 'companies co', 'bio construction', 'beneficiarias podrán', 'dhaka construction', 'inhabitants south', 'total 160', 'funding improvement', 'risk provision', 'communities indirect', 'morocco energy', '48 mujeres', 'coste total', '2017 main', 'chaînes production', 'resto población', 'government salvador', 'finance market', 'including global', 'improvement social', 'economic challenges', 'coastal marine', 'sector specific', 'personnes besoin', 'equality gender', 'environnement adoptent', 'environnement selon', 'equality accession', 'environnement cela', 'environnement socioculturel', 'equality granting', 'environnement jeunesse', 'environnement instable', 'equality coverage', 'environments actors', 'environments activity', 'equally emphasized', 'equally afcfta', 'environments construction', 'equi bureau', 'environments stories', 'equality pro', 'environments senegal', 'environnantes activités', 'equality koloriang', 'environments wide', 'environments iran', 'equality volunteer', 'equality reduces', 'environments middle', 'equality rural', 'enza goal', 'epidemic community', 'epd afines', 'epa com', 'epa business', 'epi formation', 'eo left', 'eo ir', 'eom albania', 'epsg 2022', 'eprisecab eprisecab', 'environnementaux considérables', 'environnemental missions', 'environnemental brings', 'environnementale centre', 'environnementale alimentaire', 'eqpts entret', 'envisages accountable', 'environnemtale sociale', 'epmc 532596', 'envisage contribuer', 'envisage consolidation', 'entonces prioritariamente', 'entorns saludables', 'entrada pandillas', 'entorno minería', 'entornos digitales', 'entitats feministes', 'entitled uchaguzi', 'entity execution', 'entitled bringing', 'entrepreneuralism facilitiate', 'entrepreneurs businesswomen', 'entrepreneurs filière', 'entrepreneuriat renforcement', 'entrepreneurs 955', 'entrepreneurs 85', 'entraîné mort', 'entregados proyectos', 'entrave accès', 'entreprenariat formation', 'entremujeres hombres', 'enteras visto', 'enterprise reconstruction', 'ensuring long', 'entenderse sujetos', 'entails opds', 'entier pays', 'enterprises activities', 'enterprises kenya', 'enterprises main', 'enterprises program', 'environ nementaux', 'environment ac_764_3', 'environment addressing', 'environmental behaviour', 'environment today', 'environment tougtuang', 'environment yemen', 'environmental licensing', 'environmental physical', 'environmental performance', 'environmental liability', 'environment portuguese', 'environment needed', 'environment serbia', 'environment sidi', 'environment think', 'environment sweden', 'environment proyecto', 'entrepreneurs merchants', 'entrepreneurs wgdp', 'entrepreneurship achieving', 'entrepreneurship age', 'entreprises technologiques', 'entretantos huerta', 'entretien sous', 'entretien hygiène', 'espèces plus', 'esri establish', 'ess tánger', 'ess preveu', 'espera establecido', 'esperados proyecto', 'establecemos modelo', 'essex ohchr', 'essentiels secteur', 'estabilidad área', 'essential preserve', 'essential pillar', 'essential sexual', 'essential enabler', 'essential keep', 'essentielles noix', 'essentielles centres', 'essentiels neuf', 'essentials modern', 'essentiel expliquer', 'especializados gestión', 'especially hiv', 'especially femal', 'especially concerning', 'espectacle música', 'especialmente proveniente', 'especialmente significativo', 'específico fortalecimeinto', 'especially regular', 'especially relate', 'especially rights', 'especially returning', 'especially resurgence', 'especially solar', 'especialmente dan', 'especialmente oportuno', 'estimado producción', 'estima aumento', 'estelí autoridades', 'establishment multi', 'establishments thailand', 'estimating total', 'estonian tax', 'estonian supporters', 'estrada abertura', 'estr health', 'estosobjetivos desarrollar', 'estonia learn', 'estimate inca', 'estimate etb', 'estimates 310', 'estimated clf', 'established cases', 'established procedures', 'establish resistant', 'establish identification', 'establishment caricom', 'establishment improved', 'establishment habitat', 'establishment fisheries', 'establishing centers', 'establishing 14', 'establishing heating', 'establishing formalising', 'equipts securite', 'equitable health', 'equipping testing', 'equipo umavi']

# By basic keywords ['housing', 'informal settlements', 'slums', 'shelter']
## ngram (1, 1)
## 

## ngram (2, 2)
##