FROM haproxy:1.9
LABEL maintainer="Pavel Tsurbeleu <krates@appsters.io>"

ENV BACKENDS=kontena-server-api:9292 LEGO_VERSION=3.5.0 \
    BUNDLER_VERSION=2.1.4 \
    BUNDLE_JOBS=16 \
    HAPROXY_USER=haproxy

ADD Gemfile /app/
ADD Gemfile.lock /app/

RUN apt-get update -y && apt-get install -y ruby ruby-dev build-essential ca-certificates libssl-dev curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    gem install bundler --version ${BUNDLER_VERSION} && \
    cd /app ; bundle install && \
    apt-get remove -y --purge ruby-dev build-essential gcc g++ dpkg-dev make && \
    apt-get clean && \
    apt-get autoremove -y --purge

RUN groupadd --system ${HAPROXY_USER} && \
  useradd --system --gid ${HAPROXY_USER} ${HAPROXY_USER} && \
  mkdir --parents /var/lib/${HAPROXY_USER} && \
  chown -R ${HAPROXY_USER}:${HAPROXY_USER} /var/lib/${HAPROXY_USER}

RUN curl -sL -o /tmp/lego_v${LEGO_VERSION}_linux_amd64.tar.gz https://github.com/go-acme/lego/releases/download/v${LEGO_VERSION}/lego_v${LEGO_VERSION}_linux_amd64.tar.gz && \
    cd /tmp/ && tar zvxf lego_v${LEGO_VERSION}_linux_amd64.tar.gz && \
    mv /tmp/lego /usr/bin/lego && rm -f /tmp/*

ADD . /app

EXPOSE 80 443

WORKDIR /app

VOLUME /var/lib/acme

CMD ["./run.sh"]
