library(R.utils)
library(EABN)

## Sync with Git
branch <- cmdArg("branch","PP-main")

setwd("~/Projects/PP-EA")
system2("git","pull")

found <- system2("git",c("branch","--list",branch),stdout=TRUE)
if (length(found) != 1L)
    stop("Configuration ",branch," not found.")

ecode <- system2("git",c("checkout",branch))
if (ecode != 0L)
    stop("Errors loading the branch")


## Load Configuration
EAeng.config <- fromJSON("config.json")
appStem <- as.character(EAeng.config$appStem)

## Note:  appStem should be set before loading configurations.
source("/usr/local/share/Proc4/EAini.R")

