#!/bin/sh
set -eu
sentinel=/home/azureuser/lab07-asr/failover-test.txt
hostname
cat "$sentinel"
printf '%s  %s\n' '51a55aebb76fd1af39e4b487db648a5983e2619e237d62b6375ef1e53fd88806' "$sentinel" | sha256sum -c -
