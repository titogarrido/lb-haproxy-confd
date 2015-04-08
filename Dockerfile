FROM phusion/baseimage:latest

MAINTAINER Tito Garrido <titogarrido@gmail.com>

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_PRIORITY critical
ENV DEBCONF_NOWARNINGS yes
# Workaround initramfs-tools running on kernel 'upgrade': <http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=594189>
ENV INITRD No

# Workaround initscripts trying to mess with /dev/shm: <https://bugs.launchpad.net/launchpad/+bug/974584>
# Used by our `src/ischroot` binary to behave in our custom way, to always say we are in a chroot.
#ENV FAKE_CHROOT 1
#RUN mv /usr/bin/ischroot /usr/bin/ischroot.original
#ADD build/ischroot /usr/bin/ischroot

# Configure no init scripts to run on package updates.
#ADD build/policy-rc.d /usr/sbin/policy-rc.d

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Haproxy Installation
ENV CONFD_VERSION 0.8.0

RUN add-apt-repository ppa:vbernat/haproxy-1.5
RUN apt-get update
RUN apt-get install -qqy haproxy

RUN touch /var/log/haproxy.log; \
    chown haproxy: /var/log/haproxy.log

ADD syslog-ng.conf /etc/syslog-ng/conf.d/haproxy.conf
ADD haproxy.toml /etc/confd/conf.d/haproxy.toml
ADD haproxy.tmpl /etc/confd/templates/haproxy.tmpl

WORKDIR /usr/local/bin
RUN \
    curl -s -L https://github.com/kelseyhightower/confd/releases/download/v$CONFD_VERSION/confd-$CONFD_VERSION-linux-amd64 -o confd; \
    chmod +x confd

RUN mkdir /etc/service/haproxy
ADD start.sh /etc/service/haproxy/run
RUN chmod +x /etc/service/haproxy/run

EXPOSE 80 443 1936
VOLUME ["/etc/ssl"]

CMD ["/sbin/my_init"]
# End Haproxy

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
