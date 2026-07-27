class TenantAccounts::CreateService
  attr_reader :account, :tenant, :member

  def initialize(account_attributes:, tenant_attributes:)
    @account = TenantAccount.new(account_attributes)
    @tenant = Tenant.new(tenant_attributes.merge(status: "active"))
  end

  def call
    ActiveRecord::Base.transaction do
      account.save!
      tenant.save!
      @member = TenantMember.create!(
        account: account,
        tenant: tenant,
        role: "owner",
        status: "active"
      )
    end

    self
  end
end
