lapply(c("data.table", "dplyr", "stringr", "tidyverse"), require, character.only = T)
setwd(dirname(getActiveDocumentContext()$path))
setwd("../")

dat = fread("large_input/full_crs_keyword_2018_2022_zs.csv")
dat$false_positive = dat$zs_label == "other"

textual_cols_for_classification = c(
  "project_title",
  "short_description",
  "long_description"
)

dat = dat %>%
  unite(text, all_of(textual_cols_for_classification), sep=" ", na.rm=T, remove=F)

mean(dat$false_positive)

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
fwrite(word_eval, "output/automated_keyword_evaluation.csv")
fwrite(dat, "large_input/full_crs_keyword_2018_2022_zs_annotated.csv")

