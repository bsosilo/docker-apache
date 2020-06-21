#!/bin/bash

set -e

echo "Starting Xvfb on $DISPLAY"
exec Xvfb $DISPLAY &

source /etc/apache2/envvars
#tail -F /var/log/apache2/* &
echo "Starting Apache"
exec apache2 -D FOREGROUND