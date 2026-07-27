class AdminAccounts::CreateService
  attr_reader :account, :admin

  def initialize(account_attributes:, role:)
    @account = AdminAccount.new(account_attributes)
    @admin = Admin.new(account: account, role: role, status: "active")
  end

  def call
    ActiveRecord::Base.transaction do
      account.save!
      admin.save!
    end

    self
  end
end
