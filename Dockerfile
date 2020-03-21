FROM ruby:2.2-slim
LABEL maintainer="Pavel Tsurbeleu <krates@appsters.io>"

ENV BACKENDS=kontena-server-api:9292 LEGO_VERSION=3.5.0 \
    BUNDLER_VERSION=1.17.3 \
    BUNDLE_JOBS=16

ADD Gemfile /app/
ADD Gemfile.lock /app/

RUN apt-get update -y && apt-get install -y haproxy build-essential ca-certificates libssl-dev curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    gem install bundler --version ${BUNDLER_VERSION} && \
    cd /app ; bundle install && \
    apt-get remove -y --purge build-essential gcc g++ dpkg-dev make && \
    apt-get clean && \
    apt-get autoremove -y --purge

RUN curl -sL -o /tmp/lego_v${LEGO_VERSION}_linux_amd64.tar.gz https://github.com/go-acme/lego/releases/download/v${LEGO_VERSION}/lego_v${LEGO_VERSION}_linux_amd64.tar.gz && \
    cd /tmp/ && tar zvxf lego_v${LEGO_VERSION}_linux_amd64.tar.gz && \
    mv /tmp/lego /usr/bin/lego && rm -f /tmp/*

ADD acmetool/response-file.yml /etc/acmetool/response-file.yml
ADD . /app
EXPOSE 80 443
WORKDIR /app

CMD ["./run.sh"]
