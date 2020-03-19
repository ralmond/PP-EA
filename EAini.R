## Adjust this to your configuration directory.



Proc4.config <- fromJSON("Proc4.json")
apps <- Proc4.config$apps[appStem]

dbhost <- "localhost"
dbuser <- "" # "EAP"
dbport <- "" # "27018"

builduri <- function (host,username,password,port) {
    security <- ""
    if (nchar(username) > 0L) {
        if (nchar(password) > 0L)
            security <- paste(username,password,sep=":")
        else
            security <- username
    }
    if (nchar(port) > 0L)
        host <- paste(host,port,sep=":")
    else
        host <- host
    if (nchar(security) > 0L)
        host <- paste(security,host,sep="@")
    paste("mongodb:/",host,sep="/")
}

dburi <-builduri(dbhost, dbuser,
                 Proc4.config$pwds[[dbuser]],
                 port)



EAeng.local <- list(dburi=dburi,dbname="EARecords",P4dbname="Proc4")

lognames <- sapply(appStem,
                   function (app) sub("<app>",app,EAeng.config$logname))



logfile <- file.path("/usr/local/share/Proc4/logs",lognames)


NeticaLicenseKey <- ""


## These are now loaded through config.json.
## config.dir <- "/home/ralmond/ownCloud/Projects/NSFCyberlearning/EvidenceAc/Sp2019nets"
## manifestFile <- "PPManifest.csv"
## statFile <- "StatisticList.csv"

## histNodes <-c("Physics","Torque","Energy","LinearMomentum","ForceAndMotion")
## histNodes <-c("Physics")
