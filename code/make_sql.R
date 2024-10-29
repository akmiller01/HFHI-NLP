lapply(c("data.table"), require, character.only = T)
setwd(dirname(getActiveDocumentContext()$path))
setwd("../")

words = unique(fread("input/keywords.csv")$word)

word_barriers = paste0("\\y", words, "\\y")

regex = paste0(word_barriers, collapse="|")

sql_1 = "\\COPY (SELECT * FROM crs_current WHERE year >= 2018 AND year <= 2023 AND category = 10 AND (project_title ~* '"
sql_2 = "' OR short_description ~* '"
sql_3 = "' OR long_description ~* '"
sql_4 = "')) TO 'large_input/full_crs_keyword_2018_2022.csv' WITH CSV HEADER;"

full_sql = paste0(
  sql_1, regex, sql_2, regex, sql_3, regex, sql_4
)
message(full_sql)
