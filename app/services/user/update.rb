class User
  class Update < ApplicationService
    def perform(user_to_update:, params:)
      user_to_update.assign_attributes(params)
      user_to_update.email = nil if user_to_update.api_access?
      return user_to_update unless user_to_update.changed?

      user_to_update.transaction do
        user_to_update.invite_pending = false if user_to_update.invite_pending?
        user_to_update.save!
      end

      user_to_update
    end
  end
end
