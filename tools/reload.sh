#!/bin/bash

set -ex

# echo "Reloading..." | /opt/slackcat --channel 80percent --stream --plain

sudo sysctl -p
sudo systemctl daemon-reload

# mysql
sudo /etc/init.d/mysql restart

# nginx
sudo /etc/init.d/nginx restart

# middleware

# app
(cd /home/isucon/webapp/perl && /home/isucon/.local/perl/bin/carton install)
sudo systemctl restart isuda.per
sudo systemctl restart isutar.per

# echo "Reloaded!" | /opt/slackcat --channel 80percent --stream --plain

