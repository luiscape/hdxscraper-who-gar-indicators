## Script to download and transform WHO GAR data
## into a HDX-friendly format.

# Dependencies
library(RCurl)
library(rjson)
library(countrycode)

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
  download.file(getResourceURL('f48a3cf9-110e-4892-bedf-d4c1d725a7d1'), 'data/data.csv', method = 'wget')
  
  # Loading into memory
  whoData <- read.csv('source/data/data.csv')
  
  
  # The current dataset contains 36 indicators. 
  # Out of those indicators, we will be extracting only 2: 
  # 1. Cumulative number of confirmed, probable and suspected Ebola deaths
  # 2. Cumulative number of confirmed, probable and suspected Ebola cases
  
  # Schema for indicator: 
  # - indID
  # - name
  # - units
  indicator <- read.csv('source/data/indicator.csv')
  
  # Schema for value: 
  # - value: ok
  # - period: ok
  # - region: ok
  # - indID: ok
  # - dsID: ok
  # - source: 
  # - is_number: 
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
  
  # Schema for dataset: 
  # - dsID
  # - last_updated
  # - last_scraped
  # - name
  dataset <- read.csv('source/data/dataset.csv')
  dataset$last_updated <- as.character(max(value$period))
  dataset$last_scraped <- as.character(Sys.Date())
  
  
  ### Writing CSVs ###
  write.csv(indicator, 'data/indicator.csv', row.names = F)
  write.csv(dataset, 'data/dataset.csv', row.names = F)
  write.csv(value, 'data/value.csv', row.names = F)
}


runScraper <- function() {
  downloadCSVandTransform()  # downloading and preparing the tables
}


