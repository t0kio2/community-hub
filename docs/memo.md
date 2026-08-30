## 本番Composeのイメージ

  services:
    nginx:
      image: nginx:1.27-alpine
      ports:
        - "80:80"
        - "443:443"
      volumes:
        - ./infrastructure/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
        - letsencrypt:/etc/letsencrypt:ro
      depends_on:
        - backend
      restart: unless-stopped

    backend:
      build:
        context: ./backend
        target: production
      env_file:
        - .env.production
      environment:
        RAILS_ENV: production
        RAILS_LOG_TO_STDOUT: "1"
      expose:
        - "3000"
      depends_on:
        db:
          condition: service_healthy
      volumes:
        - rails_storage:/app/storage
      restart: unless-stopped

    db:
      image: postgres:16
      env_file:
        - .env.production
      volumes:
        - pgdata:/var/lib/postgresql/data
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
        interval: 10s
        timeout: 5s
        retries: 5
      restart: unless-stopped

  volumes:
    pgdata:
    rails_storage:
    letsencrypt:

  重要なのは次の点です。

  - Next.jsは本番Composeに含めない
  - 外部公開するのはNginxの80/443だけ
  - Railsの3000番はDockerネットワーク内だけ
  - PostgreSQLの5432番はEC2外部に公開しない
  - PostgreSQLとRailsは同一EC2でも別コンテナにする
  - DBデータと画像データには永続ボリュームを使う
  - .env.production はGit管理しない