#!/bin/bash

if [[ $(id -u) -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

# If PHP-FPM wasn't stopped properly, its .pid file will still exist. When
# restarting the service, it will get stuck if a stale .pid file exists.
# Remove the stale existing .pid files so the restart won't get stuck.
for file in `find /opt/phpenv/versions -name "*.pid"`
do
  PHPFPM_PID=$(cat $file)
  PID_CMD=$(ps -p $PHPFPM_PID -o comm=)

  if [[ "$PID_CMD" != "php-fpm" ]]; then
    echo "Removing stale pid file [$file]."
    rm -f $file
  fi
done

service redis-server restart
service mysql restart
service apache2 restart

# Loop through all the PHP-FPM services and restart them.
for phpfpm in `service --status-all 2>&1 | grep -o php-fpm.*`
do
  echo "Restarting service $phpfpm."
  service $phpfpm restart
done

service mailpit restart