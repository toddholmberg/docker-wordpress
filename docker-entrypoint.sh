#!/usr/bin/env bash

set -ex

# Copy WordPress core.
if ! [ -e index.php ] && ! [ -e wp-includes/version.php ]; then
  tar cf - --one-file-system -C /usr/src/wordpress . | tar xf - --owner="$(id -u www-data)" --group="$(id -g www-data)"
  echo "WordPress has been successfully copied to $(pwd)"
fi

# Seed wp-content directory if requested.
if [ -d /tmp/wordpress/init-wp-content ]; then
  tar cf - --one-file-system -C /tmp/wordpress/init-wp-content . | tar xf - -C ./wp-content --owner="$(id -u www-data)" --group="$(id -g www-data)"
  echo "Seeded wp-content directory from /tmp/wordpress/init-wp-content."
fi

# Create WordPress config.
if ! [ -f /var/www/html/wp-config.php ]; then
  wp core config \
    --dbhost="'${WORDPRESS_DB_HOST:-mysql}'" \
    --dbname="'${WORDPRESS_DB_NAME:-wordpress}'" \
    --dbuser="'${WORDPRESS_DB_USER:-root}'" \
    --dbpass="'$WORDPRESS_DB_PASSWORD'" \
    --skip-check \
    --extra-php <<PHP
$WORDPRESS_CONFIG_EXTRA
PHP
fi

# Update WP-CLI config with current virtual host.
sed -i -E "s/^url: .*/url: ${VIRTUAL_HOST:-project.dev}/" /etc/wp-cli/config.yml

# MySQL may not be ready when container starts.
set +ex
while true; do
  curl --fail --show-error --silent "${WORDPRESS_DB_HOST:-mysql}:3306" > /dev/null 2>&1
  if [ $? -eq 0 ]; then break; fi
  echo "Waiting for MySQL to be ready...."
  sleep 3
done
set -ex

# Install WordPress.
wp core install \
  --title="'${WORDPRESS_SITE_TITLE:-Project}'" \
  --admin_user="'${WORDPRESS_SITE_USER:-wordpress}'" \
  --admin_password="'${WORDPRESS_SITE_PASSWORD:-wordpress}'" \
  --admin_email="'${WORDPRESS_SITE_EMAIL:-admin@example.com}'" \
  --skip-email

# Activate plugins.
if [ -n "$WORDPRESS_ACTIVATE_PLUGINS" ]; then
  wp plugin activate "$WORDPRESS_ACTIVATE_PLUGINS"
fi

# Activate theme.
if [ -n "$WORDPRESS_ACTIVATE_THEME" ]; then
  wp theme activate "$WORDPRESS_ACTIVATE_THEME"
fi

# Setup PHPUnit.
if [ -f /tmp/wordpress/latest/wp-tests-config-sample.php ]; then
  sed \
    -e "s/.*ABSPATH.*/define( 'ABSPATH', getenv('WP_ABSPATH') );/" \
    -e "s/.*DB_HOST.*/define( 'DB_HOST', '${PHPUNIT_DB_HOST:-mysql_phpunit}' );/" \
    -e "s/.*DB_NAME.*/define( 'DB_NAME', '${PHPUNIT_DB_NAME:-wordpress_phpunit}' );/" \
    -e "s/.*DB_USER.*/define( 'DB_USER', '${PHPUNIT_DB_USER:-root}' );/" \
    -e "s/.*DB_PASSWORD.*/define( 'DB_PASSWORD', '$PHPUNIT_DB_PASSWORD' );/" \
    /tmp/wordpress/latest/wp-tests-config-sample.php > /tmp/wordpress/latest/wp-tests-config.php

  # Link resources needed for tests.
  for link in $PHPUNIT_WP_CONTENT_LINKS; do
    if ! [ -d "/tmp/wordpress/latest/src/wp-content/$link" ]; then
      mkdir -p "$(dirname "/tmp/wordpress/latest/src/wp-content/$link")"
      ln -s "/var/www/html/wp-content/$link" "/tmp/wordpress/latest/src/wp-content/$link" || echo "Symlink $link already exists."
    fi
  done

  # Create writeable uploads directory.
  # shellcheck disable=SC2174
  mkdir -p -m 777 /tmp/wordpress/latest/src/wp-content/uploads
fi

exec "$@"
