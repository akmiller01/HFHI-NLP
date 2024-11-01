lapply(c("data.table", "rstudioapi", "scales","ggplot2","scales","Hmisc","openxlsx"), require, character.only = T)
setwd(dirname(getActiveDocumentContext()$path))
setwd("../")

#### Chart setup ####

master_blue = "#005596"
master_green = "#54B948"
master_black = "#000000"

primary_red = "#DC241F"
primary_yellow = "#F1AB00"
primary_orange = "#9A3416"
primary_purpose = "#4A207E"

secondary_blue = "#00759F"
secondary_green = "#007B63"
secondary_yellow = "#C69200"
secondary_orange = "#DA5C05"

tertiary_blue = "#93B9DC"
tertiary_grey = "#7C7369"
tertiary_tan = "#D3BE96"

custom_style = theme_bw() +
  theme(
    panel.border = element_blank()
    ,panel.grid.major.x = element_blank()
    ,panel.grid.minor.x = element_blank()
    ,panel.grid.major.y = element_line(colour = "#a9a6aa")
    ,panel.grid.minor.y = element_blank()
    ,panel.background = element_blank()
    ,axis.line.x = element_line(colour = "black")
    ,axis.line.y = element_blank()
    ,axis.ticks = element_blank()
    ,legend.position = "bottom"
  )

donut_style = custom_style +
  theme(
    panel.grid.major.y = element_blank()
    ,axis.line.x = element_blank()
    ,axis.text = element_blank()
  )

rotate_x_text_45 = theme(
  axis.text.x = element_text(angle = 45, vjust = 1, hjust=1)
)
rotate_x_text_90 = theme(
  axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)
)
#### End chart setup ####

# Load data
crs = fread("large_input/full_crs_keyword_2018_2022_zs_expanded_definitions_annotated.csv")
crs = subset(crs, false_positive==F)
iati = fread("input/modeled_crs_iati_keyword_search.csv")
iati = subset(iati, year==2023)
recip_codes = fread("input/oecd_recipient_codes.csv")
region_codes = fread("input/region_mapping.csv")
recip_codes = rbindlist(list(recip_codes, region_codes))
iati = merge(iati, recip_codes, by="recipient_iso3_code", all.x=T)
missing_names = unique(iati$recipient_iso3_code[which(is.na(iati$recipient_name))])
stopifnot({length(missing_names)==0})

# Deflate
deflators = read.xlsx("input/US$ deflators 2022 April 2024 WEO.xlsx", startRow=3)
deflator_2023_to_2022 = 1 / subset(deflators, OECD.name=="TOTAL DAC")$`2023`
iati$usd_disbursement_crs = iati$usd_disbursement_crs * deflator_2023_to_2022
iati$usd_disbursement_crs_lwr = iati$usd_disbursement_crs_lwr * deflator_2023_to_2022
iati$usd_disbursement_crs_upr = iati$usd_disbursement_crs_upr * deflator_2023_to_2022


iati$usd_disbursement_crs_lwr = pmax(0, iati$usd_disbursement_crs_lwr)
iati$usd_disbursement_crs = pmax(0, iati$usd_disbursement_crs)


# By disbursement year
oda_by_year = crs[,.(usd_disbursement_deflated=sum(usd_disbursement_deflated, na.rm=T)), by=.(year)]
iati_by_year = iati[,.(
  usd_disbursement_deflated=sum(usd_disbursement_crs, na.rm=T),
  usd_disbursement_lwr=sum(usd_disbursement_crs_lwr, na.rm=T),
  usd_disbursement_upr=sum(usd_disbursement_crs_upr, na.rm=T)
  ), by=.(year)]
oda_by_year = rbindlist(list(oda_by_year, iati_by_year), fill=T)

ggplot(oda_by_year, aes(x=year, y=usd_disbursement_deflated)) +
  geom_bar(stat="identity", fill=master_blue) +
  scale_y_continuous(expand = c(0, 0), n.breaks=6, labels=dollar) +
  scale_x_continuous(n.breaks = 6) +
  expand_limits(y=c(0, max(oda_by_year$usd_disbursement_deflated*1.1))) +
  custom_style +
  labs(
    y="ODA disbursements\n(constant 2022 US$ millions)",
    x="",
    fill=""
  )
ggsave(
  filename="output/keyword_year.png",
  height=5,
  width=8
)
fwrite(oda_by_year, "output/keyword_year.csv")

# By donor
oda_by_donor = crs[,.(usd_disbursement_deflated=sum(usd_disbursement_deflated, na.rm=T)), by=.(donor_name)]
oda_by_donor = oda_by_donor[order(-oda_by_donor$usd_disbursement_deflated),]

donor_short_names = oda_by_donor$donor_name
names(donor_short_names) = oda_by_donor$donor_name
donor_short_names["International Development Association"] = 
  "World Bank"
donor_short_names["Council of Europe Development Bank"] = 
  "CEB"
donor_short_names["Inter-American Development Bank"] = 
  "IDB"
donor_short_names["Asian Development Bank"] = 
  "ADB"
fwrite(oda_by_donor, "output/keyword_by_donor.csv")
oda_by_donor$donor_name = donor_short_names[oda_by_donor$donor_name]
oda_by_donor$donor_name = factor(
  oda_by_donor$donor_name,
  levels=oda_by_donor$donor_name
)
ggplot(oda_by_donor[1:10], aes(x=donor_name, y=usd_disbursement_deflated)) +
  geom_bar(stat="identity",fill=master_blue) +
  scale_y_continuous(expand = c(0, 0), labels=dollar) +
  expand_limits(y=c(0, max(oda_by_donor$usd_disbursement_deflated*1.1))) +
  custom_style +
  labs(
    y="ODA disbursements\n(constant 2022 US$ millions)",
    x="",
    color="",
    title="Top 10 donors to housing by keyword\n(2018-2022)"
  ) +
  rotate_x_text_45
ggsave(
  filename="output/keyword_by_donor.png",
  height=5,
  width=8
)

# By donor type
donor_type = fread("input/oecd_crs_donor_type_ref.csv")[,c("donor_name", "donor_type")]
donor_type$donor_name[which(donor_type$donor_name=="Czech Republic")] = "Czechia"
crs_donor_type = merge(crs, donor_type, by="donor_name")
oda_by_donor_type = crs_donor_type[,.(usd_disbursement_deflated=sum(usd_disbursement_deflated, na.rm=T)), by=.(donor_type)]
oda_by_donor_type = oda_by_donor_type[order(-oda_by_donor_type$usd_disbursement_deflated),]

fwrite(oda_by_donor_type, "output/keyword_by_donor_type.csv")
oda_by_donor_type$donor_type = factor(
  oda_by_donor_type$donor_type,
  levels=oda_by_donor_type$donor_type
)
ggplot(oda_by_donor_type, aes(x=donor_type, y=usd_disbursement_deflated)) +
  geom_bar(stat="identity",fill=master_blue) +
  scale_y_continuous(expand = c(0, 0), labels=dollar) +
  expand_limits(y=c(0, max(oda_by_donor$usd_disbursement_deflated*1.1))) +
  custom_style +
  labs(
    y="ODA disbursements\n(constant 2022 US$ millions)",
    x="",
    color="",
    title="Keyword housing sector ODA by donor type\n(2018-2022)"
  ) +
  rotate_x_text_45
ggsave(
  filename="output/keyword_by_donor_type.png",
  height=5,
  width=8
)

# By recipient
oda_by_recipient_year = crs[,.(usd_disbursement_deflated=sum(usd_disbursement_deflated, na.rm=T)), by=.(recipient_name, year)]
iati_by_recipient_year = iati[,.(
  usd_disbursement_deflated=sum(usd_disbursement_crs, na.rm=T),
  usd_disbursement_lwr=sum(usd_disbursement_crs_lwr, na.rm=T),
  usd_disbursement_upr=sum(usd_disbursement_crs_upr, na.rm=T)
), by=.(year, recipient_name)]
setdiff(oda_by_recipient_year$recipient_name, iati_by_recipient_year$recipient_name)
setdiff(iati_by_recipient_year$recipient_name, oda_by_recipient_year$recipient_name)

oda_by_recipient_year = rbindlist(list(oda_by_recipient_year, iati_by_recipient_year), fill=T)
fwrite(iati_by_recipient_year, "output/keyword_iati_conf_recip.csv")
oda_by_recipient = oda_by_recipient_year[,.(usd_disbursement_deflated=sum(usd_disbursement_deflated, na.rm=T)), by=.(recipient_name)]
oda_by_recipient_type = oda_by_recipient

oda_by_recipient = oda_by_recipient[order(-oda_by_recipient$usd_disbursement_deflated),]
recipient_short_names = oda_by_recipient$recipient_name
names(recipient_short_names) = oda_by_recipient$recipient_name
recipient_short_names["Syrian Arab Republic"] =
  "Syria"
fwrite(oda_by_recipient, "output/keyword_by_recipient.csv")
oda_by_recipient$recipient_name = recipient_short_names[oda_by_recipient$recipient_name]
oda_by_recipient$recipient_name = factor(
  oda_by_recipient$recipient_name,
  levels=oda_by_recipient$recipient_name
)
ggplot(oda_by_recipient[1:10], aes(x=recipient_name, y=usd_disbursement_deflated)) +
  geom_bar(stat="identity",fill=master_blue) +
  scale_y_continuous(expand = c(0, 0), labels=dollar) +
  expand_limits(y=c(0, max(oda_by_recipient$usd_disbursement_deflated*1.1))) +
  custom_style +
  labs(
    y="ODA disbursements\n(constant 2022 US$ millions)",
    x="",
    color="",
    title="Top 10 recipients of keyword housing sectors\n(2018-2023)"
  ) +
  rotate_x_text_45
ggsave(
  filename="output/keyword_by_recipient.png",
  height=5,
  width=8
)

# By recipient income group
income_groups = unique(crs[,c("recipient_name", "income_group_name")])
oda_by_recipient_type = merge(oda_by_recipient_type, income_groups, by="recipient_name")
oda_by_recipient_type = oda_by_recipient_type[,.(
  usd_disbursement_deflated=sum(usd_disbursement_deflated, na.rm=T)
), by=.(income_group_name)]

oda_by_recipient_type = oda_by_recipient_type[order(-oda_by_recipient_type$usd_disbursement_deflated),]
fwrite(oda_by_recipient_type, "output/keyword_by_income.csv")
oda_by_recipient_type$income_group_name = factor(
  oda_by_recipient_type$income_group_name,
  levels=oda_by_recipient_type$income_group_name
)
ggplot(oda_by_recipient_type, aes(x=income_group_name, y=usd_disbursement_deflated)) +
  geom_bar(stat="identity",fill=master_blue) +
  scale_y_continuous(expand = c(0, 0), labels=dollar) +
  expand_limits(y=c(0, max(oda_by_recipient_type$usd_disbursement_deflated*1.1))) +
  custom_style +
  labs(
    y="ODA disbursements\n(constant 2022 US$ millions)",
    x="",
    color="",
    title="Keyword housing sector ODA by income group\n(2018-2023)"
  ) +
  rotate_x_text_45
ggsave(
  filename="output/keyword_by_income.png",
  height=5,
  width=8
)
