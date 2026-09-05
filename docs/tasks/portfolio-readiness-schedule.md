# ポートフォリオ公開までの8週間スケジュール

## 目標

平日に1日2〜3時間、8週間で合計80〜120時間を確保し、Community Hubをポートフォリオとして安全に公開する。

公開時の構成は次を前提とする。

- 一般ユーザー向けNext.js: Vercel
- Rails API、Admin、Tenant、Nginx、PostgreSQL: AWS EC2上のDocker Compose
- AWSリソース: Terraform

機能を増やし続けるのではなく、既存機能の完成、公開環境、セキュリティ、テスト、READMEを優先する。

## 1日の進め方

2時間の日は実装範囲を小さくし、テストと記録を省略しない。3時間取れる日は翌日の調査を前倒しする。

| 時間 | 内容 |
|---|---|
| 15分 | 前日の結果と今日の完了条件を確認 |
| 75〜105分 | 実装または設定 |
| 30〜45分 | テスト、動作確認、セキュリティ確認 |
| 15分 | commit単位の整理、taskの更新、翌日のメモ |

作業が終わらなかった場合は、翌日に無条件で積み上げない。金曜日の調整枠へ移し、公開必須でない項目を後回しにする。

## Week 1: 公開範囲と代表ユースケースを固定する

### Day 1: 公開対象を棚卸しする

- [ ] Admin、Tenant、一般ユーザーの全画面とRouteを一覧化する
- [ ] 完成、要修正、非公開の3段階に分類する
- [ ] 予約機能を初回公開へ含めるか決定する
- [ ] 公開しない未完成リンクとボタンを記録する

完了条件: 初回公開で見せる機能が一枚のチェックリストにまとまっている。

### Day 2: 代表ユースケースを手動確認する

- [ ] AdminがTenant Accountを作成する
- [ ] Tenantが施設、部屋、料金プラン、販売設定を登録する
- [ ] 一般ユーザーが施設を閲覧し、お気に入りへ追加する
- [ ] 途中で発生した不具合を優先度順に記録する

完了条件: 主導線の開始から終了までと、阻害する不具合が分かる。

### Day 3: 主導線の重大な不具合を修正する

- [ ] Day 2で見つけた公開阻害バグを上から修正する
- [ ] 正常系と主要な異常系のBackendテストを追加または更新する
- [ ] Docker Composeのtest環境でfocused testを実行する

完了条件: 代表ユースケースを止める既知の不具合が残っていない。

### Day 4: デモ用seedを設計する

- [ ] Admin、Tenant、一般ユーザーの試用アカウントを決める
- [ ] 施設、画像、部屋、料金プラン、販売設定のサンプルを決める
- [ ] 実在人物の個人情報を使用しないことを確認する
- [ ] 複数回実行可能なseedの方針を決める

完了条件: seedで生成するデータと依存順が決まっている。

### Day 5: デモ用seedを実装する

- [ ] デモデータをseedまたは専用taskとして実装する
- [ ] 空DBで実行する
- [ ] 同じDBへ再実行し、重複や例外が起きないことを確認する
- [ ] Week 1の未完了項目を調整する

完了条件: 1コマンドで代表ユースケースに必要なデータを再現できる。

## Week 2: AWS Backendをproductionで動かす

### Day 6: production要件を確定する

- [ ] Rails、Nginx、PostgreSQL、必要ならWorkerの責務を整理する
- [ ] productionで必要な環境変数を一覧化する
- [ ] bind mountを使用しない方針を確認する
- [ ] migrationと起動の順序を決める

完了条件: production用Docker構成の入力、出力、起動順が決まっている。

### Day 7: Rails production imageを作る

- [ ] production用Dockerfileを作成する
- [ ] 不要なbuild dependencyを最終imageへ残さない
- [ ] 秘密値をimageへCOPYしない
- [ ] imageをbuildし、Railsの起動を確認する

完了条件: `RAILS_ENV=production`で起動できるimageがある。

### Day 8: production用Composeを作る

- [ ] Nginx、Rails、PostgreSQLを定義する
- [ ] RailsとPostgreSQLへホスト向け`ports`を設定しない
- [ ] `restart`とhealth checkを設定する
- [ ] PostgreSQLのhealth check後にRailsを起動する

完了条件: ローカルでproduction相当のComposeが起動する。

### Day 9: NginxとRailsの経路を完成させる

- [ ] `/up`がNginx経由で成功する
- [ ] JSON API、Admin、TenantのRouteを確認する
- [ ] `Host`、`X-Forwarded-*`ヘッダーを確認する
- [ ] RailsとPostgreSQLへホストから直接接続できないことを確認する

完了条件: Nginxだけを入口として主要Routeへ到達できる。

### Day 10: migrationと再起動を検証する

- [ ] 空のproduction相当DBを準備する
- [ ] migrationまたは`db:prepare`を実行する
- [ ] ComposeとEC2相当ホストの再起動を模擬する
- [ ] DBデータとアプリが復旧することを確認する
- [ ] Week 2の未完了項目を調整する

完了条件: 再起動可能なBackend用Composeが完成している。

## Week 3: AWSインフラとHTTPSを完成させる

### Day 11: Terraformの現状差分を整理する

- [ ] Terraformの`fmt`と`validate`を実行する
- [ ] Security Group、EC2、Public IP、EBSの実装状況を確認する
- [ ] 設計文書とTerraformコードの差分を記録する
- [ ] AWS料金通知が設定済みか確認する

完了条件: 公開に必要なTerraform変更が確定している。

### Day 12: Security Groupと管理経路を実装する

- [ ] HTTP 80とHTTPS 443を許可する
- [ ] SSHを残す場合は管理者IPだけに限定する
- [ ] Session Managerへ移行できる場合は22番を閉じる
- [ ] 不要なInboundがないことをplanで確認する

完了条件: 公開Portと管理Portが必要最小限になっている。

### Day 13: PostgreSQL永続領域を実装する

- [ ] 専用EBSまたは採用する永続化方式をTerraformへ反映する
- [ ] PostgreSQLのmount先と権限を設定する
- [ ] 誤って初期化し直さない仕組みを確認する
- [ ] destroy時にデータを残すか削除するか明記する

完了条件: コンテナやEC2の再作成方針とDBデータの扱いが明確になっている。

### Day 14: AWSへBackendをデプロイする

- [ ] EC2へ対象commitを配置する
- [ ] 秘密値を権限の制限された方法で設定する
- [ ] DB準備、migration、Compose起動を順に実行する
- [ ] Public IP経由でhealth checkを確認する

完了条件: AWS上でRails Backendへ一時的に疎通できる。

### Day 15: ドメインとHTTPSを設定する

- [ ] Rails API用ドメインまたはサブドメインを設定する
- [ ] TLS証明書を取得する
- [ ] HTTPからHTTPSへリダイレクトする
- [ ] 証明書更新方法を設定する
- [ ] Week 3の未完了項目を調整する

完了条件: Rails API、Admin、TenantへHTTPSで接続できる。

## Week 4: VercelとRails APIを接続する

### Day 16: Vercel projectを設定する

- [ ] `user-frontend`をRoot Directoryとして設定する
- [ ] Next.js production buildを成功させる
- [ ] ProductionとPreviewの環境を区別する
- [ ] `NEXT_PUBLIC_API_ORIGIN`へRails APIのHTTPS Originを設定する

完了条件: Vercelから一般ユーザー画面を表示できる。

### Day 17: CORSを実装する

- [ ] RailsでVercelのProduction Originだけを許可する
- [ ] 許可するHeaderとHTTP methodを必要最小限にする
- [ ] 許可Originと不許可OriginのControllerテストを追加する
- [ ] Preview deploymentを許可するか決定する

完了条件: VercelからAPIを呼べて、未知のOriginは拒否される。

### Day 18: 認証Cookieのドメイン設計を確定する

- [ ] FrontendとAPIの最終ドメインを確定する
- [ ] Refresh TokenのDomain、Path、SameSite、Secure、HttpOnlyを決める
- [ ] Fetchの`credentials`とRailsのCORS credentials設定を決める
- [ ] CSRF対策を決める
- [ ] [認証トークン保存方式](auth-token-storage.md)へ決定を反映する

完了条件: Vercel・Rails間の認証方式をコードへ落とせる状態になっている。

### Day 19: Refresh TokenをHttpOnly Cookieへ移行する

- [ ] LoginとSign upでRefresh Token Cookieを発行する
- [ ] Response bodyからRefresh Tokenを除外する
- [ ] Cookie属性をproductionとdevelopmentで適切に切り替える
- [ ] Backendの正常系テストを追加する

完了条件: JavaScriptからRefresh Tokenを読み取れない。

### Day 20: Frontendの認証処理を更新する

- [ ] Refresh Tokenの`localStorage`利用を削除する
- [ ] RefreshとLogoutへ`credentials`を設定する
- [ ] Login、reload、refresh、logoutをVercel上で確認する
- [ ] Week 4の未完了項目を調整する

完了条件: Vercel上で認証ライフサイクルが一通り動く。

## Week 5: 認証とTenant境界を固める

### Day 21: Token異常系を実装・テストする

- [ ] Access Token期限切れからRefreshできる
- [ ] 期限切れ、失効済み、再利用されたRefresh Tokenを拒否する
- [ ] Logout後にRefreshできない
- [ ] Cookie削除とサーバー側失効が一致する

完了条件: 認証の主要な失敗経路がBackendテストで保護されている。

### Day 22: CSRFとCORSを結合確認する

- [ ] 許可Originからの認証Requestが成功する
- [ ] 不許可Originからのcredential付きRequestを拒否する
- [ ] CSRF Tokenが必要な操作を確認する
- [ ] Production Cookieをブラウザの開発者ツールで確認する

完了条件: Cross-Origin認証の防御条件を説明できる。

### Day 23: Tenant境界を棚卸しする

- [ ] Tenant配下のControllerとPolicyを一覧化する
- [ ] IDを直接変更した場合の挙動を確認する
- [ ] 他TenantのLocation、Listing、Room Type、Roomを関連付けられないことを確認する
- [ ] 足りないBackendテストを列挙する

完了条件: Tenant境界の未検証箇所が明確になっている。

### Day 24: Tenant境界の不足を修正する

- [ ] 優先度の高い認可漏れを修正する
- [ ] ControllerまたはPolicyテストを追加する
- [ ] 正常系と他Tenant拒否の両方を確認する
- [ ] 全Backendテストを実行する

完了条件: 主導線上で他Tenantのデータを参照・更新できない。

### Day 25: セキュリティ静的解析を通す

- [ ] Brakemanを実行する
- [ ] bundler-auditを実行する
- [ ] 重大な警告を修正または理由つきで記録する
- [ ] productionで詳細な例外を表示しないことを確認する
- [ ] Week 5の未完了項目を調整する

完了条件: 公開を止める重大なセキュリティ警告がない。

## Week 6: CIとFrontendテストを整える

### Day 26: Backend CIを追加する

- [ ] GitHub ActionsでPostgreSQLを起動する
- [ ] Rails test DBを準備する
- [ ] Rails全テストを実行する
- [ ] RuboCopを実行する

完了条件: Pull RequestでBackend testとlintの結果を確認できる。

### Day 27: セキュリティ・Terraform CIを追加する

- [ ] Brakemanとbundler-auditをCIで実行する
- [ ] Terraform `fmt -check`を実行する
- [ ] Terraform `validate`を実行する
- [ ] CIへAWSの長期Access Keyを登録しない

完了条件: セキュリティとTerraformの基本チェックが自動化されている。

### Day 28: Frontend CIを追加する

- [ ] ESLintを実行する
- [ ] TypeScriptの型チェック用commandを用意する
- [ ] Next.js production buildを実行する
- [ ] Vercelのdeployment checkとGitHub Actionsの役割を整理する

完了条件: Frontendのlint、型、buildがPull Requestで確認できる。

### Day 29: Frontendテスト基盤を追加する

- [ ] Repositoryに合うtest runnerとDOM test環境を選ぶ
- [ ] API呼び出しを差し替えられるtest helperを用意する
- [ ] Loginの成功と失敗をテストする
- [ ] テスト名と説明コメントを日本語で記述する

完了条件: Frontend testをローカルとCIで実行できる。

### Day 30: 主要Frontendテストを追加する

- [ ] Logoutをテストする
- [ ] 施設一覧の取得成功と失敗をテストする
- [ ] お気に入りの追加と削除をテストする
- [ ] Week 6の未完了項目を調整する

完了条件: 一般ユーザーの主要操作がFrontend testで保護されている。

## Week 7: E2E、バックアップ、監視を整える

### Day 31: E2Eテスト基盤を追加する

- [ ] Playwrightなどを導入する
- [ ] E2E用データの準備と後片付け方法を決める
- [ ] Loginして施設一覧を表示する最小テストを作る
- [ ] 秘密値をテスト出力へ残さない

完了条件: ローカルでE2Eテストが1本成功する。

### Day 32: 代表ユースケースをE2Eで保護する

- [ ] 一般ユーザーの会員登録またはLoginを通す
- [ ] 施設を閲覧する
- [ ] お気に入りへ追加・削除する
- [ ] CIまたは公開前手動checkで安定して実行できるようにする

完了条件: 公開デモの代表操作を自動または再現可能な手順で確認できる。

### Day 33: DBバックアップを実装する

- [ ] `pg_dump`をEC2外へ保存する
- [ ] 保持期間と実行頻度を決める
- [ ] Backupに秘密値を混入させない
- [ ] Backup失敗を検知できるようにする

完了条件: 定期実行可能なDB Backupがある。

### Day 34: DB復元を試験する

- [ ] 最新Backupを一時DBへ復元する
- [ ] 件数または代表データを確認する
- [ ] Restore手順と所要時間を記録する
- [ ] 本番DBを誤って上書きしない手順にする

完了条件: Backupが実際に復元可能であることを確認済みである。

### Day 35: ログと監視を設定する

- [ ] RailsとNginxのログをAWS側で確認する
- [ ] Vercelのbuild・runtimeログを確認する
- [ ] `/up`を外形監視する
- [ ] EC2のCPU、ディスク、Status Checkと料金通知を設定する
- [ ] Week 7の未完了項目を調整する

完了条件: 障害と過剰課金に気づける最低限の監視がある。

## Week 8: README、デモ、公開判定

### Day 36: READMEの構成を書き直す

- [ ] 冒頭にサービス概要、課題、想定ユーザーを書く
- [ ] 主要機能と3つのロールを説明する
- [ ] デモURLと試用アカウントの欄を作る
- [ ] セットアップ詳細とトラブルシューティングを後半または別文書へ移す

完了条件: README冒頭だけで何を作ったか理解できる。

### Day 37: 技術と設計判断を説明する

- [ ] 技術スタックと採用理由を書く
- [ ] ER図とインフラアーキテクチャへリンクする
- [ ] Tenant境界、認証、料金・在庫設計から3点を説明する
- [ ] テストが何を保証するか説明する
- [ ] CI badgeを追加する

完了条件: コードを読まなくても技術的な工夫が伝わる。

### Day 38: 画面素材とデモ案内を作る

- [ ] 個人情報や秘密値が映っていないスクリーンショットを撮る
- [ ] Admin、Tenant、一般ユーザーの代表画面を掲載する
- [ ] 必要なら短い操作GIFを作る
- [ ] 各試用アカウントで試せる操作と禁止操作を記載する

完了条件: READMEからデモ操作へ迷わず進める。

### Day 39: 公開前の通し確認を行う

- [ ] 新しいブラウザSessionでREADMEの手順どおり操作する
- [ ] Vercel、Rails API、Admin、Tenant、画像、認証を確認する
- [ ] CIをすべて成功させる
- [ ] EC2再起動後の復旧を確認する
- [ ] 秘密値、個人情報、不要なDebug表示を最終検索する

完了条件: 公開を止める問題が0件になっている。

### Day 40: Bufferと公開

- [ ] Day 39で見つけた問題を修正する
- [ ] 公開版のGit tagまたはcommit SHAを記録する
- [ ] デプロイとRollback手順を最終確認する
- [ ] READMEのデモURLを開いて最終確認する
- [ ] 今後の課題を公開必須項目と混ぜずに記録する

完了条件: ポートフォリオURLを第三者へ共有できる。

## 公開判定

次をすべて満たすまでDay 40を完了扱いにしない。

- [ ] READMEからサービスの目的、対象ユーザー、主要機能が分かる
- [ ] VercelのデモURLをHTTPSで開ける
- [ ] VercelからRails APIへ安全に接続できる
- [ ] Admin、Tenant、一般ユーザーの試用アカウントで主導線を完了できる
- [ ] 他Tenantのデータへアクセスできない
- [ ] Refresh Tokenが`localStorage`へ保存されていない
- [ ] 秘密値と個人情報がGit、画面、ログへ露出していない
- [ ] 必須CIがすべて成功している
- [ ] EC2再起動後もアプリとDBが復旧する
- [ ] DB Backupから復元できる
- [ ] デモ環境の制約と未実装項目を説明できる
- [ ] 主要な設計判断を自分の言葉で説明できる

## 遅れた場合に削ってよい項目

次は初回公開後へ回してよい。

- 宿泊予約の新規実装
- Workerを使う新しい非同期処理
- OpenAPI文書
- 高度なperformance改善
- E2Eテストの複数Browser対応
- スクリーンショット以外の紹介動画

削ってはいけない項目は、HTTPS、Tenant境界、認証Tokenの安全性、CI、DB永続化、Backup、代表ユースケース、READMEである。
