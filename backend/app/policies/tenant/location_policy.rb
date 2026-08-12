class Tenant::LocationPolicy < Tenant::BasePolicy
  def index?
    owner_for_same_tenant?
  end

  def create?
    owner_for_same_tenant?
  end

  def update?
    owner_for_same_tenant?
  end

  def destroy?
    owner_for_same_tenant?
  end

  private

  def owner_for_same_tenant?
    active? && same_tenant? && actor.role == "owner"
  end
end
