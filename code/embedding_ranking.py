import os
from tqdm import tqdm
import torch
import numpy as np
from sentence_transformers import SentenceTransformer
import pickle
from datasets import Dataset, load_dataset
from datasets.utils.logging import disable_progress_bar
disable_progress_bar()


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


global MODEL
global DEVICE
MODEL = SentenceTransformer("Snowflake/snowflake-arctic-embed-s")
DEVICE = "cuda:0" if torch.cuda.is_available() else "cpu"
MODEL = MODEL.to(DEVICE)


def main(input_csv, query):
    csv_basename = os.path.basename(input_csv)
    csv_bn_noext, _ = os.path.splitext(csv_basename)
    out_filename = os.path.join("large_input", "{}_embed.csv".format(csv_bn_noext))
    pickle_path = os.path.join("large_input", "{}.pkl".format(csv_bn_noext))
    dataset = load_dataset('csv', data_files=input_csv, split="train")
    dataset = dataset.map(create_text_column, num_proc=8)


    if os.path.exists(pickle_path):
        with open(pickle_path, 'rb') as pickle_file:
            file_embeddings = pickle.load(pickle_file)
    else:
        file_embeddings = list()
        for sentence in tqdm(dataset['text']):
            embedding = MODEL.encode(sentence)
            file_embeddings.append(embedding)
        with open(pickle_path, 'wb') as pickle_file:
            pickle.dump(file_embeddings, pickle_file)

    query_embedding = MODEL.encode(query, prompt_name="query")
    ranks = np.zeros(len(file_embeddings))
    for i, embedding in enumerate(file_embeddings):
        ranks[i] = query_embedding @ embedding.T

    dataset = dataset.add_column("semantic_similarity_score", ranks)
    dataset = dataset.remove_columns(['text'])
    dataset.to_csv(out_filename)


if __name__ == '__main__':
    query = "Is this text about homes, housing, shelter, slum or informal settlement upgrading?"
    main("large_input/test_keywords_2022.csv", query)