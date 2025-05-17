#!/bin/sh
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential python-dev python-pip libffi-dev
pip install -r requirements.txt
cp ../simulations/data.zip . && sudo unzip data.zip && rm data.zip
