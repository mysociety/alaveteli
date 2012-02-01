#!/bin/bash

cd `dirname $0`

rake gettext:store_model_attributes
rake gettext:find
git checkout ../locale/*/app.po

echo "Now commit the new app.pot and push.  See TRANSLATE.md for more info"