##### Data Processing Script #####
# Install/load required packages ---------------------------------------------------------
if(!require(devtools)) install.packages("devtools")
if(!require(atRfunctions)) install_github("atrcodebase/atRfunctions")
if(!require(stringr)) install.packages("stringr")
if(!require(readxl)) install.packages("readxl")
if(!require(glue)) install.packages("glue")
if(!require(googlesheets4)) install.packages("googlesheets4")
if(!require(dplyr)) install.packages("dplyr")
if(!require(writexl)) install.packages("writexl")
if(!require(openxlsx)) install.packages("openxlsx")
source("R/functions/custom_functions.R")

# Read data ------------------------------------------------------------------------------
data_path <- "input/raw_data/AGMS - Round 2 Final DCT.xlsx" # data path
convert_to_na <- c("NA", "N/A", "-", " ") # values to convert to NA
data <- read_excel(data_path, sheet = "data", guess_max = 100000, na = convert_to_na)

# Filter Complete interviews -------------------------------------------------------------
data <- data %>% 
  filter(phone_response_short == "Complete")

# read qa-log, correction log and L13_coding_log -----------------------------------------
url <- "https://docs.google.com/spreadsheets/d/1RS3JL-Qe-TcK6NtUM26YSRon02-AePpJXY8PCLXonYI/edit#gid=2048556262"
googlesheets4::gs4_deauth()
qa_log <- googlesheets4::read_sheet(url, sheet = "QA_Log_R2", col_types = "c")
correction_log <- googlesheets4::read_sheet(url, sheet = "Correction_log", col_types = "c")
rejection_log <- googlesheets4::read_sheet(url, sheet = "Refused & Incomplete due to language issues_Cases", col_types = "c")

# apply correction/translation log -------------------------------------------------------
# file.edit("R/apply_cleaning_log.R")
source("R/apply_cleaning_log.R")
if(nrow(correction_log_discrep) !=0){
  print("Correction Logs not applied -------------------")
  correction_log_discrep
}

# remove rejected keys -------------------------------------------------------------------
data <- data %>% 
  filter(KEY %notin% rejection_log$UUID)

# remove extra columns -------------------------------------------------------------------
# file.edit("R/remove_extra_columns.R")
source("R/remove_extra_columns.R")

# Filter Data ----------------------------------------------------------------------------
data <- data %>% 
  left_join(qa_log %>% select(KEY=UUID, qa_status=`Final QA Status`), by="KEY")
# Approved Data only
data_approved <- data %>% 
  filter(qa_status %in% "Approved")

# recode ---------------------------------------------------------------------------------
# double check in output
data <- data %>% 
  mutate(SubmissionDate=convertToDateTime(SubmissionDate),
         starttime=convertToDateTime(starttime),
         endtime=convertToDateTime(endtime))

# Unlabeled data (for relevancy check) -------------
unlabeled_data <- data

# attach value labels ------------------------------------------
tools_path <- "input/tools/AGMS+survey+round+2_Final (1).xlsx"
data <- atRfunctions::labeler(data = data,
                              tool = tools_path,
                              survey_label = "label",
                              choice_lable = "label",
                              multi_response_sep = " ")

# Export ---------------------------------------------------------------------------------
check_path("output/cleaned_data")
## export cleaned data
writexl::write_xlsx(list("data"=data), "output/cleaned_data/AGMS_Round_2_Final_DCT_cleaned.xlsx", format_headers = F) # AGMS Cleaned Data
writexl::write_xlsx(list("data"=unlabeled_data), "output/cleaned_data/AGMS_Round_2_Unlabeled_data.xlsx", format_headers = F) 
## export Correction Log Issues
writexl::write_xlsx(correction_log, glue::glue("output/Correction_log_{Sys.Date()}.xlsx")) # correction log
writexl::write_xlsx(correction_log_issues, "output/Correction_log_issues.xlsx", format_headers = F) # correction log issues

# export approved data ------------------------------------------------------------------------
check_path("output/approved_data")
writexl::write_xlsx(list("data"=data_approved), "output/approved_data/AGMS_Round_2_Final_DCT_approved.xlsx", format_headers = F) # AGMS cleaned data
