FROM scratch
MAINTAINER cblomart@gmail.com
COPY ./haproxy /haproxy
COPY ./haproxy.cfg /etc/haproxy/haproxy.cfg
EXPOSE 80 443
VOLUME [ "/etc/haproxy/" ]
ENTRYPOINT [ "/haproxy", "-f", "/etc/haproxy/haproxy.cfg" ]
