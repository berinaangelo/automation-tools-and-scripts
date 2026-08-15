#!/bin/sh
set -e

cd /var/www/html

if [ "${DB_CONNECTION:-mysql}" = "sqlite" ]; then
    mkdir -p database
    [ -f database/database.sqlite ] || touch database/database.sqlite
fi
chmod -R ugo+rwx storage bootstrap/cache database

[ -L public/storage ] || php artisan storage:link

php artisan config:cache
php artisan route:cache
php artisan view:cache

# An explicit command (e.g. the one-off `migrate` service) always wins over
# role dispatch below.
if [ "$#" -gt 0 ]; then
    exec "$@"
fi

case "${APP_CONTAINER:-all}" in
    web|all)
        exec supervisord -c "/etc/supervisor/axiom/${APP_CONTAINER}.conf"
        ;;
    horizon)
        exec php artisan horizon
        ;;
    websocket)
        exec php artisan reverb:start
        ;;
    cron)
        exec php artisan schedule:work
        ;;
    *)
        echo "Unknown APP_CONTAINER: '${APP_CONTAINER}'. Expected one of: web, horizon, websocket, cron, all." >&2
        exit 1
        ;;
esac
