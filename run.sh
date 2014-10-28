# Running the main script
~/R/bin/Rscript tool/code/scraper.R

# Navigate and make ZIP package
cd tool/data
zip output *.csv
mv output.zip ../http/output.zip