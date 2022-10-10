# remove extra columns -------------------------------------------------------------------
extra_cols <- c("deviceid", "subscriberid", "simid", "devicephonenum", "instance_time", 
  "text_audit", "full_audio_audit", "phone_call_log", "phone_call_duration", 
  "collect_phone_app", "device_info", "full_name", "address", "users", 
  "pub_to_users", "call_datetime", "call_date", "call_time", "callback_time", 
  "new_sortby", "last_call_status", "num_calls", "call_num", "stop_at", 
  "review_status", "needs_review", "now_complete", "calltime", 
  "introduction", "introduction_dari", "introduction_pashto", "call_respondent", 
  "mkp_reached", "mkp_reached_dari", "mkp_reached_pashto", "AA1", 
  "AA2", "AA3", "AA4", "AA5", "AA6", "AA7", "AA8", "AA9", "AA10", 
  "otherpresent", "end_time", "reschedule_full", "Please_Select_The_Qa_Status_Of_The_Survey", 
  "qa", "instanceID", "formdef_version", "review_quality", 
  "review_comments", "review_corrections") #kept "reschedule", "reschedule_no_ans"

data <- data %>% 
  select(-all_of(extra_cols))

# remove extra objects -------------------------------------------------------------------
rm(extra_cols)