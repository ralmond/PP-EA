library(R.utils)
library(EABN)

if (interactive()) {
  app <- "ecd://epls.coe.fsu.edu/P4test"
  loglevel <- "DEBUG"
  cleanFirst <- TRUE
  evidenceFile <- "/home/ralmond/Projects/EvidenceAc/Evidence10.json"
  evidenceFile <- NULL
} else {
  app <- cmdArg("app",NULL)
  if (is.null(app) || !grepl("^ecd://",app))
    stop("No app specified, use '--args app=ecd://...'")
  loglevel <- cmdArg("level","INFO")
  cleanFirst <- as.logical(cmdArg("clean",FALSE))
  evidenceFile <- cmdArg("evidence",NULL)

}

source("/usr/local/share/Proc4/EAini.R")

if (interactive()) {
  flog.appender(appender.tee(logfile))
} else {
  flog.appender(appender.file(logfile))
}
flog.threshold(loglevel)

sess <- NeticaSession(LicenseKey=NeticaLicenseKey)
startSession(sess)

listeners <- lapply(names(EA.listenerSpecs),
                    function (ll) do.call(ll,EA.listenerSpecs[[ll]]))
names(listeners) <- names(EA.listenerSpecs)
if (interactive()) {
  cl <- new("CaptureListener")
  listeners <- c(listeners,cl=cl)
}

eng <- do.call(BNEngine,c(EAeng.params,list(session=sess,listeners=listeners),
                          EAeng.common))
loadManifest(eng)
configStats(eng)

if (cleanFirst) {
  eng$evidenceSets()$remove(buildJQuery(app=app(eng)))
  eng$studentRecords()$clearAll(TRUE)   #Clear default, as we will set
                                        #it back up in a moment.
  eng$listenerSet$messdb()$remove(buildJQuery(app=app(eng)))
  for (lis in eng$listenerSet$listeners) {
    if (is(lis,"UpdateListener") || is(lis,"InjectionListener"))
      lis$messdb()$remove(buildJQuery(app=app(eng)))
  }

}
setupDefaultSR(eng)

if (!is.null(evidenceFile)) {
  system2("mongoimport",
          sprintf('-d %s -c EvidenceSets --jsonArray', eng$dbname),
          stdin=evidenceFile)
  NN <- eng$evidenceSets()$count(buildJQuery(app=app(eng),processed=FALSE))
}

if (interactive() && !is.null(evidenceFile)) {
  eng$processN <- NN
  eng$processN <- 48
}


## Activate engine (if not already activated.)
eng$activate()
mainLoop(eng)

## This is for running the loop by hand.
if (interactive() && FALSE) {
  eve <- eng$fetchNextEvidence()
  rec1 <- handleEvidence(eng,eve)
  eng$setProcessed(eve)
}
