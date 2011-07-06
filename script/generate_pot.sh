#!/bin/bash

cd `dirname $0`

rake gettext:store_model_attributes
rake gettext:find
