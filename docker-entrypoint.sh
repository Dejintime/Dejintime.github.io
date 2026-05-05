#!/bin/sh
set -e
cd /srv/jekyll

bundle config set --local path vendor/bundle
bundle install

subcmd="${1:-serve}"
shift || true

case "$subcmd" in
  serve)
    exec bundle exec jekyll serve --host 0.0.0.0 --force_polling "$@"
    ;;
  build)
    exec bundle exec jekyll build "$@"
    ;;
  *)
    exec bundle exec jekyll "$subcmd" "$@"
    ;;
esac
