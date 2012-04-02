#!/bin/bash

echo "This is NOT a completed script! Just use it as reference for what to do from the command line, or fix it until it works!"
exit 1

cd `dirname $0`
# grab latest po files from Transifex
tx pull -a -f
git status | grep app.po | awk '{print $3}' | xargs git add
git commit -m "Backup latest po files from Transifex"

# now regenerate POT and PO files from Alaveteli source
rake gettext:store_model_attributes
rake gettext:findpot

# upload the result to Transifex
tx push -t 

# re-download (it removes the fuzzy strings and normalises it to the format last committed)
tx pull -a -f
git status | grep app.po | awk '{print $3}' | xargs git add
git commit -m "Updated POT"
