## Script to download and transform WHO GAR data
## into a HDX-friendly format.

# Dependencies
library(RCurl)
library(rjson)
library(countrycode)

# Helper functions.
source('tool/code/write_tables.R')
source('tool/code/sw_status.R')

# Getting the download link from CKAN
getResourceURL <- function(id = NULL) {
  cat('Querying CKAN for the CSV url | ')
  # Building URL
  cUrl = 'https://data.hdx.rwlabs.org/api/action/resource_show?id='
  qUrl = paste(cUrl, id, sep="")
  
  # Getting JSON document
  doc <- fromJSON(getURL(qUrl))
  cat('Done!\n')
  return(doc$result$url)
}

# Downloading file and processing the 3 tables.
downloadCSVandTransform <- function() {
  # Download file
  download.file(getResourceURL('f48a3cf9-110e-4892-bedf-d4c1d725a7d1'), 'tool/data/source/data.csv', quiet = T)
  cat('Downloading file | Done!\n')
  
  # Loading into memory
  cat('Loading data into memory | ')
  whoData <- suppressWarnings(read.csv('tool/data/source/data.csv'))
  cat('Done!\n')
  
  
  # The current dataset contains 36 indicators. 
  # Out of those indicators, we will be extracting only 2: 
  # 1. Cumulative number of confirmed, probable and suspected Ebola deaths
  # 2. Cumulative number of confirmed, probable and suspected Ebola cases
  cat('Building tables | ')
  
  # Schema for indicator: 
  # - indID: ok
  # - name: ok
  # - units: ok
  indicator <- suppressWarnings(read.csv('tool/data/source/indicator.csv'))
  
  # Schema for value: 
  # - value: ok
  # - period: ok
  # - region: ok
  # - indID: ok
  # - dsID: ok
  # - source: ok
  # - is_number: ok 
  value <- whoData[whoData$Indicator == 'Cumulative number of confirmed, probable and suspected Ebola deaths' | whoData$Indicator == 'Cumulative number of confirmed, probable and suspected Ebola cases', ]
  
  names(value) <- c('name', 'region', 'period', 'value')
  
  # Codifying country names into codes
  value$region <- countrycode(value$region, 'country.name', 'iso3c')
  
  # Changing the names of the indicators
  value$name <- ifelse(value$name == 'Cumulative number of confirmed, probable and suspected Ebola deaths', 'Cumulative number of confirmed, probable and suspected EDV deaths', as.character(value$name))
  value$name <- ifelse(value$name == 'Cumulative number of confirmed, probable and suspected Ebola cases', 'Cumulative number of confirmed, probable and suspected EDV cases', as.character(value$name))
  
  # Adding dataset id
  value$dsID <- 'who-gar'
  
  # Adding indID
  value <- merge(value, indicator)
  value$units <- NULL
  
  # Making period a Date
  value$period <- as.Date(value$period)
  
  # Adding source
  value$source <- as.character(dataset$name[1])
  
  # Adding validator
  value$is_number <- 1
  
  # Schema for dataset: 
  # - dsID
  # - last_updated
  # - last_scraped
  # - name
  dataset <- suppressWarnings(read.csv('source/data/dataset.csv'))
  dataset$last_updated <- as.character(max(value$period))
  dataset$last_scraped <- as.character(Sys.Date())
  
  cat('Done!\n')
  
  
  cat('Writing output (CSV) | ')
  ### Writing CSVs ###
  write.csv(indicator, 'tool/data/indicator.csv', row.names = F)
  write.csv(dataset, 'tool/data/dataset.csv', row.names = F)
  write.csv(value, 'tool/data/value.csv', row.names = F)
  cat('Done!\n')
  
  cat('Writing output (SQLite) | ')
  # Storing output.
  writeTables(indicator, "indicator", "scraperwiki")
  writeTables(dataset, "dataset", "scraperwiki")
  writeTables(value, "value", "scraperwiki")
  cat('Done!\n')
  
}


runScraper <- function() {
  downloadCSVandTransform()  # downloading, preparing, and storing output
}

# Changing the status of SW.
tryCatch(runScraper(),
         error = function(e) {
           cat('Error detected ... sending notification.')
           system('mail -s "WHO GAR failed." luiscape@gmail.com')
           changeSwStatus(type = "error", message = "Scraper failed.")
{ stop("!!") }
         }
)
# If success:
changeSwStatus(type = 'ok')
