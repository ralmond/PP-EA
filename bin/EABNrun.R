library(R.utils)
library(EIEvent)

appStem <- cmdArg("app",NULL)
if (is.null(appStem)) {
  stop("App not specified.")

source("/usr/local/share/Proc4/EAini.R")

EI.config <- fromJSON(file.path(config.dir,"config.json"),FALSE)

app <- as.character(Proc4.config$apps[appStem])
if (length(apps)==0L || any(apps=="NULL")) {
  stop("Could not find apps for ",appStem)
}
if (!(appStem %in% EA.config$appStem)) {
  stop("Configuration not set for app ",appStem)
}

logfile <- (file.path(logpath, sub("<app>",appStem,EA.config$logname)))
if (interactive()) {
  flog.appender(appender.tee(logfile))
} else {
  flog.appender(appender.file(logfile))
}
flog.threshold(EA.config$loglevel)

doRunrun(app,EA.config,EAeng.local,config.dir,outdir)
