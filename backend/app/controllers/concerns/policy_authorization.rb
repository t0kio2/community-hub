module PolicyAuthorization
  extend ActiveSupport::Concern

  class NotAuthorizedError < StandardError; end

  included do
    helper_method :policy
  end

  private

  def authorize(record, query, with:)
    return true if policy(record, with: with).public_send(query)

    raise NotAuthorizedError
  end

  def policy(record, with:)
    with.new(authorization_actor, record)
  end

  def authorization_actor
    raise NotImplementedError
  end
end
