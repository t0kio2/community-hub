# CommunityHub の ER 図

```mermaid
erDiagram
  users {
    int id PK
    text email　"UNIQUE, NOT NULL"
    text role "'user' | 'tenant' | 'admin'"
    text status "'active' | 'suspended'"
  }

  tenant_users {
    int tenant_id PK, FK "UNIQUE (tenant_id, user_id)"
    int user_id PK, FK "UNIQUE (tenant_id, user_id)"
    %% UNIQUE (tenant_id, user_id)
    text tenant_role "'owner' | 'staff'"
  }

  tenants {
    int id PK
    text name
    text address
    text contact_info
  }

  %% Relationships
  users ||--o{ tenant_users : has
  tenants ||--o{ tenant_users : has

  emergency_contacts {
    int id PK
    int user_id FK
    text name
    text relation
    text tel
    int priority
  }

  %% 1対多
  users ||--o{ emergency_contacts : has

  user_profiles {
    int user_id PK, FK
    text name
    text tel
    text address
    text education
    text work_history
    text notes
  }

  users ||--|| user_profiles : has

  user_preferences {
    int user_id PK, FK
    text contact_method
  }

  users ||--|| user_preferences : has

  payment_methods {
    int id PK
    int user_id FK
    text tenant
    text method_type
    text external_id
    text status
    text brand
    text last4
    int exp_month
    int exp_year
    text billing_name
    jsonb billing_address
    boolean is_default
    timestamptz created_at
    timestamptz updated_at
  }

  users ||--o{ payment_methods : has

```
