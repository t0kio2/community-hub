class Admin::TenantAccountsController < Admin::BaseController
  before_action :set_tenant, only: %i[show edit update destroy]
  before_action :authorize_tenant_account!

  def index
    @tenants = TenantAccount.order(id: :desc)
  end

  def new
    @tenant = TenantAccount.new
    @organization = Tenant.new(status: "active")
  end

  def show
    @organization = @tenant.tenant_member&.tenant
    @listings = @organization&.listings&.order(updated_at: :desc, id: :desc) || Listing.none
  end

  def create
    service = TenantAccounts::CreateService.new(
      account_attributes: tenant_account_params,
      tenant_attributes: organization_params
    )
    @tenant = service.account
    @organization = service.tenant
    service.call

    redirect_to admin_tenants_path, notice: "テナントを作成しました"
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "作成に失敗しました"
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
      redirect_to admin_tenant_accounts_path, notice: "テナントアカウントを更新しました"
    else
      flash.now[:alert] = "更新に失敗しました"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @tenant.destroy
    redirect_to admin_tenant_accounts_path, notice: "テナントアカウントを削除しました"
  end

  private

  def authorize_tenant_account!
    record = @tenant || TenantAccount
    query = {
      "index" => :index?,
      "show" => :show?,
      "new" => :create?,
      "create" => :create?,
      "edit" => :update?,
      "update" => :update?,
      "destroy" => :destroy?
    }.fetch(action_name)

    authorize record, query, with: Admin::TenantAccountPolicy
  end

  def set_tenant
    @tenant = TenantAccount.find(params[:id])
  end

  def tenant_account_params
    params.require(:tenant_account).permit(:email, :password, :password_confirmation)
  end

  def organization_params
    params.require(:tenant).permit(:name, :kana)
  end
end
