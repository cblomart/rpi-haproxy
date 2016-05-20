
#
# Libraries:
# this suppose that you have the necessary libraries and build system
# they can be installed via:
# $ sudo apt-get install build-essential zlib1g-dev libpcre3-dev libssl-dev
#
# Utilities:
# this uses dockerize which can be installed with
# $ sudo apt-get python-pip
# $ sudo pip install https://github.com/larsks/dockerize/archive/master.zip
#
# or you could use the deps target of the makefile
#


DOCKER_IMAGE_VERSION=0.0.2
DOCKER_IMAGE_NAME=cblomart/rpi-haproxy
DOCKER_IMAGE_TAGNAME=$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION)
OPENSSL_VERSION=1.0.2h
LIBRESSL_VERSION=2.3.4
HAPROXY_MAJOR=1.6
HAPROXY_MINOR=5
HAPROXY_VERSION=$(HAPROXY_MAJOR).$(HAPROXY_MINOR)
ZLIB_VERSION=1.2.8
PCRE_VERSION=8.38
CC=musl-gcc
CFLAGS=-march=armv6 -O3 -marm -mfpu=vfp -mfloat-abi=hard -O3

default: build

src/openssl-$(OPENSSL_VERSION)/libssl.a:
	if [ ! -e src/openssl-$(OPENSSL_VERSION).tar.gz ]; then echo "!! Downloading OpenSSL !!";  wget -q ftp://ftp.openssl.org/source/openssl-$(OPENSSL_VERSION).tar.gz -P src; fi
	if [ ! -d src/openssl-$(OPENSSL_VERSION) ]; then echo "!! Extracting OpenSSL !!"; tar -zxf src/openssl-$(OPENSSL_VERSION).tar.gz -C src; fi
	cd src/openssl-$(OPENSSL_VERSION) && CC=$(CC) MACHINE=armv6 ./config  no-camillia no-dso no-shared no-zlib no-krb5 no-test no-rc4 no-md2 no-md4 no-idea no-ssl2 no-ssl3 no-dso no-engines no-hw no-apps no-comp no-err no-srp no-asm-static $(CFLAGS)
	make -j 2 -C src/openssl-$(OPENSSL_VERSION) depend
	make -j 2 -C src/openssl-$(OPENSSL_VERSION) build_libs

src/libressl-$(LIBRESSL_VERSION)/libssl.a:
	if [ ! -e src/libressl-$(LIBRESSL_VERSION).tar.gz ]; then echo "!! Downloading LibreSSL !!"; wget http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz -P src; fi
	if [ ! -d src/libressl-$(LIBRESSL_VERSION) ]; then echo "!! Extracting FreeSSL !!"; tar -zxf src/libressl-$(LIBRESSL_VERSION).tar.gz -C src; fi
	cd src/libressl-$(LIBRESSL_VERSION) && CC=$(CC) CFLAGS="$(CFLAGS)" LDFLAGS="$(CFLAGS) -static"./configure --enable-shared=no
	cd src/libressl-$(LIBRESSL_VERSION); sed -i '/sysctl\.h/d' ./crypto/compat/getentropy_linux.c
	cd src/libressl-$(LIBRESSL_VERSION); sed -i 's!linux/types.h!sys/types.h!g' ./crypto/compat/getentropy_linux.c
	make -j 2 -C src/libressl-$(LIBRESSL_VERSION)

src/zlib-$(ZLIB_VERSION)/libz.a:
	if [ ! -e src/zlib-$(ZLIB_VERSION).tar.gz ]; then echo "!! Downloading zlib !!"; wget -q http://zlib.net/zlib-$(ZLIB_VERSION).tar.gz -P src; fi
	if [ ! -d src/zlib-$(ZLIB_VERSION) ]; then echo "!! Extracting zlib !!";  tar -zxf src/zlib-$(ZLIB_VERSION).tar.gz -C src; fi
	cd src/zlib-$(ZLIB_VERSION); CC=$(CC) CFLAGS="$(CFLAGS)"  LDFLAGS="$(CFLAGS) -static" ./configure --static
	make -j 2 -C src/zlib-$(ZLIB_VERSION)

src/pcre-$(PCRE_VERSION)/libpcre.la:
	if [ ! -e src/pcre-$(PCRE_VERSION).tar.gz ]; then echo "!! Downloading PCRE !!"; wget -q http://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$(PCRE_VERSION).tar.gz -P src; fi
	if [ ! -d src/pcre-$(PCRE_VERSION) ]; then echo "!! Extracting PCRE !!"; tar -zxf src/pcre-$(PCRE_VERSION).tar.gz -C src; fi
	cd src/pcre-$(PCRE_VERSION); CC=$(CC) CFLAGS="$(CFLAGS)"  LDFLAGS="$(CFLAGS) -static" ./configure --enable-shared=no  --enable-static=yes --disable-cpp --enable-jit  --enable-utf8
	make -j 2 -C src/pcre-$(PCRE_VERSION)

src/haproxy-$(HAPROXY_VERSION)/haproxy: src/openssl-$(OPENSSL_VERSION)/libssl.a src/zlib-$(ZLIB_VERSION)/libz.a src/pcre-$(PCRE_VERSION)/libpcre.la
	if [ ! -e src/haproxy-$(HAPROXY_VERSION).tar.gz ]; then echo "!! Downloading HAProxy !!"; wget -q http://www.haproxy.org/download/$(HAPROXY_MAJOR)/src/haproxy-$(HAPROXY_VERSION).tar.gz -P src; fi
	if [ ! -e src/haproxy-$(HAPROXY_VERSION) ]; then echo "!! Extracting HAProxy !!"; tar -zxf src/haproxy-$(HAPROXY_VERSION).tar.gz -C src; fi
	make -j 2 -C src/haproxy-$(HAPROXY_VERSION) CC=$(CC) LDFLAGS="$(CFLAGS) -static" TARGET=linux2628 CPU=armv6 USE_FUTEX= USE_TPROXY= USE_DL= USE_POLL= USE_PCRE_JIT=1 USE_LIBCRYPT= USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 SSL_INC=$(PWD)/src/openssl-$(OPENSSL_VERSION)/include/ SSL_LIB=$(PWD)/src/openssl-$(OPENSSL_VERSION)/ ZLIB_INC=$(PWD)/src/zlib-$(ZLIB_VERSION)/ ZLIB_LIB=$(PWD)/src/zlib-$(ZLIB_VERSION)/ PCRE_INC=$(PWD)/src/pcre-$(PCRE_VERSION)/ PCRE_LIB=$(PWD)/src/pcre-$(PCRE_VERSION)/.libs/ haproxy

binary: src/haproxy-$(HAPROXY_VERSION)/haproxy

build: src/haproxy-$(HAPROXY_VERSION)/haproxy
	mv src/haproxy-$(HAPROXY_VERSION)/haproxy /usr/local/bin/
	dockerize -t $(DOCKER_IMAGE_NAME) -a haproxy.cfg /etc/haproxy/ --entrypoint "/usr/local/bin/haproxy -f /etc/haproxy/haproxy.cfg" /usr/local/bin/haproxy
	mkdir -p tmp
	cp Dockerfile tmp/
	docker build -t $(DOCKER_IMAGE_NAME) tmp
	docker tag -f $(DOCKER_IMAGE_NAME) $(DOCKER_IMAGE_NAME):latest
	docker tag -f $(DOCKER_IMAGE_NAME) $(DOCKER_IMAGE_TAGNAME)

clean:
	rm -rf src
	rm -rf tmp

build-clean:
	make -C src/haproxy-$(HAPROXY_VERSION) clean
	make -C src/pcre-$(PCRE_VERSION) clean
	make -C src/zlib-$(ZLIB_VERSION) clean
	make -C src/openssl-$(OPENSSL_VERSION) clean

deps:
	sudo apt-get update
	sudo apt-get install -y build-essential  python-pip
	sudo pip install dockerize

push:
	docker push $(DOCKER_IMAGE_NAME)

test:
	docker run --rm $(DOCKER_IMAGE_NAME) -vv
