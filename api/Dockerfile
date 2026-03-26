FROM ruby:3.3-slim

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    RAILS_ENV=development

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        libyaml-dev \
        pkg-config \
        git \
        curl \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Bundler と Rails を先に入れてビルドキャッシュを効かせる
RUN gem update --system \
    && gem install bundler \
    && gem install rails -v "~> 8.0"

# エントリポイントを配置
COPY docker/entrypoint.sh /usr/bin/entrypoint
RUN chmod +x /usr/bin/entrypoint

EXPOSE 3000

CMD ["/usr/bin/entrypoint"]
