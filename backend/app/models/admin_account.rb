class AdminAccount < Account
  self.table_name = 'accounts'

  default_scope { where(account_type: 'admin') }

  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  before_validation :set_account_type

  private

  def set_account_type
    self.account_type = 'admin'
  end
end

