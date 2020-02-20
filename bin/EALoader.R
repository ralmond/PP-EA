###
## These are R functions for loading the contexts and rules into the Eng

library(EABN)
app <- "ecd://epls.coe.fsu.edu/PhysicsPlayground/Sp2019/EAConfig"
source("/usr/local/share/Proc4/EAini.R")
flog.appender(appender.tee(logfile))
flog.threshold(INFO)

sess <- NeticaSession(LicenseKey=NeticaLicenseKey)
startSession(sess)

listeners <- lapply(names(EA.listenerSpecs),
                    function (ll) do.call(ll,EA.listenerSpecs[[ll]]))
names(listeners) <- names(EA.listenerSpecs)


mantab <- read.csv(file.path(config.dir, manifestFile),as.is=TRUE)
if (is.null(mantab$Name)) stop ("No names in manifest file",
                                file.path(config.dir, manifestFile))

badnames <- !sapply(mantab$Name,is.IDname)
if (any(badnames))
  stop ("Illegal Netica names in manifest:",
        paste(mantab$Name[badnames],collapse=", "))

if (is.null(mantab$Pathname)) stop ("No pathnames in manifest file",
                                file.path(config.dir, manifestFile))

rownames(mantab) <- mantab$Name
## mantab$Pathname <- file.path(config.dir,mantab$Pathname)

stattab <- read.csv(file.path(config.dir, statFile),as.is=TRUE)


variants <- c("ecd://epls.coe.fsu.edu/P4test",
              file.path(file.path(dirname(app),c("userContorl","linear","adaptive"))))
tapp <- "ecd://epls.coe.fsu.edu/P4test"
elist <- list()
for (tapp in variants) {
  eng <- do.call(BNEngine, c(list(app=tapp,session=sess,listeners=listeners),
                             EAeng.common))
  loadManifest(eng,mantab)
  eng$setHistNodes(histNodes)
  configStats(eng,stattab)
  setupDefaultSR(eng)
  elist[[tapp]] <- eng
}



## Load default student records.
## system2("mongoimport",args=sprintf("-d Proc4 -c Statistics --jsonArray %s",
##                                    file.path(config.dir,"defaultStats.json")))

