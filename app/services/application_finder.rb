class ApplicationFinder
  attr_reader :user, :account, :space, :user_context

  def initialize(user_context)
    @user_context = user_context
    @account = user_context.account
    @user = user_context.user
    @space = user_context.space
  end
end
