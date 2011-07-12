The software translations are implemented using GNU gettext, and the
resource files are managed in Transifex.

The Transifex project is at
https://www.transifex.net/projects/p/alaveteli/; you'll probably want
an account there (ask on the mailing list).

# Finding new translatable strings

To update the POT file with strings from the software source, run
`rake gettext:find` from the Alaveteli software.  This will also
update all the PO files for all the languages, which you don't
actually want, because these are all handled in Transifex; so you'll
want to revert these files again using git.

# Pulling translations from Transifex
  
To update the local translation files using the Transifex command-line client, first install it:

    # easy_install transifex-client
  
Then you can run the following from the root of your Alaveteli install:

    tx pull -a
    
Finally, commit these translations to github as usual.

