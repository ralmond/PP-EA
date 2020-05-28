library(R.utils)
library(EABN)
library(PNetica)

if (interactive()) {
    branch <- "PP-main"
} else {
    branch <- cmdArg("branch","PP-main")
}

system2("git", "pull")
system2("git", c("checkout",branch))

source("/usr/local/share/Proc4/EAini.R")

EA.config <- fromJSON(file.path(config.dir,"config.json"),FALSE)

appStem <- as.character(EA.config$appStem)

apps <- Proc4.config$apps[appStem]
if (length(apps)==0L || any (is.na(apps))) {
  stop("Could not find apps for ",appStem)
}

sess <- NeticaSession(LicenseKey=NeticaLicenseKey)
startSession(sess)

## <<HERE>> Need to load extensions.

trimTable <- function (tab, lastcol="Description") {
    nlcol <- which(colnames(tab)==lastcol)
    tab[,1:nlcol]
}



if (isTRUE(EA.config$rebuildNets)) {

  EA.tables <- EA.config$Tables
  tid <- EA.tables$TableID
  if (!is.null(tid) && nchar(tid)>0L) {
    ## Read from Google sheet
    ## This should work, and indeed this URL works with curl, but it always
    ## downloads the Nodes sheet when called directly from read.csv.
    ## templateURL <- paste("https://docs.google.com/spreadsheets/d",tid,
    ##                    "gviz/tq?tqx=out:csv&sheet={%s}",
    ##                    sep="/")
    ## Give up and just use CURL
    system2("./tables/download.sh",tid)

  }
  ## Read from the tables directory
  templateURL <- file.path(config.dir,"tables","%s.csv")

  stattab <- read.csv(sprintf(templateURL,EA.tables$StatName),
                      stringsAsFactors=FALSE,strip.white=TRUE)
  stattab <- trimTable(stattab,"Node")
  netman <- read.csv(sprintf(templateURL,EA.tables$NetsName),
                     stringsAsFactors=FALSE,strip.white=TRUE)
  netman <- trimTable(netman)
  nodeman <- read.csv(sprintf(templateURL,EA.tables$NodesName),
                      stringsAsFactors=FALSE,strip.white=TRUE)
  nodeman <- trimTable(nodeman,"UpperBound")
  Omega <- read.csv(sprintf(templateURL,EA.tables$OmegaName),
                    stringsAsFactors=FALSE,strip.white=TRUE)
  Omega <- trimTable(Omega,"PriorWeight")
  QQ <- read.csv(sprintf(templateURL,EA.tables$QName),
                 stringsAsFactors=FALSE,strip.white=TRUE)
  QQ <- trimTable(QQ,"PriorWeight")
  ## Now build the models
  Nethouse <- PNetica::BNWarehouse(manifest=netman,session=sess,key="Name")
  Nodehouse <- PNetica::NNWarehouse(manifest=nodeman,
                           key=c("Model","NodeName"),
                           session=sess)

  ## Build Competency Model
  if (any(is.na(Omega$Node))) {
    flog.error("Missing node name in rows: ",
               which(is.na(Omega$Node))+1,capture=TRUE)
  }
  CM <- WarehouseSupply(Nethouse,EA.tables$CMName)
  CM <- Omega2Pnet(Omega,CM,Nodehouse,override=TRUE)

  ## Build Evidence Models
  if (any(is.na(QQ$Model))) {
    flog.error("Missing model name in rows: ",
               which(is.na(QQ$Model))+1,capture=TRUE)
  }
  if (any(is.na(QQ$Node))) {
    flog.error("Missing node name in rows: ",
               which(is.na(QQ$Node))+1,capture=TRUE)
  }
  Qmat2Pnet(QQ,Nethouse,Nodehouse)

  write.csv(netman,file.path(config.dir,"nets",
                             EA.config$EAEngine$manifestFile))

  for (name in netman$Name) {
    if (nchar(name)>0L) {
      net <- WarehouseSupply(Nethouse,name)
      WriteNetworks(net,file.path(config.dir,"nets",PnetPathname(net)))
    }
  }
  write.csv(stattab,file.path(config.dir,"nets",EA.config$EAEngine$statFile))


}

##<<HERE>> Need to make the run in parallel.
for (app in apps) {
  sapp <- basename(app)

  flog.appender(appender.file(file.path(logpath,
                                   sub("<app>",sapp,EA.config$logname))))
  flog.threshold(EA.config$loglevel)
  listeners <- lapply(EA.config$listeners, buildListener,app,dburi)
  names(listeners) <- sapply(listeners,listenerName)

  EAeng.params <- c(EA.config$EAEngine,EAeng.local)
  EAeng.params$histNodes <- as.character(EAeng.params$histNodes)
  EAeng.params$listenerSet <-
    ListenerSet(sender= sub("<app>",sapp,EA.config$sender),
                dbname=EA.config$dbname, dburi=dburi,
                listeners=listeners,
                colname=EA.config$lscolname)
  netman <- read.csv(file.path(config.dir,"nets",
                               EA.config$EAEngine$manifestFile),
                     stringsAsFactors=FALSE,strip.white=TRUE)
  EAeng.params$warehouse <-
    PNetica::BNWarehouse(manifest=netman,
                         session=sess,key="Name",
                         address=file.path(config.dir,"nets"))

  eng <- do.call(ifelse(dburi=="",BNEngineNDB,BNEngineMongo),
                 EAeng.params)
  loadManifest(eng,netman)
  stattab <- read.csv(file.path(config.dir,"nets",
                                 EA.config$EAEngine$statFile),
                       stringsAsFactors=FALSE,strip.white=TRUE)
  configStats(eng,stattab)

  if (!is.null(EA.config$listenerReset)) {
    resetListeners(eng$listenerSet,as.character(EA.config$listenerReset),app)
  }
  if (dburi != "") {
    if (EA.config$filter$doRemove) {
      rquery <- buildJQuery(c(list(app=app,EA.config$filter$remove)))
      eng$evdienceSets()$remove(rquery)
    }
    if (isTRUE(EA.config$SRreset)) {
      eng$studentRecords()$clearAll(TRUE)   #Clear default, as we will set
                                        #it back up in a moment.
    }
    ## Import <<HERE>>
    if (isTRUE(EA.config$filter$doReprocess)) {
      rquery <- buildJQuery(c(list(app=app,EA.config$filter$update)))
      eng$evidenceSets()$update(rquery,'{"$set":{"processed":false}}')
    }
  }
  setupDefaultSR(eng)
  if (EA.config$limitNN=="ALL") {
    eng$processN <- eng$evidenceSets()$count(buildJQuery(app=app,
                                                         processed=FALSE))
  } else {
    eng$processN <- as.numeric(EA.config$limitNN)
  }
  flog.info("Begining EA for application %s.",basename(app))
  if (is.finite(eng$processN)) {
    flog.info("%d messages queued.",eng$processN)
  } else {
    flog.info("Running in server mode.")
  }
  mainLoop(eng)

  if (!is.null(EA.config$statListener)) {
    sl <- listeners[[EA.config$statListener]]
    if (is.null(sl)) {
      flog.error("Stat listener %s not found, skipping building stat file.",
                 EA.config$statListener)
    } else {
      stat1 <- sl$messdb()$find(buildJQuery(app=app))
      sdat <- data.frame(stat1[,c("app","uid","context","timestamp")],
                         flatten(stat1$data))
      sdat$app <- basename(sdat$app)
      fname <- gsub("<app>",sapp,EA.config$statfile)
      write.csv(stat1,fname)
      file.copy(fname,
                file.path("/www1/www/https_docs/PhysicsPlayground",
                          basename(fname)),
                overwrite=TRUE)
    }
  }
}

