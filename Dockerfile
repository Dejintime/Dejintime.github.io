FROM ruby:3.2-bookworm

RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    build-essential \
    libcurl4-openssl-dev \
    libffi-dev \
    libyaml-dev \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

RUN gem install bundler -v 2.6.7 --no-document

WORKDIR /srv/jekyll

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["serve"]
