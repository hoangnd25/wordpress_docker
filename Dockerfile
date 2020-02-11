ARG NGINX_VERSION=1.15
ARG PHP_VERSION=7.4

FROM nginx:${NGINX_VERSION}-alpine AS nginx

ENV PHP_SERVICE=php PHP_PORT=9000

COPY docker/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
COPY docker/nginx/docker-entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

WORKDIR /var/www/

# need this index file so nginx can start
COPY ./docker/nginx/public ./public

CMD ["entrypoint"]

FROM php:${PHP_VERSION}-fpm-alpine AS php

# persistent / runtime deps
RUN apk add --no-cache \
		acl \
		file \
		gettext \
		git \
	;

# Install various PHP extensions
RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
        icu-dev \
        oniguruma-dev \
        libmcrypt-dev \
        libxml2-dev \
		libzip-dev \
		zlib-dev \
	; \
	\
	docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) \
		intl \
		pcntl \
        mbstring \
        mysqli \
		pdo_mysql \
		zip \
	; \
	docker-php-ext-enable \
		opcache \
	; \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install gd \
    ; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache --virtual .api-phpexts-rundeps $runDeps; \
	\
	apk del .build-deps

COPY docker/php/php.ini /usr/local/etc/php/php.ini

# copy composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN set -eux; \
	composer global require "hirak/prestissimo:^0.3" --prefer-dist --no-progress --no-suggest --classmap-authoritative; \
	composer clear-cache
ENV PATH="${PATH}:/root/.composer/vendor/bin"