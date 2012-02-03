#!/bin/bash

cd `dirname $0`

rake gettext:store_model_attributes
rake gettext:findpot

echo "Now commit the new app.pot and push.  See TRANSLATE.md for next steps"