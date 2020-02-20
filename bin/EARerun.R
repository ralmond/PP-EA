library(R.utils)
library(EABN)

if (interactive()) {
  app <- "ecd://epls.coe.fsu.edu/P4test"
  loglevel <- "DEBUG"
  cleanFirst <- TRUE
  evidenceFile <- "/home1/ralmond/ownCloud/Projects/NSFCyberlearning/FSUSSp2019Data/EvidenceSets.Sp2019.json"
  evidenceFileb <- "/home1/ralmond/ownCloud/Projects/NSFCyberlearning/FSUSSp2019Data/EvidenceSets.Sp2019b.json"
  evidenceFile <- NULL
  reprocess <- TRUE
} else {
  app <- cmdArg("app",NULL)
  if (is.null(app) || !grepl("^ecd://",app))
    stop("No app specified, use '--args app=ecd://...'")
  loglevel <- cmdArg("level","INFO")
  cleanFirst <- as.logical(cmdArg("clean",FALSE))
  evidenceFile <- cmdArg("evidence",NULL)
  reprocess <- cmdArg("reprocess",is.null(evidenceFile))
}

#source("~/.Netica.R")
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

eng <- do.call(BNEngine,c(EAeng.params,
                          list(session=sess,listeners=listeners),
                          EAeng.common))
loadManifest(eng,read.csv(file.path(config.dir,manifestFile),
                          stringsAsFactors=FALSE))
configStats(eng,read.csv(file.path(config.dir,statFile),
                          stringsAsFactors=FALSE))

if (!is.null(evidenceFile)) {
  if (cleanFirst)
    eng$evidenceSets()$remove(buildJQuery(app=app(eng)))
  system2("mongoimport",
          sprintf('-d %s -c EvidenceSets --jsonArray', eng$dbname),
          stdin=evidenceFile)
}


if (cleanFirst) {
  eng$studentRecords()$clearAll(TRUE)   #Clear default, as we will set
                                        #it back up in a moment.
  eng$listenerSet$messdb()$remove(buildJQuery(app=app(eng)))
  for (lis in eng$listenerSet$listeners) {
    if (is(lis,"UpdateListener") || is(lis,"InjectionListener"))
      lis$messdb()$remove(buildJQuery(app=app(eng)))
  }

}
setupDefaultSR(eng)

if (reprocess) {
  eng$evidenceSets()$update(buildJQuery(app=app(eng)),
                       '{"$set":{"processed":false}}',
                       multiple=TRUE)
}

NN <- eng$evidenceSets()$count(buildJQuery(app=app(eng),processed=FALSE))

if (NN > 0L) {
  eng$processN <- NN
}
cat("Processing ",NN," records for application ",app(eng),".\n")

## Activate engine (if not already activated.)
eng$activate()
mainLoop(eng)

## This is for running the loop by hand.
if (interactive() && FALSE) {
  eve <- eng$fetchNextEvidence()
  rec1 <- handleEvidence(eng,eve,debug=1)
  eng$setProcessed(eve)
}

statCol <- listeners$UpdateListener$messdb()
stat1 <- statCol$find(buildJQuery(app=app(eng)))
statdat <- stat1$data
physdat <- statdat$Physics_Margin
names(physdat) <- paste("Physics",names(physdat),sep="_")
statdat1 <- cbind(statdat[,-which(names(statdat)=="Physics_Margin")],physdat)
stat <- cbind(stat1[,-which(names(stat1)=="data")],statdat1)

fname <- paste("stats",basename(app(eng)),"csv",sep=".")
write.csv(stat[1:21],fname)
file.copy(file.path("/home/ralmond/PhysicsPlayground",fname),
          file.path("/www1/www/https_docs/PhysicsPlayground",fname),
          overwrite=TRUE)


