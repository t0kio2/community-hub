# 概要

フロント - API - DB という構成です。

# フロント URL 設計

#### 公開領域

```
/
/about
/help
```

#### 認証領域

```
ユーザーログイン: /auth/user/login
テナントログイン: /auth/tenant/login
管理者ログイン: /auth/admin/login
ユーザー新規登録: /auth/user/sign-up
```

#### user 領域（一般利用者）

```
/app
/app/profile
/app/emergency-contacts
/app/preferences
/app/payment-methods
/app/tenants
/app/tenants/$tenantId
```

#### tenant 領域（組織運用）

```
/tenant
/tenant/dashboard
/tenant/settings
/tenant/staff
/tenant/staff/invite
/tenant/users
/tenant/users/$userId
```

#### admin 領域

```
/admin
/admin/users
/admin/users/$id
/admin/tenants
/admin/tenants/$id
/admin/audits
```

#### 整理

```
/
/auth/*
/app/*
/tenant/:tenantId/*
/admin/*
```

## ログインの流れ

```
/auth/login
  ↓
/post-login-redirect
  ↓
フロント判定
  ↓
/admin or /tenant/:id or /app
```

# API URL 設計
