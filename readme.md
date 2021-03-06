# WordPress development on Docker

This image provides WordPress on PHP7. It generally follows the approach of the
official WordPress Docker image and adds better defaults, WP-CLI, PHPUnit,
Composer, Xdebug, and the WordPress unit testing suite.

```
docker pull chriszarate/wordpress
```

Most likely, you will want to connect this image to a MySQL / MariaDB container
and sync your plugin or theme code to it so that you can connect to a
development instance of WordPress in a browser. If that's the case, I can
recommend my [Docker Compose WordPress development][development] repo.


## Environment variables

- `WORDPRESS_ACTIVATE_PLUGINS`: A space-separated list of plugin paths relative
  to `/var/www/html/wp-content/wp-content/plugins/` that should be activated
  when the container starts.

- `WORDPRESS_ACTIVATE_THEME` A theme path relative to `/var/www/html/wp-content/wp-content/themes/`
  that should be activated when the container starts.

- `WORDPRESS_CONFIG_EXTRA`: Additional PHP to append to `wp-config.php`.

- `WORDPRESS_DB_HOST`: Default "mysql".

- `WORDPRESS_DB_NAME`: Default "wordpress".

- `WORDPRESS_DB_USER`: Default "root".

- `WORDPRESS_DB_PASSWORD`: Default "".

- `WORDPRESS_SITE_USER`: Default "wordpress"

- `WORDPRESS_SITE_PASSWORD`: Default "wordpress"

- `WORDPRESS_SITE_EMAIL`: Default "admin@example.com"

- `WORDPRESS_SITE_TITLE`: Default "Project".

- `WORDPRESS_SITE_URL`: Default "http://project.dev/".


## WP-CLI

```sh
docker exec wordpress wp [command]
```


## Running tests (PHPUnit)

Set `PHPUNIT_TEST_DIR` to the path containing `phpunit.xml`.

```sh
docker exec wordpress tests
```

Other environment variables:

- `PHPUNIT_DB_HOST`: Default "localhost".

- `PHPUNIT_DB_NAME`: Default "wordpress_phpunit".

- `PHPUNIT_DB_USER`: Default "root".

- `PHPUNIT_DB_PASSWORD`: Default "".

- `PHPUNIT_WP_CONTENT_LINKS`: A space-separated list of paths, relative to
  `/var/www/html/wp-content/`, that should be symlinked into the WordPress unit
  test suite directory so that they are available during testing.


## Xdebug

Xdebug is installed but needs the IP of your local machine to connect to your
local debugging client. Edit `.env` and populate the `DOCKER_LOCAL_IP`
environment variable with your machine's (local network) IP address. The default
`idekey` is `xdebug`.

```
XDEBUG_CONFIG: "remote_host=x.x.x.x idekey=xdebug"
```

You can enable profiling by appending additional instructions, e.g.:

```
XDEBUG_CONFIG: "remote_host=x.x.x.x idekey=xdebug profiler_enable=1 profiler_output_name=%R.%t.out"
```

This will output cachegrind files (named after the request URI and timestamp) to
`/tmp` inside the WordPress container.


## Seed `wp-content`

You can seed `wp-content` with files (e.g., an uploads folder) by mounting a
volume at `/tmp/wordpress/init-wp-content`. Everything in that folder will be
copied to your installation's `wp-content` folder.


[development]: https://github.com/chriszarate/docker-compose-wordpress
