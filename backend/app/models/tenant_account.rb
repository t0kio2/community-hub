class TenantAccount < Account
  self.table_name = 'accounts'

  default_scope { where(account_type: 'tenant') }

  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  before_validation :set_account_type

  private

  def set_account_type
    self.account_type = 'tenant'
  end
end

