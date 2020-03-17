FROM ruby:2.2-slim
LABEL maintainer="Pavel Tsurbeleu <krates@appsters.io>"

ENV BACKENDS=kontena-server-api:9292 ACMETOOL_VERSION=0.0.61 \
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

RUN curl -sL -o /tmp/acmetool-v${ACMETOOL_VERSION}-linux_amd64.tar.gz https://github.com/hlandau/acme/releases/download/v${ACMETOOL_VERSION}/acmetool-v${ACMETOOL_VERSION}-linux_amd64.tar.gz && \
    cd /tmp && tar zvxf acmetool-v${ACMETOOL_VERSION}-linux_amd64.tar.gz && \
    mv /tmp/acmetool-v${ACMETOOL_VERSION}-linux_amd64/bin/acmetool /usr/bin/acmetool && \
    mkdir -p /etc/acmetool && mkdir -p /var/lib/acme/conf && \
    echo "provider: https://acme-v01.api.letsencrypt.org/directory" > /var/lib/acme/conf/target

ADD acmetool/response-file.yml /etc/acmetool/response-file.yml
ADD . /app
EXPOSE 80 443
WORKDIR /app

CMD ["./run.sh"]
