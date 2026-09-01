# インフラアーキテクチャ

## この文書の位置づけ

この文書は、リポジトリに現在定義されているローカル開発環境と、ポートフォリオ公開時に予定するVercel・AWS構成を示す。
ローカル環境は`docker-compose.yml`、AWS側の現在地は`docker-compose.server.yml`、`nginx/default.conf`、`infrastructure/`配下のTerraformコードを正本とする。公開環境には未実装の構成を含むため、実装状況を注記する。

## ローカル開発環境

```mermaid
flowchart TB
    developer[開発者のブラウザ]

    subgraph local["ローカルPC上のDocker Compose"]
        source[ソースコード]

        subgraph apps["コンテナ群"]
            direction LR
            frontend["user-frontend<br/>Next.js dev<br/>3000:3000"]
            backend["backend<br/>Rails dev<br/>3001:3000"]
            db[("db<br/>PostgreSQL 16<br/>5432:5432")]
        end

        subgraph vols["Docker Volumes"]
            direction LR
            node_modules[(node_modules)]
            bundle[(bundle)]
            pgdata[(pgdata)]
        end
    end

    %% 通信関係
    developer -->|"HTTP localhost:3000"| frontend
    developer -->|"HTTP localhost:3001<br/>API / Admin / Tenant"| backend
    frontend -.->|"ブラウザから<br/>NEXT_PUBLIC_API_ORIGIN"| backend
    backend -->|"DATABASE_URL<br/>db:5432"| db

    %% マウント関係
    source ---|"bind mount"| frontend
    source ---|"bind mount"| backend
    frontend --- node_modules
    backend --- bundle
    db --- pgdata
```

- ホストの`3000`番をNext.js、`3001`番をRailsへ割り当てる。
- PostgreSQLの`5432`番もホストへ公開しており、ローカルのDBクライアントから接続できる。
- ソースコードはbind mountされるため、ローカルの変更が各開発コンテナへ反映される。
- DBデータと依存パッケージはDocker named volumeへ保持する。

## 公開環境（予定構成）

### 全体構成

```mermaid
flowchart TB
    browser[一般ユーザーのブラウザ]
    operator[Admin・Tenant利用者]
    vercel["Vercel<br/>Next.js production"]
    nginx["AWS EC2 / Nginx<br/>Railsへの入口"]
    backend["Rails<br/>JSON API / Admin / Tenant"]

    browser -->|"HTTPS<br/>一般ユーザー画面"| vercel
    browser -->|"HTTPS<br/>JSON API"| nginx
    operator -->|"HTTPS<br/>Admin / Tenant画面"| nginx
    nginx --> backend
    vercel -.->|"NEXT_PUBLIC_API_ORIGINで<br/>API接続先を設定"| nginx
```

Next.jsはVercelから配信する。現在のFrontend実装はClient ComponentからRails APIを呼ぶため、JSON API通信の主体はVercelではなくブラウザである。VercelとRailsには別のOriginを使用するため、Rails側で許可Originを限定したCORS設定が必要になる。

### AWSネットワーク

```mermaid
flowchart TB
    operator[管理者端末]
    tfstate[("S3<br/>Terraform State")]
    internet((Internet))
    igw[Internet Gateway]
    route["Route Table<br/>0.0.0.0/0 → IGW"]
    subnet["Public Subnet<br/>10.0.1.0/24<br/>ap-northeast-1a"]
    sg["Security Group<br/>HTTP 80 / HTTPS 443<br/>管理経路は接続元を限定"]
    ec2["EC2 t2.micro<br/>Amazon Linux 2<br/>Public IPv4"]

    operator -->|Terraform| tfstate
    operator -->|HTTPSまたは管理接続| internet
    internet --> igw --> route --> subnet --> sg --> ec2
```

### EC2内部

```mermaid
flowchart TB
    request["EC2ホストの80 / 443番"]

    subgraph compose["EC2上のDocker Compose"]
        repository["配置したリポジトリ<br/>backend / nginx設定"]

        subgraph apps["コンテナ群"]
            direction LR
            nginx["nginx 1.27<br/>80:80 / 443:443"]
            backend["backend<br/>Rails production<br/>expose 3000"]
            db[("db<br/>PostgreSQL 16<br/>internal 5432")]
        end

        subgraph vols["Docker Volumes"]
            direction LR
            bundle[(bundle)]
            pgdata[(pgdata)]
        end
    end

    %% 通信関係
    request -->|HTTP / HTTPS| nginx
    nginx -->|proxy_pass| backend
    backend -->|DATABASE_URL| db

    %% マウント関係
    repository ---|bind mount| backend
    repository ---|read-only mount| nginx
    backend --- bundle
    db --- pgdata
```

### 現在の境界と注意点

- 一般ユーザー向けNext.jsはVercelで稼働させ、EC2上のDocker Composeには含めない。
- TerraformはVPC、Public Subnet、Internet Gateway、Route Table、Security Group、EC2、キーペアを作成する。
- Terraform Stateは東京リージョンのS3 backendへ保存し、S3 lockfileを使用する。
- EC2にはPublic IPv4を自動割り当てする。Elastic IPはTerraformコード上で無効化されている。
- Vercelには公開してよいRails APIのOriginを`NEXT_PUBLIC_API_ORIGIN`として設定する。
- VercelのOriginとRails APIのOriginを確定し、RailsはそのOriginだけをCORSで許可する。
- Security Groupが現在許可するInboundは管理者IPからのSSH（22番）のみである。公開時にはNginx用の80番と443番を許可する。
- サーバー用Composeに現在含まれるのはNginx、Rails、PostgreSQLであり、WorkerとCertbotはまだ含まれない。
- Railsは現在`development`環境で起動し、ソースコードをbind mountする。production向けイメージおよびComposeへの移行は未実装である。
- PostgreSQLはホストへポート公開せず、Compose内部からのみ接続する。一方、データはDocker named volumeであり、専用EBSへのbind mountはまだ実装されていない。

公開までの残作業は、[ポートフォリオ公開までの実装ロードマップ](../tasks/portfolio-readiness.md)を参照する。[単一EC2での低コストデプロイ構成](single-ec2-deployment.md)は、Next.jsもEC2で稼働させる場合の比較資料として扱う。
