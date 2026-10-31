#!/bin/sh
set -eu
printf 'HOSTNAME: '
hostname
printf 'ARCHITECTURE: '
uname -m
printf 'KERNEL: '
uname -r
cat /etc/os-release
printf '\nHTTPS_LOGIN_STATUS: '
curl --connect-timeout 10 --max-time 30 -sS -o /dev/null -w '%{http_code}\n' https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration
printf 'HTTPS_ARM_STATUS: '
curl --connect-timeout 10 --max-time 30 -sS -o /dev/null -w '%{http_code}\n' https://management.azure.com/
mkdir -p /home/azureuser/lab07-asr
printf '%s\n' 'AZ-104 Lab07 - Site Recovery' 'Version: 1' 'This file must survive a test failover.' > /home/azureuser/lab07-asr/failover-test.txt
printf '\nSENTINEL_CONTENT:\n'
cat /home/azureuser/lab07-asr/failover-test.txt
sha256sum /home/azureuser/lab07-asr/failover-test.txt
