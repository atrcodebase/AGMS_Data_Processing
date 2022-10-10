`%notin%` <- Negate(`%in%`)

check_path <- function(path){
  if (!file.exists(path)) {
    dir.create(path, showWarnings = TRUE, recursive = TRUE)
    cat("Created '", path, "' folder")
  } else {
    cat("The '",path,"' folder already exists")
  }
}


# Relevancy Function -------------------------------------------------------------------------------
relevancy_check <- function(data, tool_relevancy){
  # start.time <- Sys.time()
  tool_sub <- tool_relevancy %>% 
    filter(name %in% names(data)) 
  
  relevancy_log <- data.frame(KEY=NA,question=NA,q_val=NA,relevancy=NA,relevant_q=NA,
                              relev_val=NA)
  #loop through rows and tool
  for(i in 1:nrow(data)){
    
    prev_log_res <- NA
    final_match <- NA
    flagged_val <- c()
    flagged_var <- c()
    for(j in 1:nrow(tool_sub)){
      var_name <- tool_sub$name[j]
      
      data_q_val <- data[[var_name]][i]
      
      if(!is.na(data_q_val)){
        
        split_opr <- str_split(tool_sub$operator[j], " - ", simplify = T)
        # log_opr <- tool_sub$logical_opr[j]
        split_log_opr <- str_split(tool_sub$logical_opr[j], " - ", simplify = T)
        # opr_order <- tool_sub$operator_order[j]
        relev_var <- tool_sub$q[j]
        relev_var_val <- tool_sub$val[j]
        rep <- tool_sub$rep[j]
        last_rep <- tool_sub$last_rep[j]
        #Data relevant question value
        dt_relev_q_val <- data[[relev_var]][i]
        if(is.na(dt_relev_q_val)){
          dt_relev_q_val <- ""
        }
        
        #Using grepl for "Selected()" relevancies 
        if(split_opr[1] == "selected"){
          
          curr_log_res <- grepl(relev_var_val, dt_relev_q_val)
          
        } else if(grepl(" - ", relev_var_val)){
          
          curr_log_res <- multi_val(dt_relev_q_val, relev_var_val, split_opr, relev_var, split_val, split_log_opr)
          
        } else if(grepl("\\$\\{", relev_var_val)){
          
          relev_var_val <- str_extract(relev_var_val, "(?<=\\$\\{)(.*?)(?=\\})")
          curr_log_res <- match.fun(split_opr[1])(dt_relev_q_val, data[[relev_var_val]][i])
          
        } else {
          curr_log_res <- match.fun(split_opr[1])(dt_relev_q_val, relev_var_val)
        }
        #For questions that has more than one relevancy
        if(rep > 1){
          # for each repition, keep checking previous and current log result
          final_match <- match.fun(split_log_opr[1])(prev_log_res, curr_log_res)
        } else {
          final_match <- curr_log_res
        }
        #record the current flagged val
        if(!curr_log_res){
          flagged_var <- c(flagged_var, relev_var)
          flagged_val <- c(flagged_val, dt_relev_q_val)
        }
        
        # log if the final check is False
        if(last_rep & !final_match){
          log <- c(data$KEY[i], var_name, data_q_val, tool_sub$relevance[j], 
                   paste0(flagged_var, collapse = " - "), paste0(flagged_val, collapse = " - "))
          relevancy_log <- rbind(relevancy_log, log)
        } 
        #storing Current Final Logical Result for next check
        prev_log_res <- final_match
        #reset flagged values
        if(last_rep){
          flagged_val <- c()
          flagged_var <- c()
        }
      }
    }
  }
  relevancy_log <- relevancy_log[-1,]
  
  if(nrow(relevancy_log) == 0){
    message("There aren't any relavancy issues!")
  } else {
    message("Relevancy issues found in data!")
  }
  # end.time <- Sys.time()
  # time.taken <- end.time - start.time
  # print(time.taken)
  return(relevancy_log)
}
multi_val <- function(dt_relev_q_val, relev_var_val, split_opr, relev_var, split_val, split_log_opr){
  split_val <- str_split(relev_var_val, " - ", simplify = T)
  
  final_res <- NULL
  prev_res <- NULL
  for(val_i in 1:length(split_val)){
    curr_res <- match.fun(split_opr[val_i])(dt_relev_q_val, split_val[val_i])
    
    if(val_i != 1){
      final_res <- match.fun(split_log_opr[val_i-1])(prev_res, curr_res)
      prev_res <- final_res
    } else {
      prev_res <- curr_res
    }
  }
  
  return(final_res)
}

rank_check <- function(data){
  rank_options <- c(1, 2, 3, 4, 5, 6, 98, 99)
  
  relevancy_log <- data.frame(KEY=NA,question=NA,q_val=NA,relevancy=NA,relevant_q=NA,
                              relev_val=NA)
  for(i in 1:nrow(data)){
    rank1 <- str_split(data$rank1[i], " ")[[1]]
    rank2 <- str_split(data$rank2[i], " ")[[1]] 
    rank3 <- str_split(data$rank3[i], " ")[[1]]
    rank4 <- str_split(data$rank4[i], " ")[[1]]
    rank5 <- str_split(data$rank5[i], " ")[[1]]
    not_app_rank1 <- any(rank1 %in% c(6,98,99))
    
    if(not_app_rank1 & !all(is.na(rank2), is.na(rank3), is.na(rank4), is.na(rank5))){
      log <- c(data$KEY[i], "rank1", rank1, "Other ranks are not all NA", 
               paste0("rank2-3-4-5", collapse = " - "), 
               paste0(c(rank2, rank3, rank4, rank5), collapse = " - "))
      relevancy_log <- rbind(relevancy_log, log)
    } else {
      #rank2
      if(rank2 %notin% c(NA, 6, 98, 99) & any(rank2 %in% rank1)){
        log <- c(data$KEY[i], "rank2", rank2, "value in previous ranks",
                 paste0("rank1", collapse = " - "), paste0(rank1, collapse = " - "))
        relevancy_log <- rbind(relevancy_log, log)
      }
      #rank3
      if(rank3 %notin% c(NA, 6, 98, 99) & any(rank3 %in% c(rank1, rank2))){
        log <- c(data$KEY[i], "rank3", rank3, "value in previous ranks",
                 paste0("rank1-2", collapse = " - "), 
                 paste0(c(rank1, rank2), collapse = " - "))
        relevancy_log <- rbind(relevancy_log, log)
      }
      #rank4
      if(rank4 %notin% c(NA, 6, 98, 99) & any(rank4 %in% c(rank1, rank2, rank3))){
        log <- c(data$KEY[i], "rank4", rank4, "value in previous ranks",
                 paste0("rank1-2-3", collapse = " - "), paste0(c(rank1, rank2, rank3), collapse = " - "))
        relevancy_log <- rbind(relevancy_log, log)
      }
      #rank5
      if(rank5 %notin% c(NA, 6, 98, 99) & any(rank5 %in% c(rank1, rank2, rank3, rank4))){
        log <- c(data$KEY[i], "rank5", rank5, "value in previous ranks",
                 paste0("rank1-2-3-4", collapse = " - "), 
                 paste0(c(rank1, rank2, rank3, rank4), collapse = " - "))
        relevancy_log <- rbind(relevancy_log, log)
      }
    }
  }
  return(relevancy_log[-1,])
}
