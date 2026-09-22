# Documentation for developing Alaveteli

## Building your own docs

```
LANG=en_US.UTF-8 rdoc --main=doc/README.md -op doc/generated .
```
will build a local HTML site generated from the comments in the codebase.
The output will be under `<alaveteli_root>/p/`.

(the `LANG=` part is needed to circumvent [a bug in rdoc](https://github.com/ruby/rdoc/issues/1574#issuecomment-4860657680))
