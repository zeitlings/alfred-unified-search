#!/bin/bash

pkl eval template.pkl # > &dev null ~ 
pkl eval -f json searches.config.pkl -o ../searches.json



