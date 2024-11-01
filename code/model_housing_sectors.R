#### Setup ####
list.of.packages <- c("rstudioapi", "data.table", "gtsummary")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd <- dirname(getActiveDocumentContext()$path) 
setwd(wd)
setwd("../")

rmse = function(vec1, vec2){
  sqrt(mean((vec1 - vec2)^2, na.rm=T))
}
#### End setup ####

# Donor fit
dat = fread("input/merged_crs_iati_housing_sectors.csv")

donor_fit_list = list()
donor_fit_index = 1
unique_donors = unique(dat$donor_name)
missing_donors = c()
for(i in 1:length(unique_donors)){
  unique_donor = unique_donors[i]
  na_subset = subset(dat,donor_name==unique_donor)
  non_na_subset = subset(na_subset, !is.na(usd_disbursement_iati) & !is.na(usd_disbursement_crs))
  if(nrow(non_na_subset) == 0){
    message(unique_donor)
    missing_donors = c(missing_donors, unique_donor)
  }else{
    fit = lm(usd_disbursement_crs~usd_disbursement_iati,data=na_subset)
    alpha = summary(fit)$coefficients[1]
    beta = summary(fit)$coefficients[2]
    adj.r.squared = summary(fit)$adj.r.squared
    tmp = data.frame(donor.name=unique_donor, alpha, beta, adj.r.squared, n=nrow(non_na_subset))
    donor_fit_list[[donor_fit_index]] = tmp
    donor_fit_index = donor_fit_index + 1
  }
}

donor_fit = rbindlist(donor_fit_list)
fwrite(donor_fit, "output/donor_fit.csv")

dat = fread("input/merged_crs_iati_housing_sectors.csv")
dat = dat[,.(
  usd_disbursement_crs=sum(usd_disbursement_crs, na.rm=T),
  usd_disbursement_iati=sum(usd_disbursement_iati, na.rm=T)
),
by=.(year, sector_code, recipient_iso3_code)]

dat.grid = expand.grid(
  sector_code=unique(dat$sector_code),
  recipient_iso3_code=unique(dat$recipient_iso3_code),
  year= unique(dat$year)
  )

dat = merge(dat, dat.grid, all=T)
dat$usd_disbursement_crs[which(is.na(dat$usd_disbursement_crs))] = 0
dat$usd_disbursement_iati[which(is.na(dat$usd_disbursement_iati))] = 0

dat = dat[order(dat$recipient_iso3_code, dat$sector_code, dat$year)]
dat[,"usd_disbursement_crs_t1":=shift(usd_disbursement_crs),by=.(recipient_iso3_code, sector_code)]
dat[,"usd_disbursement_iati_t1":=shift(usd_disbursement_iati),by=.(recipient_iso3_code, sector_code)]

dat$delta_iati = (dat$usd_disbursement_iati - dat$usd_disbursement_iati_t1)

dat$sector_code = factor(dat$sector_code)

dat_train = subset(dat, year < 2022)
dat_test = subset(dat, year == 2022)

fit = lm(
  usd_disbursement_crs~ # CRS this year is a function of
    # Constant alpha
    usd_disbursement_iati+ # plus beta0 * IATI this year
    usd_disbursement_crs_t1+ # plus beta1 * CRS last year
    delta_iati+ # plus beta2 * the absolute change in IATI from last year
    recipient_iso3_code+ # Country fixed effects
    sector_code+ # sector fixed effects
    year # time period
    , data=dat_train)
summary(fit)

tbl_regression(fit) %>% add_glance_source_note(include=c("nobs","adj.r.squared","p.value"))
confidence = predict.lm(fit, newdata = dat_test, interval = "confidence")
dat_test$usd_disbursement_iati_fit = confidence[,1]
dat_test$usd_disbursement_iati_lwr = confidence[,2]
dat_test$usd_disbursement_iati_upr = confidence[,3]
plot(usd_disbursement_crs~usd_disbursement_iati, data=dat_test)
abline(0,1)
original_rmse = rmse(dat_test$usd_disbursement_crs, dat_test$usd_disbursement_iati)
original_rmse
plot(usd_disbursement_crs~usd_disbursement_iati_fit, data=dat_test)
abline(0,1)
fit_rmse = rmse(dat_test$usd_disbursement_crs, dat_test$usd_disbursement_iati_fit)
fit_rmse

dat_agg = dat_test[,.(
  usd_disbursement_crs=sum(usd_disbursement_crs),
  usd_disbursement_iati_fit=sum(usd_disbursement_iati_fit),
  usd_disbursement_iati=sum(usd_disbursement_iati)
),
by=.(year, recipient_iso3_code)]
rmse(dat_agg$usd_disbursement_crs, dat_agg$usd_disbursement_iati)
rmse(dat_agg$usd_disbursement_crs, dat_agg$usd_disbursement_iati_fit)

dat_train = subset(dat, year < 2023)
dat_predict = subset(dat, year < 2024)
fit = lm(
  usd_disbursement_crs~ # CRS this year is a function of
    # Constant alpha
    usd_disbursement_iati+ # plus beta0 * IATI this year
    usd_disbursement_crs_t1+ # plus beta1 * CRS last year
    delta_iati+ # plus beta2 * the absolute change in IATI from last year
    recipient_iso3_code+ # Country fixed effects
    sector_code+ # sector fixed effects
    year # time period
  , data=dat_train)
summary(fit)
confidence = predict.lm(fit, newdata = dat_predict, interval = "confidence")
dat_predict$usd_disbursement_crs_fit = confidence[,1]
dat_predict$usd_disbursement_crs_lwr = confidence[,2]
dat_predict$usd_disbursement_crs_upr = confidence[,3]
dat_predict$usd_disbursement_crs[which(dat_predict$year==2023)] = dat_predict$usd_disbursement_crs_fit[which(dat_predict$year==2023)]
fwrite(dat_predict, "input/modeled_crs_iati_housing_sectors.csv")
