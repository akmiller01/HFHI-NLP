#### Setup ####
list.of.packages <- c("rstudioapi", "dplyr", "data.table", "countrycode", "stringr")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd <- dirname(getActiveDocumentContext()$path) 
setwd(wd)
setwd("../")
#### End setup ####

crs = fread("large_input/oda_housing_sectors_2010_2022.csv")
crs = subset(crs, sector_code != "930" & aid_type!="E01" & aid_type!="E02")

region_codes = c(
  "88",
  "89",
  "189",
  "289",
  "298",
  "389",
  "489",
  "498",
  "589",
  "619",
  "679",
  "689",
  "789",
  "798",
  "889",
  "998",
  "1027",
  "1028",
  "1029",
  "1030",
  "1031",
  "1032",
  "1033",
  "1034",
  "1035"
)
crs_regions = subset(crs, recipient_code %in% region_codes)
region_iso3_codes = unique(crs_regions[,c("recipient_code", "recipient_iso3_code", "recipient_name")])
unspecified = data.frame(recipient_code="998", recipient_iso3_code="DPGC_X", recipient_name="Bilateral, unspecified")
region_iso3_codes = rbind(region_iso3_codes, unspecified)
missing_regions = data.frame(
  recipient_code=c("380", "889", "1027", "1028", "1029"),
  recipient_iso3_code=c("A5_X", "O_X", "F3_X", "F5_X", "F7_X"),
  recipient_name=c("Caribbean & Central America, regional", "Oceania, regional", "Eastern Africa, regional", "Middle Africa, regional", "Southern Africa, regional")
)
region_iso3_codes = rbind(region_iso3_codes, missing_regions)
fwrite(region_iso3_codes, "input/region_mapping.csv")
region_iso3_code_mapping = region_iso3_codes$recipient_iso3_code
names(region_iso3_code_mapping) = region_iso3_codes$recipient_code

iati = fread("large_input/iati_28102024.csv")
iati = subset(iati, x_sector_code %in% c("16030", "16040"))
iati[,c("title_narrative", "description_narrative", "transaction_description_narrative")] = NULL
gc()

# Correction for missing reporting_org_ref, and nonbreaking space
iati$reporting_org_ref[which(startsWith(iati$iati_identifier,"GB-CHC-294329"))] = "GB-CHC-294329"
iati$reporting_org_ref[which(startsWith(iati$iati_identifier,"FR-6"))] = "FR-6"
iati$reporting_org_ref = str_trim(iati$reporting_org_ref)

oecd_donor_mapping = fread('input/iati_donor_mapping.csv')
oecd_donor_mapping = subset(oecd_donor_mapping, !is.na(`Donor code`))
# Account for splitting
iati$index = c(1:nrow(iati))
pre_sum = sum(iati$x_transaction_value_usd, na.rm=T)
iati = merge(iati, oecd_donor_mapping, by="reporting_org_ref", all.x = T, allow.cartesian=T)
duplicated_indicies = iati$index[which(duplicated(iati$index))]
if(length(duplicated_indicies) > 0){
  duplicated_counts = data.table(table(duplicated_indicies))
  names(duplicated_counts) = c("index", "count")
  duplicated_counts$index = as.numeric(duplicated_counts$index)
  duplicated_counts$count = duplicated_counts$count + 1
  duplicated_counts$value_multiplier = 1 / duplicated_counts$count 
  duplicated_counts$count = NULL
  iati = merge(iati, duplicated_counts, by="index", all.x=T)
  iati$value_multiplier[which(is.na(iati$value_multiplier))] = 1
  iati$x_transaction_value_usd = iati$x_transaction_value_usd * iati$value_multiplier
  iati$index = NULL
  iati$value_multiplier = NULL
  post_sum = sum(iati$x_transaction_value_usd, na.rm=T)
  stopifnot(format(pre_sum, scientific=F) == format(post_sum, scientific=F))
}

# Correction for World Bank publisher mapping to IDA Donor Code
wb = subset(iati, reporting_org_ref=="44000")
wb = subset(wb, grepl("International Development Association", funding_orgs))
nonwb = subset(iati, reporting_org_ref!="44000")
iati = rbind(wb, nonwb)

# Remove non-core funding for FAO
fao = subset(iati, reporting_org_ref=="XM-DAC-41301")
fao = subset(fao, grepl("Food and Agriculture Organization (FAO)", funding_orgs, fixed=T))
nonfao = subset(iati, reporting_org_ref!="XM-DAC-41301")
iati = rbind(fao, nonfao)

iati = subset(iati, !is.na(`Donor code`))
iati$sector_code = iati$x_sector_code
iati$x_transaction_value_usd = iati$x_transaction_value_usd / 1000000
iati_agg = data.table(iati)[,.(usd_disbursement_iati=sum(x_transaction_value_usd, na.rm=T)),by=.(
  `Donor code`, `Donor name`, x_transaction_year, x_recipient_code, sector_code
)]
names(iati_agg) = c("donor_code", "donor_name" ,"year", "recipient_iso2_code", "sector_code", "usd_disbursement_iati")
iati_agg$recipient_iso3_code = countrycode(
  iati_agg$recipient_iso2_code, 
  origin="iso2c", 
  destination="iso3c"
)
iati_agg$recipient_iso3_code[which(iati_agg$recipient_iso2_code=="XK")] = "XKV"
iati_agg$recipient_iso3_code[which(iati_agg$recipient_iso2_code %in% names(region_iso3_code_mapping))] =
  region_iso3_code_mapping[iati_agg$recipient_iso2_code[which(iati_agg$recipient_iso2_code %in% names(region_iso3_code_mapping))]]
iati_agg = subset(iati_agg, !is.na(recipient_iso3_code))
iati_agg$recipient_iso2_code = NULL
iati_agg$sector_code = as.character(iati_agg$sector_code)
iati_agg$donor_name = stringr::str_replace_all(iati_agg$donor_name, "\\h", " ") # Replace horizontal space

crs$sector_code = crs$purpose_code
crs_agg = data.table(crs)[,.(usd_disbursement_crs=sum(usd_disbursement, na.rm=T)),by=.(
  donor_code, donor_name, year, recipient_iso3_code, sector_code
)]
crs_agg$sector_code = as.character(crs_agg$sector_code)

dat = merge(crs_agg, iati_agg, all=T)
# dat$usd_disbursement_crs[which(is.na(dat$usd_disbursement_crs))] = 0
# dat$usd_disbursement_iati[which(is.na(dat$usd_disbursement_iati))] = 0

# dat$recipient_name = countrycode(dat$recipient_iso3_code, origin="iso3c", destination="country.name")
# dat = subset(dat, !is.na(recipient_name))

fwrite(dat, "input/merged_crs_iati_housing_sectors.csv")
