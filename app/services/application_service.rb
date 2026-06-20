class ApplicationService
  attr_reader :user, :account, :space, :audit_context, :event_uuid, :user_context

  # Supported options:
  #   :account
  #   :user
  #   :space
  #   :user_context
  #   :audit_context (defaults to ApplicationEvent::CONTEXT_WEB)
  #   :event_uuid (defaults to a randomly-generated one)
  # At the very least, either :account or :user_context must be provided.
  def initialize(options)
    @user_context = options[:user_context]
    @account = options[:account] || @user_context&.account
    raise ArgumentError, 'no account provided' if @account.nil?

    @user = options[:user] || @user_context&.user
    @space = options[:space] || @user_context&.space
    @user_context ||= UserContext.new(user, account, space)
    @audit_context = options[:audit_context] || ApplicationEvent::CONTEXT_WEB
    @event_uuid = options[:event_uuid].presence || SecureRandom.uuid
  end

  # When calling perform, you should at minimum pass the +account+ or +user_context+ argument.
  # +user:+ and +space:+ are also always accepted, although may not be appropriate for the action
  # at hand.
  # Deriving service actions will usually have one or more additional keyword arguments specific
  # to it's behavior. See the +perform+ method in the derived class for details on those arguments.
  def self.perform(**options)
    extracted_keys = %i[account user space user_context audit_context event_uuid]
    constructor_attributes = options.extract!(*extracted_keys)
    if constructor_attributes[:account].nil? && constructor_attributes[:user_context].nil?
      raise ArgumentError, 'Must provide an account or user_context'
    end

    new(constructor_attributes).perform(**options)
  end

  protected

  # A hash of all of the relevant context information for this service.
  # Useful for passing along to services called from other services.
  def service_context
    { account: account, user: user, space: space, audit_context: audit_context, event_uuid: event_uuid }
  end
end
