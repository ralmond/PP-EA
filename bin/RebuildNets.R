library(googlesheets)
library(PNetica)

#########  Parameters
## This is the URL for the google sheet with the Model information.
## If this changes, copy the URL from your browser and paste it here.
PPmodelurl <- "https://docs.google.com/spreadsheets/d/16LcEuCspZjiBoZ3-Y1R3jxi1COXmh9vuTa9GwH1A_7Q/"

app <- "ecd://epls.coe.fsu.edu/P4test"
cleanFirst <- TRUE
loglevel <- "INFO"

source("/usr/local/share/Proc4/EAini.R")

## Set up logging
if (interactive()) {
  flog.appender(appender.tee(logfile))
} else {
  flog.appender(appender.file(logfile))
}
flog.threshold(loglevel)

## Start Netica Session
sess <- NeticaSession(LicenseKey=NeticaLicenseKey)
startSession(sess)

## Authorize to read from google sheets.  This should pop up a message
## in your default browser asking if you want allow
## "googsheets-tidyverse" to access your google drive.  That is this
## application.
gs_auth()


## Open a connection to the spreadsheet
PPmodelSS <- gs_url(PPmodelurl)

## The approach to both Network and Node management is that they are built
## On demand.  The Warehouse stashes the current copy of the network/node.
## If it doesn't have it yet, it uses the information in the manifest to build it.


## Don't need this yet, but read it up front as there is a bug in curl
## which causes an HTTP2 framing layer error if I wait around too long.
PPStats <- as.data.frame(gs_read_csv(PPmodelSS,"Statistics",
                                     stringsAsFactors=FALSE,trim_ws=TRUE))


### Networks
PPnetman <- gs_read_csv(PPmodelSS,"Nets",stringsAsFactors=FALSE,trim_ws=TRUE)
PPNethouse <- BNWarehouse(manifest=PPnetman,session=sess,key="Name")

if (FALSE) {
  ## Normally don't need to run these commands, but they allow
  ## you to update the manifest for a warehouse without rebuilding it.
  PPnetman <- gs_read_csv(PPmodelSS,"Nets",
                          stringsAsFactors=FALSE,trimws=TRUE)
  WarehouseManifest(PPNethouse) <- PPnetman
  DeleteNetwork(sess$nets$Angel)
}

### Nodes
PPnodeman <- gs_read_csv(PPmodelSS,"Nodes",stringsAsFactors=FALSE,trim_ws=TRUE)
PPNodehouse <- NNWarehouse(manifest=PPnodeman,
                         key=c("Model","NodeName"),
                         session=sess)
if (FALSE) {
  ## Normally don't need to run these commands, but they allow
  ## you to update the manifest for a warehouse without rebuilding it.

  PPnodeman <- gs_read_csv(PPmodelSS,"Nodes",
                           stringsAsFactors=FALSE,trimws=TRUE)
  WarehouseManifest(PPNodehouse) <- PPnodeman

  ## This deletes a damaged node.
  DeleteNodes(sess$nets$Blocked$nodes$AppropriateSlider)


}

## Build the Proficiency Model

PPOmega <- as.data.frame(gs_read_csv(PPmodelSS,"Omega",stringsAsFactors=FALSE,
                                     trim_ws=TRUE))
if (any(is.na(PPOmega$Node))) {
  flog.error("Missing node name in rows: ",
             which(is.na(PPOmega$Node))+1,capture=TRUE)
}

## Make blank proficiency model
Physics_CM <- WarehouseSupply(PPNethouse,na.omit(PPnetman$Hub)[1])
## And populate it.
Physics_CM <- Omega2Pnet(PPOmega,Physics_CM,PPNodehouse,override=TRUE)


## Next build the Evidence Models.
PPQ <- as.data.frame(gs_read_csv(PPmodelSS,"Q",
                                 stringsAsFactors=FALSE,trim_ws=TRUE))
if (any(is.na(PPQ$Model))) {
  flog.error("Missing model name in rows: ",
             which(is.na(PPQ$Model))+1,capture=TRUE)
}
if (any(is.na(PPQ$Node))) {
  flog.error("Missing node name in rows: ",
             which(is.na(PPQ$Node))+1,capture=TRUE)
}

Qmat2Pnet(PPQ, PPNethouse, PPNodehouse)


## This next set of commands looks at the spreadsheet for a single
## variable for use in isolating trouble.
if (FALSE) {
  unique(PPQ$Node)
  unique(PPQ$Model)
  PPX <- PPQ[PPQ$Model=="MagicBean" & PPQ$Node=="AppropriateSlider",]
  PPX <- PPQ[PPQ$Model=="LaundryDay" & PPQ$Node=="TrophyLevel",]
  PPX[,1:5]
  flog.threshold(INFO)
  DeleteNodes(sess$nets$Angels$nodes$Duration)
  Qmat2Pnet(PPX, PPNethouse, PPNodehouse, debug=FALSE)
}

if (FALSE) {
  ## This code continues on from the given place.
  which(PPnodeman$Model=="HitandRun" & PPnodeman$NodeName=="AppropriateSlider")
  w1 <- which(PPQ$Model=="HitandRun" & PPQ$Node=="AppropriateSlider")
  Qmat2Pnet(PPQ[w1[1L]:nrow(PPQ),], PPNethouse, PPNodehouse)
}



## Now save all the nets:

write.csv(PPnetman,file.path(config.dir,manifestFile))
for (name in PPnetman$Name) {
  if (nchar(name)>0L) {
    net <- WarehouseSupply(PPNethouse,name)
    WriteNetworks(net,file.path(config.dir,PnetPathname(net)))
  }
}

write.csv(PPStats,file.path(config.dir,statFile))

