#!/usr/bin/env bash
set -euo pipefail

cd /app

# 初回: Railsアプリが無ければ作成（APIモード, PostgreSQL）
if [ ! -f "Gemfile" ]; then
  echo "[entrypoint] Creating new Rails API app..."
  rails new . \
    --api \
    --force \
    --skip-javascript \
    --skip-system-test \
    --database=postgresql \
    --skip-docker \
    --skip-ci \
    --skip-git
fi

# 依存インストール
if ! bundle check > /dev/null 2>&1; then
  echo "[entrypoint] Installing gems..."
  bundle install
fi

# DB準備（DATABASE_URL を優先使用）
echo "[entrypoint] Preparing database..."
bundle exec rails db:prepare

echo "[entrypoint] Starting Rails server..."
exec bundle exec rails s -b 0.0.0.0 -p 3000
