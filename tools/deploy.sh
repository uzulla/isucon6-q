#!/bin/bash

set -ex

IPADDR='13.78.115.165'

#DEPLOY_NOTI='echo "Deploying..." | /opt/slackcat --channel 80percent --stream --plain'
#DEPLOYED_NOTI='echo "Deployed!" | /opt/slackcat --channel 80percent --stream --plain'

#ssh isucon@$IPADDR "$DEPLOY_NOTI && cd /home/isucon/webapp && git checkout master && git pull origin master && ./tools/reload.sh && $DEPLOYED_NOTI"
ssh isucon@$IPADDR "cd /home/isucon/webapp && git checkout master && git pull origin master && /home/isucon/webapp/tools/reload.sh"

