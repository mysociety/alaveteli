#!/bin/bash

# a small script useful for theme development (not for core alaveteli)
# This allows creating or updating a theme Gemfile/Gemfile.lock/gemset.nix
# with additional gems compared to core alaveteli.
#
# Run outside the nix development environment (as it uses a read-only Gemfile
# that cannot be modified)
# Usage example: bash nix/add_theme_gems.sh sparql "3.3.2"
# then move the resulting Gemfile and Gemfile.lock to the theme folder

NEW_GEM=$1
NEW_GEM_VER=$2

bundle config set --local path 'vendor/bundle'
bundle config set frozen false
bundle add $NEW_GEM --version $NEW_GEM_VER --skip-install --group=theme
