# Tenant Account / Tenant / Tenant User 作成設計

## 背景

現状、tenant のセルフサインアップ画面はない。

- フロントには `/auth/tenant/login` はあるが、`/auth/tenant/sign-up` はない
- Rails 側の `TenantAccount` は Devise の `:registerable` を持っていない
- tenant アカウントは admin 画面から作成する想定
- 既存の `/admin/tenant_accounts/new` は `accounts` の tenant account だけを作っている

しかし `tenant_members` は `accounts` と `tenants` を紐づけるテーブルなので、tenant account だけ作っても「このログインユーザーがどの tenant に所属するか」が分からない。

そのため、admin が最初の tenant account を作成するときに、tenant の組織情報も同時に入力し、以下 3 レコードを同一トランザクションで作成する。

1. `accounts`
2. `tenants`
3. `tenant_members`

## 用語整理

### accounts

ログイン認証用の共通アカウント。

tenant 用アカウントは `TenantAccount < Account` として扱い、`account_type` は `tenant` にする。

### tenants

テナント組織そのもの。

例:

- 事業者
- 店舗運営会社
- 宿泊施設運営会社

`tenants` はログイン情報を持たない。組織情報だけを持つ。

### tenant_members

tenant 組織に所属するログインユーザーを表す。

`tenant_members.account_id` で `accounts` に紐づき、`tenant_members.tenant_id` で `tenants` に紐づく。

つまり「この account は、この tenant のメンバーである」を表すテーブル。

## role 方針

`tenant_members.role` は初期から使う。

ただし、最初の実装では owner/staff による細かい権限制御は入れない。

### role 値

- `owner`
- `staff`

### 作成ルール

admin が `/admin/tenant_accounts/new` から作成する最初の tenant user は `owner` にする。

```ruby
TenantUser.create!(
  tenant: tenant,
  account: tenant_account,
  role: 'owner',
  status: 'active'
)
```

将来、owner が tenant 管理画面から追加する tenant user は `staff` にする。

```ruby
TenantUser.create!(
  tenant: current_tenant,
  account: tenant_account,
  role: 'staff',
  status: 'active'
)
```

### 初期の権限制御

初期実装では owner/staff の権限差は作らない。

ただし、将来以下のような制御を入れられるように、role は必ず保存しておく。

- 組織情報編集は owner のみ
- メンバー追加/削除は owner のみ
- 請求関連は owner のみ

## 実装する内容

### 1. admin tenant 作成画面に組織情報入力 UI を追加する

対象:

- `backend/app/views/admin/tenant_accounts/new.html.erb`

現在は tenant account 情報だけを入力している。

以下の 2 セクションに分ける。

#### アカウント情報

- email
- password
- password_confirmation

#### 組織情報

- name
- kana
- address
- status

`status` は初期値 `active` でよい。

UI 上で `status` を入力させるかどうかは任意。
最初は hidden field または controller 側で `active` 固定でもよい。

### 2. Admin::TenantAccountsController#create を修正する

対象:

- `backend/app/controllers/admin/tenant_accounts_controller.rb`

現在:

```ruby
@tenant = TenantAccount.new(tenant_params)
if @tenant.save
  redirect_to admin_tenant_accounts_path, notice: 'テナントアカウントを作成しました'
else
  ...
end
```

修正後は、同一トランザクションで以下を作る。

1. `TenantAccount`
2. `Tenant`
3. `TenantUser`

実装イメージ:

```ruby
def create
  @tenant_account = TenantAccount.new(tenant_account_params)
  @tenant = Tenant.new(tenant_params)

  ActiveRecord::Base.transaction do
    @tenant_account.save!
    @tenant.save!
    TenantUser.create!(
      account: @tenant_account,
      tenant: @tenant,
      role: 'owner',
      status: 'active'
    )
  end

  redirect_to admin_tenant_accounts_path, notice: 'テナントアカウントを作成しました'
rescue ActiveRecord::RecordInvalid
  flash.now[:alert] = '作成に失敗しました'
  render :new, status: :unprocessable_entity
end
```

注意:

- view で使っているインスタンス変数名と controller を揃える
- 既存 view が `@tenant` を `TenantAccount` として使っているなら、混乱を避けるために `@tenant_account` と `@tenant` に分ける
- バリデーションエラー表示も `@tenant_account.errors` と `@tenant.errors` の両方を表示できるようにする

### 3. strong parameters を分ける

対象:

- `backend/app/controllers/admin/tenant_accounts_controller.rb`

例:

```ruby
def tenant_account_params
  params.require(:tenant_account).permit(:email, :password, :password_confirmation)
end

def tenant_params
  params.require(:tenant).permit(:name, :kana, :address, :status)
end
```

`status` を画面入力させない場合:

```ruby
def tenant_params
  params.require(:tenant).permit(:name, :kana, :address).merge(status: 'active')
end
```

### 4. モデルに最低限の validation を追加する

対象候補:

- `backend/app/models/tenant.rb`
- `backend/app/models/tenant_user.rb`

最低限:

```ruby
class Tenant < ApplicationRecord
  has_many :tenant_members, dependent: :destroy

  validates :name, presence: true
  validates :status, presence: true
end
```

```ruby
class TenantUser < ApplicationRecord
  belongs_to :tenant
  belongs_to :account

  validates :role, presence: true, inclusion: { in: %w[owner staff] }
  validates :status, presence: true
end
```

必要なら status も値を制限する。

```ruby
validates :status, inclusion: { in: %w[active inactive] }
```

### 5. docs の account_type 表記を修正する

対象:

- `backend/docs/DB/ER.md`

現在、`accounts.account_type` の説明が以下になっている。

```text
['user' | 'tenant_user' | 'admin']
```

実装では `Account` の validation が `%w[user tenant admin]` で、`TenantAccount` も `account_type = 'tenant'` をセットしている。

docs を以下に直す。

```text
['user' | 'tenant' | 'admin']
```

## データ作成後の期待状態

admin が tenant を作成した後、DB は以下の状態になる。

### accounts

```text
id: 10
email: tenant-owner@example.com
account_type: tenant
```

### tenants

```text
id: 3
name: サンプル旅館
kana: サンプルリョカン
address: 東京都...
status: active
```

### tenant_members

```text
id: 7
tenant_id: 3
account_id: 10
role: owner
status: active
```

この状態で、tenant login 後に `current_tenant_account.tenant_user.tenant` を辿れる。

## 将来実装する内容

### owner による staff 追加

tenant 側管理画面から、owner が staff を追加できるようにする。

このとき作るもの:

1. `TenantAccount`
2. `TenantUser`

既存 tenant に所属させるので、`Tenant` は新規作成しない。

```ruby
TenantUser.create!(
  tenant: current_tenant,
  account: tenant_account,
  role: 'staff',
  status: 'active'
)
```

### owner/staff の権限制御

初期実装では分けない。

後で必要になったら以下から始める。

- tenant 組織情報編集: owner のみ
- tenant メンバー管理: owner のみ
- 通常業務画面: owner/staff 両方許可

## テスト観点

### controller / request spec

admin が tenant account 作成フォームを送信したとき:

- `TenantAccount` が 1 件増える
- `Tenant` が 1 件増える
- `TenantUser` が 1 件増える
- `TenantUser.role` が `owner`
- `TenantUser.status` が `active`
- `TenantUser.account` が作成した `TenantAccount`
- `TenantUser.tenant` が作成した `Tenant`

バリデーションエラー時:

- どれか 1 つでも失敗したら全体が rollback される
- `accounts` だけ作られる状態にならない
- `tenants` だけ作られる状態にならない

### model test

`TenantUser`:

- `role` は `owner` / `staff` のみ有効
- `role` 空は無効
- `status` 空は無効

`Tenant`:

- `name` 空は無効
- `status` 空は無効

## 実装時の注意

- `tenant_members.account_id` には unique index があるため、1 account は 1 tenant にだけ所属できる
- 既存 controller の `@tenant` は実際には `TenantAccount` を指しているので、名前を整理した方がよい
- admin の tenant 一覧が `TenantAccount` 一覧なのか、`Tenant` 一覧なのかは後で整理が必要
- まずは既存画面の責務に合わせて「admin が tenant owner account と tenant 組織を同時作成する」実装を優先する
