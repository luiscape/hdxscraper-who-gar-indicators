#!/bin/bash

# Running the main script
# and generating the 3 CSVs
# as output.
~/R/bin/Rscript tool/code/scraper.R

# Navigate to the output folder
cd tool/data

# CPS has a bug that it doesn't recognize column names
# because they within quotation marks.
# In all, this is a really non-elegant solution
# for a non-elegant issue.
echo 'dsID,last_updated,last_scraped,name' | cat - dataset.csv > temp && mv temp dataset.csv
echo 'indID,name,units' | cat - indicator.csv > temp && mv temp indicator.csv
echo 'dsID,region,indID,period,value,is_number,source' | cat - value.csv > temp && mv temp value.csv

# Making ZIP package
zip output *.csv
mv output.zip ../http/output.zip

# When the output is generated,
# update the new dataset on HDX.
printf 'Updating the HDX resource.\n'
source ~/venv/bin/activate
python ~/tool/code/updateResource.py