#!/bin/bash
set -e

if [ -n "$DB_HOST" ]; then
  echo "Waiting for database $DB_HOST..."
  until nc -z "$DB_HOST" "${DB_PORT:-3306}"; do
    sleep 0.5
  done
fi

# Ensure required dirs exist
mkdir -p storage bootstrap/cache
mkdir -p storage/framework/views storage/framework/cache storage/framework/sessions storage/logs
chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true
chmod -R 775 storage bootstrap/cache 2>/dev/null || true

# Storage symlink
if [ ! -L "public/storage" ]; then
  echo "Creating storage symlink..."
  ln -s ../storage/app/public public/storage || true
fi

chmod -R 755 public || true

# Skip all caching commands since they trigger package discovery
# which fails with dev-only packages excluded
# php artisan config:cache || true
# php artisan route:cache || true
# php artisan view:cache || true

# Run migrations if enabled
if [ "$LARAVEL_MIGRATE" = "true" ]; then
  php artisan migrate --force
fi

exec "$@"
