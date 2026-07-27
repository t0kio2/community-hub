class Tenant::BasePolicy
  attr_reader :actor, :record

  def initialize(actor, record)
    @actor = actor
    @record = record
  end

  def index?
    false
  end

  def access?
    active?
  end

  def show?
    false
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  private

  def active?
    actor&.status == "active"
  end

  def same_tenant?
    actor&.tenant_id == record_tenant_id
  end

  def record_tenant_id
    return record.id if record.is_a?(Tenant)
    return record.tenant_id if record.respond_to?(:tenant_id)

    nil
  end
end
