class TenantUser < ApplicationRecord
  belongs_to :tenant
  belongs_to :account
end
