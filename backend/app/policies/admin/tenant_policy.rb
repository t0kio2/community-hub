class Admin::TenantPolicy < Admin::BasePolicy
  def index?
    active?
  end

  def show?
    active?
  end

  def create?
    active?
  end

  def update?
    active?
  end

  def destroy?
    active? && actor.role == "super_admin"
  end
end