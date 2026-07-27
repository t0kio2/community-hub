class Tenant::OrganizationPolicy < Tenant::BasePolicy
  def show?
    active? && same_tenant?
  end

  def update?
    active? && same_tenant? && actor.role == "owner"
  end
end
