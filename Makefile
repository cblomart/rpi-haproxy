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
HAPROXY_VERSION=1.6.5
HAPROXY_MAJOR=1.6

default: build

dirs:
	mkdir -p src tmp

src/openssl-$(OPENSSL_VERSION).tar.gz: dirs
	wget ftp://ftp.openssl.org/source/openssl-$(OPENSSL_VERSION).tar.gz -P src

src/openssl-$(OPENSSL_VERSION): src/openssl-$(OPENSSL_VERSION).tar.gz
	tar -zxf src/openssl-$(OPENSSL_VERSION).tar.gz -C src


src/openssl-$(OPENSSL_VERSION)/openssl.spec: src/openssl-$(OPENSSL_VERSION)
	cd src/openssl-$(OPENSSL_VERSION) && MACHINE=armv5 ./config --prefix=../../ssl no-dso no-shared no-zlib no-krb5 no-test no-rc4 no-md2 no-md4 no-idea no-ssl2 no-ssl3 no-dso no-engines no-hw no-apps no-comp no-err no-srp -static

src/openssl-$(OPENSSL_VERSION)/libssl.a: src/openssl-$(OPENSSL_VERSION)/openssl.spec
	make -C src/openssl-$(OPENSSL_VERSION) depend
	make -C src/openssl-$(OPENSSL_VERSION) build_libs

src/haproxy-$(HAPROXY_VERSION).tar.gz: dirs
	wget http://www.haproxy.org/download/$(HAPROXY_MAJOR)/src/haproxy-$(HAPROXY_VERSION).tar.gz -P src

src/haproxy-$(HAPROXY_VERSION): src/haproxy-$(HAPROXY_VERSION).tar.gz
	tar -zxf src/haproxy-$(HAPROXY_VERSION).tar.gz -C src

src/haproxy-$(HAPROXY_VERSION)/haproxy: src/haproxy-$(HAPROXY_VERSION) src/openssl-$(OPENSSL_VERSION)/libssl.a
	make -C src/haproxy-$(HAPROXY_VERSION) TARGET=linux2628 CPU=armv5 USE_STATIC_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 ADDINC=$(PWD)/src/openssl-$(OPENSSL_VERSION)/include/
	strip --strip-all src/haproxy-$(HAPROXY_VERSION)/haproxy
	upx src/haproxy-$(HAPROXY_VERSION)/haproxy

build: src/haproxy-$(HAPROXY_VERSION)/haproxy dirs
	sudo mv src/haproxy-$(HAPROXY_VERSION)/haproxy /usr/local/bin/
	dockerize -t $(DOCKER_IMAGE_NAME) -a haproxy.cfg /etc/haproxy/ --entrypoint "/usr/local/bin/haproxy -f /etc/haproxy/haproxy.cfg" /usr/local/bin/haproxy
	cp Dockerfile tmp/
	docker build -t $(DOCKER_IMAGE_NAME) tmp
	docker tag -f $(DOCKER_IMAGE_NAME) $(DOCKER_IMAGE_NAME):latest
	docker tag -f $(DOCKER_IMAGE_NAME) $(DOCKER_IMAGE_TAGNAME)

clean:
	rm -rf src
	rm -rf tmp

deps:
	sudo apt-get install -y build-essential zlib1g-dev libpcre3-dev libssl-dev python-pip
	sudo pip install dockerize 

push:
	docker push $(DOCKER_IMAGE_NAME)

test:
	docker run --rm $(DOCKER_IMAGE_NAME) -vv	
