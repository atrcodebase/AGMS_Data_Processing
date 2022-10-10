# Install/load required packages ---------------------------------------------------------
if(!require(stringr)) install.packages("stringr")
if(!require(readxl)) install.packages("readxl")
if(!require(dplyr)) install.packages("dplyr")
if(!require(glue)) install.packages("glue")
if(!require(writexl)) install.packages("writexl")
if(!require(tidyr)) install.packages("tidyr")
source("R/functions/custom_functions.R")

# Read data ------------------------------------------------------------------------------
convert_to_na <- c("NA", "N/A", "-", " ") # values to convert to NA
data <- read_excel("output/cleaned_data/AGMS_Round_2_Unlabeled_data.xlsx", 
                   sheet = "data", guess_max = 100000, na = convert_to_na)
tool_relevancy <- read_excel("input/tools/tool_relevancies.xlsx")

#apply function --------------------------------------------------------------------------
relevancy_issues <- relevancy_check(data, tool_relevancy)

# check Rank option question
relevancy_issues <- rbind(
  relevancy_issues, 
  rank_check(data)
)

#Export ----------------------------------------------------------------------------------
writexl::write_xlsx(relevancy_issues, "output/Tool_relevancy_issues.xlsx")
