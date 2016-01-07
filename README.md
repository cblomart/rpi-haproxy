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


# License

The MIT License (MIT)

Copyright (c) 2016 cblomart

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
