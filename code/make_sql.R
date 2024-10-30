lapply(c("data.table"), require, character.only = T)
setwd(dirname(getActiveDocumentContext()$path))
setwd("../")

words = unique(fread("input/keywords.csv")$word)

word_barriers = paste0("\\y", words, "\\y")

regex = paste0(word_barriers, collapse="|")

# CRS
sql_1 = "\\COPY (SELECT * FROM crs_current WHERE year >= 2018 AND year <= 2023 AND category = 10 AND (project_title ~* '"
sql_2 = "' OR short_description ~* '"
sql_3 = "' OR long_description ~* '"
sql_4 = "')) TO 'large_input/full_crs_keyword_2018_2022.csv' WITH CSV HEADER;"

full_sql = paste0(
  sql_1, regex, sql_2, regex, sql_3, regex, sql_4
)
message(full_sql)

# IATI
sql_1 = "\\copy (select iati_identifier, reporting_org_ref, x_transaction_year, funding_orgs, x_sector_code, x_recipient_code, x_transaction_value_usd, title_narrative, description_narrative, transaction_description_narrative from repo.iati_transactions where x_vocabulary_number=1 and reporting_org_secondary_reporter in ('0', 'false') and x_transaction_year>=2018 and x_transaction_year<=2023 and x_transaction_type in ('Disbursement', 'Expenditure') and (title_narrative ~* '"
sql_2 = "' OR description_narrative ~* '"
sql_3 = "' OR transaction_description_narrative ~* '"
sql_4 = "')) TO 'large_input/full_iati_keyword_2018_2023.csv' WITH CSV HEADER;"

full_sql = paste0(
  sql_1, regex, sql_2, regex, sql_3, regex, sql_4
)
message(full_sql)
