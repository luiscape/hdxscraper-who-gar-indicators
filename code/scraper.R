## Script to download and transform WHO GAR data
## into a HDX-friendly format.

# Dependencies
library(RCurl)
library(rjson)
library(countrycode)

# Helper function for running on ScraperWiki
# Change a = T if running locally.
onSw <- function(a = T, d = 'tool/') {
  if(a == T) return(d)
  else return('')
}

# Helper functions.
source(paste0(onSw(), 'code/write_tables.R'))
source(paste0(onSw(), 'code/sw_status.R'))

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
  cat('-------------------------------------------\n')
  # Download file
  destination = paste0(onSw(), 'data/source/data.csv')
  download.file(getResourceURL('f48a3cf9-110e-4892-bedf-d4c1d725a7d1'), destination, method = 'wget', quiet = T)
  cat('Downloading file | Done!\n')
  
  # Loading into memory
  cat('Loading data into memory | ')
  whoData <- suppressWarnings(read.csv(paste0(onSw(), 'data/source/data.csv')))
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
  indicator <- suppressWarnings(read.csv(paste0(onSw(), 'data/source/indicator.csv')))
  dataset <- suppressWarnings(read.csv(paste0(onSw(), 'data/source/dataset.csv')))
  
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
  
  # Adding source
  value$source <- as.character(dataset$name[1])
  
  # Adding validator
  value$is_number <- 1
  
  # Removing name
  value$name <- NULL
  
  ## Calculating the total for the World ("WLD")
  ## TODO: Create function that sums the latest per country
  ## and per date.
  
  total136 <- data.frame(
    indID = 'CHD.HTH.136',
    value = tapply(
      value$value[value$indID == 'CHD.HTH.136'],
      value$period[value$indID == 'CHD.HTH.136'],
      sum),
    period = row.names(tapply(
      value$value[value$indID == 'CHD.HTH.136'],
      value$period[value$indID == 'CHD.HTH.136'],
      sum)),
    dsID = 'who-gar',
    source = as.character(dataset$name[1]),
    is_number = 1,
    region = 'WLD'
    )
  
  total137 <- data.frame(
    indID = 'CHD.HTH.137',
    value = tapply(
      value$value[value$indID == 'CHD.HTH.137'],
      value$period[value$indID == 'CHD.HTH.137'],
      sum),
    period = row.names(tapply(
      value$value[value$indID == 'CHD.HTH.137'],
      value$period[value$indID == 'CHD.HTH.137'],
      sum)),
    dsID = 'who-gar',
    source = as.character(dataset$name[1]),
    is_number = 1,
    region = 'WLD'
  )
  
  ## Nigeria and Senegal
  sen = value[value$region == 'SEN', ]
  nga = value[value$region == 'NGA', ]
  
  total136$value[total136$period == as.character(max(as.Date(total136$period)))] <- 
    total136$value[total136$period == as.character(max(as.Date(total136$period)))] + 
    sen$value[sen$period == as.character(max(as.Date(sen$period))) & 
                sen$indID == 'CHD.HTH.136'] +
    nga$value[nga$period == as.character(max(as.Date(nga$period))) & 
                nga$indID == 'CHD.HTH.136']
    
  total137$value[total137$period == as.character(max(as.Date(total137$period)))] <- 
    total137$value[total137$period == as.character(max(as.Date(total137$period)))] + 
    sen$value[sen$period == as.character(max(as.Date(sen$period))) & 
                sen$indID == 'CHD.HTH.137'] +
    nga$value[nga$period == as.character(max(as.Date(nga$period))) & 
                nga$indID == 'CHD.HTH.137']
  
  
  ## Plot test
  value <- rbind(value, total136, total137)
  
  # Schema for dataset: 
  # - dsID
  # - last_updated
  # - last_scraped
  # - name
  dataset$last_updated <- as.character(max(as.Date(value$period)))
  dataset$last_scraped <- as.character(Sys.Date())
  
  cat('Done!\n')
  
  ############################################
  #### Changing the order of the columns #####
  ############################################
  dataset <- data.frame(dsID = dataset$dsID, 
                        last_updated = dataset$last_updated,
                        last_scraped = dataset$last_scraped,
                        name = dataset$name)
  indicator <- data.frame(indID = indicator$indID,
                          name = indicator$name,
                          units = indicator$units)
  value <- data.frame(dsID = value$dsID,
                      region = value$region,
                      indID = value$indID,
                      period = value$period,
                      value = value$value,
                      is_number = value$is_number,
                      source = value$source)
  
  
  cat('Writing output (CSV) | ')
  ### Writing CSVs ###
  write.table(indicator, paste0(onSw(), 'data/indicator.csv'), row.names = F, col.names = F, sep = ",")
  write.table(dataset, paste0(onSw(), 'data/dataset.csv'), row.names = F, col.names = F, sep = ",")
  write.table(value, paste0(onSw(), 'data/value.csv'), row.names = F, col.names = F, sep = ",")
  cat('Done!\n')
  
  # Storing output.
  writeTables(indicator, "indicator", "scraperwiki")
  writeTables(dataset, "dataset", "scraperwiki")
  writeTables(value, "value", "scraperwiki")
  
  cat('-------------------------------------------\n')
  
}


runScraper <- function() {
  downloadCSVandTransform()  # downloading, preparing, and storing output
}


# Changing the status of SW.
tryCatch(runScraper(),
         error = function(e) {
           cat('Error detected ... sending notification.')
           system('mail -s "WHO GAR failed." luiscape@gmail.com, takavarasha@un.org')
           changeSwStatus(type = "error", message = "Scraper failed.")
{ stop("!!") }
         }
)
# If success:
changeSwStatus(type = 'ok')
