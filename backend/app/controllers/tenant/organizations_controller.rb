class Tenant::OrganizationsController < Tenant::BaseController
  before_action :set_organization
  before_action :authorize_update!

  def edit
  end

  def update
    if @organization.update(organization_params)
      redirect_to tenant_root_path, notice: "組織情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = current_tenant_organization
    return if @organization

    redirect_to tenant_root_path, alert: "組織情報がありません"
  end

  def authorize_update!
    return if performed?

    authorize @organization, :update?, with: Tenant::OrganizationPolicy
  end

  def organization_params
    params.require(:tenant).permit(:name, :kana)
  end
end
