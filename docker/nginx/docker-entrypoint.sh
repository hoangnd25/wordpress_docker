#!/bin/sh
set -e

cp /etc/nginx/conf.d/default.conf.bak /etc/nginx/conf.d/default.conf

sed -i -e 's/PHP_SERVICE/'${PHP_SERVICE}'/' /etc/nginx/conf.d/default.conf
sed -i -e 's/PHP_PORT/'${PHP_PORT}'/' /etc/nginx/conf.d/default.conf

nginx -g "daemon off;"
