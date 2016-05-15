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


DOCKER_IMAGE_VERSION=0.0.1
DOCKER_IMAGE_NAME=cblomart/rpi-haproxy
DOCKER_IMAGE_TAGNAME=$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION)
OPENSSL_VERSION=1.0.2h
HAPROXY_VERSION=1.6.5
HAPROXY_MAJOR=1.6

default: build

dirs:
	mkdir src tmp

src/openssl-$(OPENSSL_VERSION).tar.gz: dirs
	wget ftp://ftp.openssl.org/source/openssl-$(OPENSSL_VERSION).tar.gz -P src

src/openssl-$(OPENSSL_VERSION): src/openssl-$(OPENSSL_VERSION).tar.gz
	tar -zxf src/openssl-$(OPENSSL_VERSION).tar.gz -C src


src/openssl-$(OPENSSL_VERSION)/openssl.spec: src/openssl-$(OPENSSL_VERSION)
	cd src/openssl-$(OPENSSL_VERSION) && ./config --prefix=../../ssl no-shared

src/openssl-$(OPENSSL_VERSION)/libssl.a: src/openssl-$(OPENSSL_VERSION)/openssl.spec
	make -C src/openssl-$(OPENSSL_VERSION)
	make -C src/openssl-$(OPENSSL_VERSION) install_sw

src/haproxy-$(HAPROXY_VERSION).tar.gz: dirs
	wget http://www.haproxy.org/download/$(HAPROXY_MAJOR)/src/haproxy-$(HAPROXY_VERSION).tar.gz -P src

src/haproxy-$(HAPROXY_VERSION): src/haproxy-$(HAPROXY_VERSION).tar.gz
	tar -zxf src/haproxy-$(HAPROXY_VERSION).tar.gz -C src

src/haproxy-$(HAPROXY_VERSION)/haproxy: src/haproxy-$(HAPROXY_VERSION) src/openssl-$(OPENSSL_VERSION)/libssl.a
	make -C src/haproxy-$(HAPROXY_VERSION) TARGET=linux2628 CPU=native USE_STATIC_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 ADDINC=$(PWD)/src/openssl-$(OPENSSL_VERSION)/include/ ADDLIB=-L$(PWD)/src/openssl-$(OPENSSL_VERSION)/ -ldl
	strip --strip-all src/haproxy-$(HAPROXY_VERSION)/haproxy

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
