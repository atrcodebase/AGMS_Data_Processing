# clean the cleaning log -----------------------------------------------------------------
options(scipen = 999)
#Filter empty rows
correction_log_filtered <- correction_log %>% 
  filter(!(is.na(KEY) & is.na(question) & is.na(old_value)))

#identify issues
correction_log_filtered <- correction_log_filtered %>% 
  mutate(not_found = case_when(
    question %notin% names(data) ~ "question",
    KEY %notin% data$KEY ~ "KEY"))

correction_log_filtered$duplicates <- duplicated(correction_log_filtered[, c("KEY", "question")], fromLast = T) | duplicated(correction_log_filtered[, c("KEY", "question")])

correction_log_issues <- correction_log_filtered %>% 
  filter(!is.na(not_found) | duplicates == TRUE)

correction_log_filtered <- correction_log_filtered %>% 
  filter(is.na(not_found) & duplicates == FALSE)


# apply the correction-log ---------------------------------------------------------------
data_copy <- data
data <- atRfunctions::apply_log(data = data, log = correction_log_filtered,
                               data_KEY = "KEY",
                               log_columns = c(question = "question",
                                               old_value = "old_value",
                                               new_value = "new_value",
                                               KEY = "KEY"))

# Verify correction log -------------------------------------------
message("Verifying Correction log, please wait!")
correction_log_discrep <- compare_dt(df1 = data_copy, df2 = data,
                                     unique_id_df1 = "KEY", unique_id_df2 = "KEY") %>%
  anti_join(correction_log_filtered, c("KEY",
                                       "question",
                                       # "old_value",
                                       "new_value"))

# remove extra objects -------------------------------------------
rm(data_copy, correction_log_filtered)
