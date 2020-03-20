ARG PHP_VERSION=7.4
FROM php:${PHP_VERSION}-cli-alpine

ARG PHP_EXTENSIONS=bcmath,gd,pcntl,pdo_mysql,redis,sockets,swoole,sysvmsg,sysvsem,sysvshm,zip
ARG ALPINE_REPOSITORIES=mirrors.aliyun.com
ARG COMPOSER_DIR=/.composer

ARG REDIS_VERSION=5.2.1
ARG SWOOLE_VERSION=4.4.16

ARG BUILD_DEPS=.build-deps

ARG EXTENSIONS=",${PHP_EXTENSIONS},"
ARG EXTENSIONS_PATH=/tmp/extensions

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME ${COMPOSER_DIR}
RUN set -ex \
    && php -r " \
    copy('https://getcomposer.org/installer', '/tmp/composer-setup.php'); \
    " \
    && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

WORKDIR ${EXTENSIONS_PATH}

COPY ./extensions ${EXTENSIONS_PATH}
COPY ./shell/install.sh /tmp/install.sh
RUN export MC="-j `nproc`" \
    && chmod +x /tmp/*.sh \
    && /tmp/install.sh

WORKDIR /var/www/html

# change config
RUN set -ex \
    && cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && \rm -rf /var/cache/apk/* /tmp/* /usr/share/man \
    && echo -e "\033[42;37m Build Completed :).\033[0m\n"
