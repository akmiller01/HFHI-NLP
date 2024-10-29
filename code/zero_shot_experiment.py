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
classes_verbalized = ['homes, housing, shelter, slum or informal settlement upgrading', 'other']
id2label = {i: label for i, label in enumerate(classes_verbalized)}
label2id = {id2label[i]: i for i in id2label.keys()}

# Set up classifier
zeroshot_classifier = pipeline("zero-shot-classification", model="MoritzLaurer/mDeBERTa-v3-base-xnli-multilingual-nli-2mil7")

# Test classifier
def inference_classifier(example):
    output = zeroshot_classifier(example['text'], classes_verbalized, multi_label=False)
    example['zs_label'] = output['labels'][0]
    example['zs_score'] = output['scores'][0]
    return example

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