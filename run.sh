# Running the main script
~/R/bin/Rscript tool/code/scraper.R

# Navigate and make ZIP package
cd tool/data
zip who-gar-raw *.csv
mv who-gar-raw.zip ../http/who-gar-raw.zip
