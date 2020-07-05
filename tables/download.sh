#!/bin/bash

cd $1
## To get the SHEETID, go to the google sheet in question and click share.
## Generate a view link, and then copy the link and paste it here.
## Next edit everything after the final "/", including the final slash.

#BASEURL="https://docs.google.com/spreadsheets/d/16LcEuCspZjiBoZ3-Y1R3jxi1COXmh9vuTa9GwH1A_7Q"
BASEURL="https://docs.google.com/spreadsheets/d/$2"

curl "${BASEURL}/gviz/tq?tqx=out:csv&sheet={Nets}" >Nets.csv
curl "${BASEURL}/gviz/tq?tqx=out:csv&sheet={Nodes}" >Nodes.csv
curl "${BASEURL}/gviz/tq?tqx=out:csv&sheet={Q}" >Q.csv
curl "${BASEURL}/gviz/tq?tqx=out:csv&sheet={Omega}" >Omega.csv
curl "${BASEURL}/gviz/tq?tqx=out:csv&sheet={Statistics}" >Statistics.csv


