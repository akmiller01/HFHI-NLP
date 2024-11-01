list.of.packages <- c("sp","leaflet", "leaflet.extras2",
                      "data.table","ggplot2","scales",
                      "htmlwidgets", "rstudioapi",
                      "RColorBrewer", "geojsonio", "reshape2")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

setwd(dirname(getActiveDocumentContext()$path))
setwd("../")

deflators = read.xlsx("input/US$ deflators 2022 April 2024 WEO.xlsx", startRow=3)
deflator_2023_to_2022 = 1 / subset(deflators, OECD.name=="TOTAL DAC")$`2023`
# Load sector code data
crs = fread("large_input/oda_housing_sectors_2018_2022.csv")
crs = subset(crs, !endsWith(recipient_name, ", regional"))
crs = subset(crs, !endsWith(recipient_name, ", unspecified"))
crs = subset(crs, sector_code != "930" & aid_type!="E01" & aid_type!="E02")
iati = fread("input/modeled_crs_iati_housing_sectors.csv")
iati = subset(iati, year==2023)

iati$usd_disbursement_crs = iati$usd_disbursement_crs * deflator_2023_to_2022
iati$usd_disbursement_crs_lwr = iati$usd_disbursement_crs_lwr * deflator_2023_to_2022
iati$usd_disbursement_crs_upr = iati$usd_disbursement_crs_upr * deflator_2023_to_2022

iati$usd_disbursement_crs_lwr = pmax(0, iati$usd_disbursement_crs_lwr)
iati$usd_disbursement_crs = pmax(0, iati$usd_disbursement_crs)
iati$usd_disbursement_crs_upr = pmax(0, iati$usd_disbursement_crs_upr)

oda_by_recipient_year = crs[,.(usd_disbursement_deflated=sum(usd_disbursement_deflated, na.rm=T)), by=.(recipient_iso3_code, year)]
oda_by_recipient_year$usd_disbursement_lwr = oda_by_recipient_year$usd_disbursement_deflated
oda_by_recipient_year$usd_disbursement_upr = oda_by_recipient_year$usd_disbursement_deflated
iati_by_recipient_year = iati[,.(
  usd_disbursement_deflated=sum(usd_disbursement_crs, na.rm=T),
  usd_disbursement_lwr=sum(usd_disbursement_crs_lwr, na.rm=T),
  usd_disbursement_upr=sum(usd_disbursement_crs_upr, na.rm=T)
), by=.(year, recipient_iso3_code)]
oda_by_recipient_year = rbindlist(list(oda_by_recipient_year, iati_by_recipient_year), fill=T)
oda_by_recipient = oda_by_recipient_year[,.(
  usd_disbursement_deflated=sum(usd_disbursement_deflated, na.rm=T),
  usd_disbursement_lwr=sum(usd_disbursement_lwr, na.rm=T),
  usd_disbursement_upr=sum(usd_disbursement_upr, na.rm=T)
  ), by=.(recipient_iso3_code)]
purpose_code_dat = oda_by_recipient
setnames(purpose_code_dat, "recipient_iso3_code", "iso_3")
rm(
  crs, iati, iati_by_recipient_year,
  oda_by_recipient, oda_by_recipient_year
)

# Load keyword data
crs = fread("large_input/full_crs_keyword_2018_2022_zs_expanded_definitions_annotated.csv")
crs = subset(crs, false_positive==F)
crs = subset(crs, !endsWith(recipient_name, ", regional"))
crs = subset(crs, !endsWith(recipient_name, ", unspecified"))
crs = subset(crs, sector_code != "930" & aid_type!="E01" & aid_type!="E02")
iati = fread("input/modeled_crs_iati_keyword_search.csv")
iati = subset(iati, year==2023)

iati$usd_disbursement_crs = iati$usd_disbursement_crs * deflator_2023_to_2022
iati$usd_disbursement_crs_lwr = iati$usd_disbursement_crs_lwr * deflator_2023_to_2022
iati$usd_disbursement_crs_upr = iati$usd_disbursement_crs_upr * deflator_2023_to_2022

iati$usd_disbursement_crs_lwr = pmax(0, iati$usd_disbursement_crs_lwr)
iati$usd_disbursement_crs = pmax(0, iati$usd_disbursement_crs)

oda_by_recipient_year = crs[,.(usd_disbursement_deflated=sum(usd_disbursement_deflated, na.rm=T)), by=.(recipient_iso3_code, year)]
oda_by_recipient_year$usd_disbursement_lwr = oda_by_recipient_year$usd_disbursement_deflated
oda_by_recipient_year$usd_disbursement_upr = oda_by_recipient_year$usd_disbursement_deflated
iati_by_recipient_year = iati[,.(
  usd_disbursement_deflated=sum(usd_disbursement_crs, na.rm=T),
  usd_disbursement_lwr=sum(usd_disbursement_crs_lwr, na.rm=T),
  usd_disbursement_upr=sum(usd_disbursement_crs_upr, na.rm=T)
), by=.(year, recipient_iso3_code)]
oda_by_recipient_year = rbindlist(list(oda_by_recipient_year, iati_by_recipient_year), fill=T)
oda_by_recipient = oda_by_recipient_year[,.(
  usd_disbursement_deflated=sum(usd_disbursement_deflated, na.rm=T),
  usd_disbursement_lwr=sum(usd_disbursement_lwr, na.rm=T),
  usd_disbursement_upr=sum(usd_disbursement_upr, na.rm=T)
), by=.(recipient_iso3_code)]
keyword_dat = oda_by_recipient
setnames(keyword_dat, "recipient_iso3_code", "iso_3")
rm(
  crs, iati, iati_by_recipient_year,
  oda_by_recipient, oda_by_recipient_year, deflators
)

dat = merge(purpose_code_dat, keyword_dat, all=T,
            suffixes=c(".purpose", ".keyword"), by="iso_3")

dat[is.na(dat)] = 0
dat = subset(dat, iso_3 != "DPGC_X")

# Reshape
world_nat = geojsonio::geojson_read("shapefiles/simplified_adm0_polygons.json", what = "sp")
setdiff(unique(dat$iso_3), unique(world_nat$iso_3))
world_nat = merge(world_nat, dat, by="iso_3", all=T)
world_nat = subset(
  world_nat,
  select = c("iso_3", "adm0_name1",
             "usd_disbursement_deflated.purpose",
             "usd_disbursement_lwr.purpose",
             "usd_disbursement_upr.purpose",
             "usd_disbursement_deflated.keyword",
             "usd_disbursement_lwr.keyword",
             "usd_disbursement_upr.keyword"
  )
)


greens = c(
  "#109e68", "#92cba9", "#5ab88a", "#1e8259", "#16513a", "#c5e1cb", "#b1d8bb", "#a2d1b0", "#74bf93", "#3b8c61", "#00694a", "#005b3e", "#07482e"
)

reds = c(
  "#e84439", "#f8c1b2", "#f0826d", "#bc2629", "#8f1b13", "#fce3dc", "#fbd7cb", "#f6b0a0", "#ec6250", "#dc372d", "#cd2b2a", "#a21e25", "#6b120a"
)


quantile(dat$usd_disbursement_deflated.purpose, probs=c(0, 0.10, 0.20, 0.80, 0.90, 1), na.rm=T)
purpose.bins = c(
  0, 1, 10, 50, 100, 500, 1000, 1500
)
purpose.pal <- colorBin(reds[6:13], domain = c(world_nat$usd_disbursement_deflated.purpose), bins = purpose.bins)

quantile(dat$usd_disbursement_deflated.keyword, probs=c(0, 0.10, 0.20, 0.80, 0.90, 1), na.rm=T)
keyword.bins = c(
  0, 1, 10, 50, 100, 500, 1000, 1500
)
keyword.pal <- colorBin(reds[6:13], domain = c(world_nat$usd_disbursement_deflated.keyword), bins = keyword.bins)


popup.labels <- sprintf(
  paste0(
    "<strong>Country:</strong> %s<br/>",
    "<strong>Years:</strong> 2018-2023<br/>",
    "<strong>Purpose code housing ODA (US$ millions):</strong> %s<br/>",
    "<strong>Purpose code housing ODA range:</strong> %s - %s<br/>",
    "<strong>Keyword housing ODA (US$ millions):</strong> %s<br/>",
    "<strong>Keyword housing ODA range:</strong> %s - %s<br/>"
  ),
  world_nat$adm0_name1, 
  dollar(world_nat$usd_disbursement_deflated.purpose, 0.1),
  dollar(world_nat$usd_disbursement_lwr.purpose, 0.1),
  dollar(world_nat$usd_disbursement_upr.purpose, 0.1),
  dollar(world_nat$usd_disbursement_deflated.keyword, 0.1),
  dollar(world_nat$usd_disbursement_lwr.keyword, 0.1),
  dollar(world_nat$usd_disbursement_upr.keyword, 0.1)
) %>% lapply(htmltools::HTML)

legend_format = labelFormat(
  prefix="$",
  between=" to "
)


m <- leaflet(world_nat) %>%
  addMapPane("Purpose", zIndex = 0) %>%
  addMapPane("Keyword", zIndex = 0) %>%
  setView(25, 0, 3) %>%
  addProviderTiles(
    providers$CartoDB.PositronNoLabels,
    options = pathOptions(pane = "Keyword"),
    layerId = "Keyword",
  ) %>%
  addProviderTiles(
    providers$CartoDB.PositronNoLabels,
    options = pathOptions(pane = "Purpose"),
    layerId = "Purpose",
  ) %>%
  addPolygons(
    group = "Keyword",
    options = pathOptions(pane = "Keyword"),
    fillColor = ~keyword.pal(usd_disbursement_deflated.keyword),
    weight = 0.5,
    opacity = 1,
    color = "#000",
    dashArray = "",
    fillOpacity = 1,
    highlightOptions = highlightOptions(
      weight = 2,
      color = "#000",
      dashArray = "",
      fillOpacity = 1,
      bringToFront = TRUE
    ),
    popup = popup.labels,
    popupOptions = popupOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "15px",
      direction = "auto",
      closeOnClick = TRUE
    )
  )  %>%
  addPolygons(
    group = "Purpose",
    options = pathOptions(pane = "Purpose"),
    fillColor = ~purpose.pal(usd_disbursement_deflated.purpose),
    weight = 0.5,
    opacity = 1,
    color = "#000",
    dashArray = "",
    fillOpacity = 1,
    highlightOptions = highlightOptions(
      weight = 2,
      color = "#000",
      dashArray = "",
      fillOpacity = 1,
      bringToFront = TRUE,
      sendToBack = TRUE
    ),
    popup = popup.labels,
    popupOptions = popupOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "15px",
      direction = "auto",
      closeOnClick = TRUE
    )
  ) %>%
  addLegend(
    pal = keyword.pal, values = ~usd_disbursement_deflated.keyword,
    labFormat = legend_format,
    opacity = 1,
    title = "Housing ODA</br>by keyword</br>(US$ millions)",
    position = "bottomright"
  ) %>%
  addLegend(
    pal = purpose.pal, values = ~usd_disbursement_deflated.purpose,
    labFormat = legend_format,
    opacity = 1,
    title = "Housing ODA</br>by purpose code</br>(US$ millions)",
    position = "bottomleft"
  ) %>%
  addSidebyside(layerId = "sidecontrols",
                rightId = "Keyword",
                leftId  = "Purpose")
m
saveWidget(m, file="output/housing_comp_map.html")
