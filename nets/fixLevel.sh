#!/bin/bash
sed -e 's/levels = (33.3, 33.33, 33.3);/levels = (0.967421566101701, 0, -0.967421566101701);/g' $1 >tmp.dne
mv $1 "$1.old"
mv tmp.dne $1

