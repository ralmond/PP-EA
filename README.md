# PP-EA
Physics Playground Evidence Accumulation Model


## Network preparation

The files for configuring the network are on a Google Sheets, with a different sheet corresponding to each input file.  The CSV files are:
* `Nets` -- names and metadata about the nets.
* `Nodes` -- names and metadata about the nodes.
* `Omega` -- the relationships between the variables in the proficiency model.
* `Q` -- the relationship between the proficiency and observable variables.
* `Statistics` -- a list of statistics to be reported after each round.

The file `download.sh` will pull these from sheets in the Google doc, to csv files in the `tables` directory.

The file `BuildNets.R` will generate the networks from these nets.

## Running procedures.

Here are the steps that need to be done to do a scoring run.

1. Do a git pull to bring server up to date with repository.
2. Do a git branch to put server on correct version of setup for this
   run.
3. Run the `EALoader` script to load the configuration into the
   database.
   This needs a `config.json` file that specifies details about the run.
4. If running in server mode, run the EABN script to start the
   server.
5. In running in rerun mode, run a query to mark appropriate events as
   unprocessed. 
6. Run the EABN script to do the rerun process.

