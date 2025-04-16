# Python API interface

import os
import requests
import json
import pandas as pd
import sqlite3 as sql

os.chdir("/home/cschmidt/git/llm-test")

# Endpoint /datasets https://dataset.api.hub.geosphere.at/v1/datasets

# Get data from endpoint and put it into a dataframe
# API Structure <host>/<version>/<type>/<mode>/<resource_id>


def get_data():
    url = 'https://dataset.api.hub.geosphere.at/v1/datasets'
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        return data
    else:
        print(f"Error: {response.status_code}")
        return None

datasets = pd.DataFrame(get_data())   

datasets =datasets.transpose()

datasets

# Construct new urls from previous response.
# We have to append /metadata to the url to get the metadata
datasets["url"]

urls = []
for i in range(len(datasets)):
    urls.append(datasets['url'][i] + "/metadata")

# Now we have a list of urls for all datasets
# We want to access the data from each url.

def get_data_from_url(url):
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        return data
    else:
        print(f"Error: {response.status_code}")
        return None 


