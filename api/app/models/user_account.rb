class UserAccount < Account
  self.table_name = 'accounts'

  default_scope { where(account_type: 'user') }

  devise :database_authenticatable, :registerable,
         :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  before_validation :set_account_type

  private

  def set_account_type
    self.account_type = 'user'
  end
end

