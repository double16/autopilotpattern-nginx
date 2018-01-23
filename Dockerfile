# A minimal Nginx container including ContainerPilot
FROM debian:stretch-slim
MAINTAINER Patrick Double <pat@patdouble.com>

ENV NGINX_VERSION 1.10.3-1+deb9u1

RUN echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        nginx-extras=${NGINX_VERSION} gettext-base \
        bc \
        ca-certificates \
        curl \
        unzip \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/lib/lua && curl --fail -s -o /usr/local/lib/lua/prometheus.lua https://raw.githubusercontent.com/knyar/nginx-lua-prometheus/24ab338427bcfd121ac6c9a264a93d482e115e14/prometheus.lua

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

STOPSIGNAL SIGQUIT

# Install Consul
# Releases at https://releases.hashicorp.com/consul
RUN export CONSUL_VERSION=1.0.2 \
    && export CONSUL_CHECKSUM=418329f0f4fc3f18ef08674537b576e57df3f3026f258794b4b4b611beae6c9b \
    && curl --retry 7 --fail -vo /tmp/consul.zip "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_CHECKSUM}  /tmp/consul.zip" | sha256sum -c \
    && unzip /tmp/consul -d /usr/local/bin \
    && rm /tmp/consul.zip \
    && mkdir /config

# Create empty directories for Consul config and data
RUN mkdir -p /etc/consul \
    && mkdir -p /var/lib/consul

# Install Consul template
# Releases at https://releases.hashicorp.com/consul-template/
RUN export CONSUL_TEMPLATE_VERSION=0.18.3 \
    && export CONSUL_TEMPLATE_CHECKSUM=caf6018d7489d97d6cc2a1ac5f1cbd574c6db4cd61ed04b22b8db7b4bde64542 \
    && curl --retry 7 --fail -Lso /tmp/consul-template.zip "https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_TEMPLATE_CHECKSUM}  /tmp/consul-template.zip" | sha256sum -c \
    && unzip /tmp/consul-template.zip -d /usr/local/bin \
    && rm /tmp/consul-template.zip

# Add Containerpilot and set its configuration
ENV CONTAINERPILOT_VER="3.6.1" \
    CONTAINERPILOT="/etc/containerpilot.json5"

RUN export CONTAINERPILOT_CHECKSUM=57857530356708e9e8672d133b3126511fb785ab \
    && curl -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VER}/containerpilot-${CONTAINERPILOT_VER}.tar.gz" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /usr/local/bin \
    && rm /tmp/containerpilot.tar.gz

# Add node_exporter for system level Prometheus metrics
RUN curl --fail -sL https://github.com/prometheus/node_exporter/releases/download/v0.14.0/node_exporter-0.14.0.linux-amd64.tar.gz |\
    tar -xzO -f - node_exporter-0.14.0.linux-amd64/node_exporter > /usr/local/bin/node_exporter &&\
    chmod +x /usr/local/bin/node_exporter

# Add Dehydrated
RUN export DEHYDRATED_VERSION=v0.3.1 \
    && curl --retry 8 --fail -Lso /tmp/dehydrated.tar.gz "https://github.com/lukas2511/dehydrated/archive/${DEHYDRATED_VERSION}.tar.gz" \
    && tar xzf /tmp/dehydrated.tar.gz -C /tmp \
    && mv /tmp/dehydrated-0.3.1/dehydrated /usr/local/bin \
    && rm -rf /tmp/dehydrated-0.3.1

# Add jq
RUN export JQ_VERSION=1.5 \
    && curl --retry 8 --fail -Lso /usr/local/bin/jq "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64" \
    && chmod a+x /usr/local/bin/jq

# Add our configuration files and scripts
RUN rm -f /etc/nginx/conf.d/default.conf
COPY etc/acme /etc/acme
COPY etc/containerpilot.json5 /etc/
COPY etc/nginx /etc/nginx/templates
COPY etc/consul /etc/consul
COPY bin /usr/local/bin

# Usable SSL certs written here
RUN mkdir -p /var/www/ssl
# Temporary/work space for keys
RUN mkdir -p /var/www/acme/ssl
# ACME challenge tokens written here
RUN mkdir -p /var/www/acme/challenge

CMD [ "/usr/local/bin/containerpilot"]

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.license="MPL-2.0" \
      org.label-schema.name="Autopilot Pattern Nginx with Extras and Full Prometheus Monitoring" \
      org.label-schema.url="https://github.com/double16/autopilotpattern-nginx" \
      org.label-schema.docker.dockerfile="Dockerfile" \
      org.label-schema.vcs-ref=$SOURCE_REF \
      org.label-schema.vcs-type='git' \
      org.label-schema.vcs-url="https://github.com/double16/autopilotpattern-nginx.git"
