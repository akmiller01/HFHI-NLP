from transformers import pipeline
from datasets import Dataset, load_dataset
import pandas as pd

# Map function to create unified text column
def create_text_column(example):
    textual_data_list = [
        example['project_title'],
        example['short_description'],
        example['long_description']
    ]
    textual_data_list = [str(textual_data) for textual_data in textual_data_list if textual_data is not None]
    example['text'] = " ".join(textual_data_list)
    return example


# Load data and make text col
dataset = pd.read_csv("large_input/full_crs_keyword_2018_2022.csv", dtype=str)
dataset = Dataset.from_pandas(dataset, preserve_index=False)
dataset = dataset.map(create_text_column, num_proc=8)

# Prep model args
classes_verbalized = [
    'contributes to the provision of no-cost, low-cost, and affordable human habitation, including the construction of new homes, government or civil-society capacity building to assist in the provision of housing, the administration of housing programs, provision of temporary shelters in emergency or disaster situations (including housing within the donor country), and the improvement/upgrading of quality of shelter in slums or informal settlements.',
    'is primarily about other sectors, including education, health, water and sanitation, general government and civil-society, conflict, peace or security, energy, finance, agriculture, or industry.'
]
id2label = {i: label for i, label in enumerate(classes_verbalized)}
label2id = {id2label[i]: i for i in id2label.keys()}

# Set up classifier
zeroshot_classifier = pipeline("zero-shot-classification", model="MoritzLaurer/bge-m3-zeroshot-v2.0")
hypothesis_template = "The activity described by this text {}"

# Test classifier
def inference_classifier(example):
    output = zeroshot_classifier(example['text'], classes_verbalized, hypothesis_template=hypothesis_template, multi_label=False)
    example['zs_label'] = output['labels'][0]
    example['zs_score'] = output['scores'][0]
    return example

example = dict()
example['text'] = "To deliver an effective response to the basic needs of vulnerable people impacted by the crisis in the North East of Nigeria. The programme will deliver humanitarian assistance in nutrition and food security, protection and Education in Emergencies, multi-sector support including health, water, shelter and livelihoods interventions, as well as enabling a more efficient response to the crisis, including strengthened government planning, budgeting and coordination, and risk management."
import pdb; pdb.set_trace()

# De-duplicate
dataset = pd.DataFrame(dataset)
text_cols = ['text']
dataset_text = dataset[text_cols]
print(dataset_text.shape)
dataset_text = dataset_text.drop_duplicates(subset=text_cols)
print(dataset_text.shape)

# Inference
dataset_text = Dataset.from_pandas(dataset_text, preserve_index=False)
dataset_text = dataset_text.map(inference_classifier)
dataset_text = pd.DataFrame(dataset_text)
dataset = pd.merge(dataset, dataset_text, on=text_cols, how="left")
dataset.to_csv("large_input/full_crs_keyword_2018_2022_zs.csv")