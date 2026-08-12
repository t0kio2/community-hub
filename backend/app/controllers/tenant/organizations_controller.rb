class Tenant::OrganizationsController < Tenant::BaseController
  before_action :require_current_tenant!
  before_action :authorize_update!
  before_action :set_locations

  def edit
  end

  def update
    if @tenant.update(organization_params)
      redirect_to tenant_root_path, notice: "組織情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def authorize_update!
    return if performed?

    authorize @tenant, :update?, with: Tenant::OrganizationPolicy
  end

  def set_locations
    return if performed?

    @locations = @tenant.tenant_locations.order(:name, :id)
  end

  def organization_params
    params.require(:tenant).permit(:name, :kana)
  end
end
