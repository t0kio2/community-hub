class Tenant::ListingPolicy < Tenant::BasePolicy
  def index?
    active? && same_tenant?
  end

  def show?
    active? && same_tenant?
  end

  def create?
    active? && same_tenant?
  end

  def update?
    active? && same_tenant?
  end
end
