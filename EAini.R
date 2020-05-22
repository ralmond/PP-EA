## Adjust this to your configuration directory.

Proc4.config <- fromJSON("Proc4.json")

dbhost <- "localhost"
dbuser <- "" # "EAP"
dbport <- "" # "27018"

dburi <-Proc4::makeDBuri(dbuser, Proc4.config$pwds[[dbuser]],
                         dbhost, dbport)

EAeng.local <- list(dburi=dburi,dbname="EARecords",admindbname="Proc4")


config.dir <- "/home/ralmond/Projects/PP-EA"

logpath <- "/usr/local/share/Proc4/logs"

NeticaLicenseKey <- ""


## These are now loaded through config.json.
## config.dir <- "/home/ralmond/ownCloud/Projects/NSFCyberlearning/EvidenceAc/Sp2019nets"
## manifestFile <- "PPManifest.csv"
## statFile <- "StatisticList.csv"

## histNodes <-c("Physics","Torque","Energy","LinearMomentum","ForceAndMotion")
## histNodes <-c("Physics")
