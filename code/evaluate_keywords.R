lapply(c("data.table", "dplyr", "stringr", "tidyverse"), require, character.only = T)
setwd(dirname(getActiveDocumentContext()$path))
setwd("../")

data_source = "full_iati_keyword_2018_2023"
# data_source = "full_crs_keyword_2018_2022"

dat = fread(paste0("large_input/",data_source,"_zs_expanded_definitions.csv"))
dat$false_positive = startsWith(dat$zs_label, "is primarily about other")

mean(dat$false_positive)

textual_cols_for_classification = c(
  "title_narrative",
  "description_narrative",
  "transaction_description_narrative"
)
# textual_cols_for_classification = c(
#   "project_title",
#   "short_description",
#   "long_description"
# )

dat = dat %>%
  unite(text, all_of(textual_cols_for_classification), sep=" ", na.rm=T, remove=F)

keywords = unique(fread("input/keywords.csv")$word)

word_list = list()
word_index = 1
for(word in keywords){
  message(word)
  regex = paste0(
    "\\b",
    word,
    "\\b"
  )
  dat[,word] = grepl(regex, dat$text, perl=T, ignore.case = T)
  matches = dat[which(dat[,word]),]
  if(nrow(matches) > 0){
    word_df = data.frame(
      word,
      n=nrow(matches),
      false_positive_rate=mean(matches$false_positive)
    )
    word_list[[word_index]] = word_df
    word_index = word_index + 1
  }
}

word_eval = rbindlist(word_list)
fwrite(word_eval, "output/automated_keyword_evaluation_iati.csv")
fwrite(dat, paste0("large_input/",data_source,"_zs_expanded_definitions_annotated.csv"))

