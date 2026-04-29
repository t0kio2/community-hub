class Admin::TenantAccountsController < Admin::BaseController
  before_action :set_tenant, only: %i[edit update destroy]

  def index
    @tenants = TenantAccount.order(id: :desc)
  end

  def new
    @tenant = TenantAccount.new
    @organization = Tenant.new(status: 'active')
  end

  def create
    @tenant = TenantAccount.new(tenant_account_params)
    @organization = Tenant.new(organization_params)

    ActiveRecord::Base.transaction do
      @tenant.save!
      @organization.save!
      TenantMember.create!(
        account: @tenant,
        tenant: @organization,
        role: 'owner',
        status: 'active'
      )
    end

    redirect_to admin_tenant_accounts_path, notice: 'テナントアカウントを作成しました'
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = '作成に失敗しました'
    render :new, status: :unprocessable_entity
  end

  def edit; end

  def update
    attrs = tenant_account_params
    if attrs[:password].blank? && attrs[:password_confirmation].blank?
      attrs.delete(:password)
      attrs.delete(:password_confirmation)
    end

    if @tenant.update(attrs)
      redirect_to admin_tenant_accounts_path, notice: 'テナントアカウントを更新しました'
    else
      flash.now[:alert] = '更新に失敗しました'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @tenant.destroy
    redirect_to admin_tenant_accounts_path, notice: 'テナントアカウントを削除しました'
  end

  private

  def set_tenant
    @tenant = TenantAccount.find(params[:id])
  end

  def tenant_account_params
    params.require(:tenant_account).permit(:email, :password, :password_confirmation)
  end

  def organization_params
    params.require(:tenant).permit(:name, :kana, :address).merge(status: 'active')
  end
end
