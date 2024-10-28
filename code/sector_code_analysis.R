lapply(c("data.table", "rstudioapi", "scales","ggplot2","scales","Hmisc"), require, character.only = T)
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
crs = fread("large_input/oda_housing_sectors_2018_2022.csv")

# By disbursement year
oda_by_year = crs[,.(usd_disbursement_deflated=sum(usd_disbursement_deflated, na.rm=T)), by=.(year, purpose_name)]

ggplot(oda_by_year, aes(x=year, y=usd_disbursement_deflated, group=purpose_name, fill=purpose_name)) +
  geom_bar(stat="identity") +
  scale_y_continuous(expand = c(0, 0), n.breaks=5, labels=dollar) +
  scale_x_continuous(n.breaks = 5) +
  scale_fill_manual(values=c(master_blue, master_green)) +
  expand_limits(y=c(0, max(oda_by_year$usd_disbursement_deflated*1.1))) +
  custom_style +
  labs(
    y="ODA disbursements\n(constant 2021 US$ millions)",
    x="",
    fill=""
  )
ggsave(
  filename="output/sector_year.png",
  height=5,
  width=8
)
oda_by_year_wide = dcast(oda_by_year, year~purpose_name, value.var="usd_disbursement_deflated")
fwrite(oda_by_year_wide, "output/sector_year.csv")

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
fwrite(oda_by_donor, "output/sector_by_donor.csv")
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
    y="ODA disbursements\n(constant 2021 US$ millions)",
    x="",
    color="",
    title="Top 10 donors to current housing sectors\n(2018-2022)"
  ) +
  rotate_x_text_45
ggsave(
  filename="output/sector_by_donor.png",
  height=5,
  width=8
)

# By recipient
oda_by_recipient = crs[,.(usd_disbursement_deflated=sum(usd_disbursement_deflated, na.rm=T)), by=.(recipient_name)]
oda_by_recipient = oda_by_recipient[order(-oda_by_recipient$usd_disbursement_deflated),]
recipient_short_names = oda_by_recipient$recipient_name
names(recipient_short_names) = oda_by_recipient$recipient_name
recipient_short_names["Europe, regional"] =
  "Europe"
recipient_short_names["West Bank and Gaza Strip"] =
  "Palestine"
fwrite(oda_by_recipient, "output/sector_by_recipient.csv")
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
    y="ODA disbursements\n(constant 2021 US$ millions)",
    x="",
    color="",
    title="Top 10 recipients of current housing sectors\n(2018-2022)"
  ) +
  rotate_x_text_45
ggsave(
  filename="output/sector_by_recipient.png",
  height=5,
  width=8
)