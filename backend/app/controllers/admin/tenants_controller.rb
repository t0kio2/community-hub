class Admin::TenantsController < Admin::BaseController
  before_action :set_tenant, only: %i[show edit update destroy]
  before_action :authorize_tenant!
	# TODO: docs/FAQ/authorize_tenant_account?.txt を元に、どうするべきか考える。

	def index
		@tenants = Tenant
			.includes(:listings, tenant_members: :account)
			.order(id: :desc)
	end

	def new
	end

	def show
	end

	def edit
	end

	def update
	end

	def destroy
	end

	private

	def authorize_tenant!
		record = @tenant || Tenant
		query = {
			"index" => :index?,
      "show" => :show?,
      "new" => :create?,
      "create" => :create?,
      "edit" => :update?,
      "update" => :update?,
      "destroy" => :destroy?
		}.fetch(action_name)

		authorize record, query, with: Admin::TenantPolicy
	end

	def set_tenant
    @tenant = Tenant
			.includes(:listings, tenant_members: :account)
			.find(params[:id])
  end

end