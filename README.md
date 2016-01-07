# rpi-haproxy

This image is build form a (mostly) staticaly compiled haproxy via dockerize. Thus reducing the size of the image to 4MB.

Many thanks to hypriots for its work and posts... it obviously inspired most of this work.

**Compose**

Simply use "make"...But

To be able to compile haproxy staticaly a few dependencies must be met. So you can first:

> make deps

An then you can build the image
This will download haproxy and openssl and compile them... If you run on a Pi1 take a city trip and comme back afterwards...
The haproxy binary will be installed in /usr/local/bin.

> make

Test the image

> make test

And push it to the docker hub

> make push

The erase the sources and builds

> make clean

**Usage**

> docker run -d -p 80:80 cblomart/rpi-haproxy

**Customizing Haproxy**

> docker run -d -p 80:80 -v \<dir\>:/etc/haproxy cblomart/rpi-haproxy

where \<dir\> is an absolute path of a directory that could contain:

You can get the default haproxy.cfg from a container:

> docker cp \<container\>:/etc/haproxy/haproxy.cfg haproxy.cfg

Logging is sent to 127.0.0.1 to avoid error accessing /dev/log socket device.
