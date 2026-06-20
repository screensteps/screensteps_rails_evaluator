class User
  class Destroy < ApplicationService
    def perform(user_to_destroy:)
      user_to_destroy.destroy
      user_to_destroy
    end
  end
end
