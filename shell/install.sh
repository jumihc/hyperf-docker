#!/bin/sh

### install

echo
echo "============================================"
echo "Install extensions from   : ${0##*/}"
echo "PHP version               : ${PHP_VERSION}"
echo "Extra Extensions          : ${PHP_EXTENSIONS}"
echo "Multicore Compilation     : ${MC}"
echo "Work directory            : ${PWD}"
echo "============================================"
echo

if [ "${ALPINE_REPOSITORIES}" != "" ]; then
    sed -i "s/dl-cdn.alpinelinux.org/${ALPINE_REPOSITORIES}/g" /etc/apk/repositories
    apk update
fi

if [ "${PHP_EXTENSIONS}" != "" ]; then
    echo "---------- Install general dependencies ----------"
    apk add --no-cache --virtual ${BUILD_DEPS} autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c
fi

if [ -z "${EXTENSIONS##*,bcmath,*}" ]; then
    php --ri bcmath &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "---------- Install bcmath ----------"
        docker-php-ext-install ${MC} bcmath
    else
        echo "---------- bcmath has been installed ----------"
    fi
fi

if [ -z "${EXTENSIONS##*,gd,*}" ]; then
    php --ri gd &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "---------- Install gd ----------"
        apk add --no-cache --virtual .gd-deps freetype-dev libjpeg-turbo-dev libpng-dev \
        && docker-php-ext-configure gd --with-freetype --with-jpeg \
        && docker-php-ext-install ${MC} gd
        apk del --no-network .gd-deps
    else
        echo "---------- gd has been installed ----------"
    fi
fi

if [ -z "${EXTENSIONS##*,pcntl,*}" ]; then
    php --ri pcntl &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "---------- Install pcntl ----------"
        docker-php-ext-install ${MC} pcntl
    else
        echo "---------- pcntl has been installed ----------"
    fi
fi

if [ -z "${EXTENSIONS##*,pdo_mysql,*}" ]; then
    php --ri pdo_mysql &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "---------- Install pdo_mysql ----------"
        docker-php-ext-install ${MC} pdo_mysql
    else
        echo "---------- pdo_mysql has been installed ----------"
    fi
fi

if [ -z "${EXTENSIONS##*,redis,*}" -a \
-f "redis-${REDIS_VERSION}.tgz" ]; then
    php --ri redis &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "---------- Install redis ----------"
        mkdir redis \
        && tar -xf redis-${REDIS_VERSION}.tgz -C redis --strip-components=1 \
        && ( cd redis && phpize && ./configure && make ${MC} && make install ) \
        && docker-php-ext-enable redis
        if [ $? != 0 ]; then
            echo -e '\033[31m Install redis fail. \033[0m'
            exit 1
        fi
    else
        echo "---------- redis has been installed ----------"
    fi
fi

if [ -z "${EXTENSIONS##*,sockets,*}" ]; then
    php --ri sockets &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "---------- Install sockets ----------"
        docker-php-ext-install ${MC} sockets
    else
        echo "---------- sockets has been installed ----------"
    fi
fi

if [ -z "${EXTENSIONS##*,swoole,*}" -a \
-f "swoole-${SWOOLE_VERSION}.tgz" ]; then
    php --ri swoole &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "---------- Install swoole ----------"
        apk add --no-cache --virtual .swoole-deps openssl-dev
        mkdir swoole \
        && tar -xf swoole-${SWOOLE_VERSION}.tgz -C swoole --strip-components=1 \
        && ( cd swoole && phpize && ./configure --enable-http2 --enable-mysqlnd \
        --enable-openssl -with-openssl-dir=/usr/include/openssl \
        && make ${MC} && make install ) \
        && docker-php-ext-enable swoole
        if [ $? != 0 ]; then
            echo -e '\033[31m Install swoole fail. \033[0m'
            exit 1
        fi
        apk del --no-network .swoole-deps
    else
        echo "---------- swoole has been installed ----------"
    fi
fi

if [ -z "${EXTENSIONS##*,sysvmsg,*}" ]; then
    php --ri sysvmsg &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "---------- Install sysvmsg ----------"
        docker-php-ext-install ${MC} sysvmsg
    else
        echo "---------- sysvmsg has been installed ----------"
    fi
fi

if [ -z "${EXTENSIONS##*,sysvsem,*}" ]; then
    php --ri sysvsem &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "---------- Install sysvsem ----------"
        docker-php-ext-install ${MC} sysvsem
    else
        echo "---------- sysvsem has been installed ----------"
    fi
fi

if [ -z "${EXTENSIONS##*,sysvshm,*}" ]; then
    php --ri sysvshm &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "---------- Install sysvshm ----------"
        docker-php-ext-install ${MC} sysvshm
    else
        echo "---------- sysvshm has been installed ----------"
    fi
fi

if [ -z "${EXTENSIONS##*,zip,*}" ]; then
    php --ri zip &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "---------- Install zip ----------"
        apk add --no-cache --virtual .zip-deps libzip-dev
        docker-php-ext-install ${MC} zip
        apk del --no-network .zip-deps
    else
        echo "---------- zip has been installed ----------"
    fi
fi

### php-handle-deps

echo "---------- Install RUN DEPS ----------"
RUN_DEPS="$( \
    scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
        | tr ',' '\n' \
        | sort -u \
        | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
)"
apk add --no-cache ${RUN_DEPS};

if apk info --installed ${BUILD_DEPS} > /dev/null; then
    echo "---------- UnInstall BUILD DEPS ----------"
    apk del --no-network ${BUILD_DEPS}
fi

exit 0
