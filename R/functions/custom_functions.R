`%notin%` <- Negate(`%in%`)

check_path <- function(path){
  if (!file.exists(path)) {
    dir.create(path, showWarnings = TRUE, recursive = TRUE)
    cat("Created '", path, "' folder")
  } else {
    cat("The '",path,"' folder already exists")
  }
}



