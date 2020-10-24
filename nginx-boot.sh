#!/bin/bash

# Check for variables
export WORKER_CONNECTIONS=${WORKER_CONNECTIONS:-1024}
export HTTP_PORT=${HTTP_PORT:-80}
export REDIRECT=${REDIRECT:-https\:\/\/\$host}
export REDIRECT_TYPE=${REDIRECT_TYPE:-permanent}
export NGINX_CONF=/etc/nginx/mushed.conf
export HSTS=${HSTS:-0}
export HSTS_MAX_AGE=${HSTS_MAX_AGE:-31536000}
export HSTS_INCLUDE_SUBDOMAINS=${HSTS_INCLUDE_SUBDOMAINS:-0}
export LARGE_CLIENT_HEADER_BUFFERS=${LARGE_CLIENT_HEADER_BUFFERS:-8k}
export HEALTH_CHECK_PATH=${HEALTH_CHECK_PATH:-/health_check}

# Build config
cat <<EOF > $NGINX_CONF
user nginx;
daemon off;

events {
    worker_connections $WORKER_CONNECTIONS;
}

http {
    server {
        listen $HTTP_PORT;
        server_tokens off;
        large_client_header_buffers 4 $LARGE_CLIENT_HEADER_BUFFERS;
        $([ "${HSTS}" != "0" ] && echo "
        add_header Strict-Transport-Security \"max-age=${HSTS_MAX_AGE};$([ "${HSTS_INCLUDE_SUBDOMAINS}" != "0" ] && echo "includeSubDomains")\";
        ")
        location = $HEALTH_CHECK_PATH {
          return 200 "OK";
        }
        location / {
          rewrite ^(.*) $REDIRECT\$1 $REDIRECT_TYPE;
        }
    }
}

EOF

cat $NGINX_CONF;

mkdir -p /run/nginx;
chown -R nginx:nginx /var/lib/nginx /run/nginx ;

exec nginx -c $NGINX_CONF
