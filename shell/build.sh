#!/bin/sh

root_dir=`pwd`
root_dir=${root_dir%%'/shell'}

docker build \
-f ${root_dir}/Dockerfile \
-t jmhc/hyperf-docker \
--build-arg PHP_EXTENSIONS=bcmath,gd,pcntl,pdo_mysql,redis,sockets,swoole,sysvmsg,sysvsem,sysvshm,zip \
--no-cache \
--force-rm \
${root_dir}

exit 0
