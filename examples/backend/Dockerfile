FROM pdouble16/autopilotpattern-base:1.3.0
FROM mhart/alpine-node:latest

RUN mkdir -p /var/lib/consul /etc/consul
COPY --from=0 /usr/local/bin/* /usr/local/bin/
COPY --from=0 /etc/consul/* /etc/consul/

RUN apk add --no-cache curl bash

# COPY ContainerPilot configuration
ENV CONTAINERPILOT=/etc/containerpilot.json5
COPY containerpilot.json5 ${CONTAINERPILOT}


# Install our application
COPY index.js /opt/hello/

EXPOSE 3001
CMD ["/usr/local/bin/containerpilot"]
