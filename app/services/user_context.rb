class UserContext
  attr_reader :user, :account, :space

  def initialize(user, account = nil, space = nil)
    @user = user
    @account = account || user.account
    @space = space
  end
end
