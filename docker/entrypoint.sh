#!/bin/sh

mailcatcher --ip=0.0.0.0

rm -f tmp/pids/server.pid
bin/rails server -b 0.0.0.0