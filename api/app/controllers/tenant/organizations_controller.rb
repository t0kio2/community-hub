class Tenant::OrganizationsController < Tenant::BaseController
  before_action :set_organization
  before_action :require_owner!

  def edit
  end

  def update
    if @organization.update(organization_params)
      redirect_to tenant_root_path, notice: '組織情報を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = current_tenant_organization
    return if @organization

    redirect_to tenant_root_path, alert: '組織情報がありません'
  end

  def require_owner!
    return if performed?
    return if current_tenant_user&.role == 'owner'

    redirect_to tenant_root_path, alert: '組織情報を編集する権限がありません'
  end

  def organization_params
    params.require(:tenant).permit(:name, :kana, :address)
  end
end
