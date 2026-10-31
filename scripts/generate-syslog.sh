#!/bin/sh
set -eu
logger -p local0.info 'LAB07_POST_BICEP info'
logger -p local0.warning 'LAB07_POST_BICEP warning'
logger -p local0.err 'LAB07_POST_BICEP error'
logger -p local0.debug 'LAB07_POST_BICEP excluded-debug'
logger -p local1.warning 'LAB07_POST_BICEP excluded-local1'
