module Api
  class UsersController < ApplicationController
    deserializable_resource :user, class: BaseDeserializer, only: %i[update]

    def index
      if params[:id] == 'current'
        json_render [current_user]
      else
        users = filter_users

        records, meta = if params[:contributors].present?
                          paginate(users, 100, :countless)
                        else
                          paginate(users, 25, :countless)
                        end
        json_render records, **meta
      end
    end

    def show
      if current_user.editor? && !editor_finding_self? && !notification_access?
        json_render user, jsonapi_args: { fields: { user: %i[firstName lastName name role] } }
      else
        json_render user
      end
    end

    def update
      json_render update_user
    end

    def destroy
      User::Destroy.perform(user_context: pundit_user, user_to_destroy: user)
      head :no_content
    end

    private

    def filter_users
      if simulate_unified_permissions?
        current_account.assume_unified_permissions do
          User::Finder.new(user_context).where(filter_params.to_h)
        end
      else
        User::Finder.new(user_context).where(filter_params.to_h)
      end
    end

    def notification_access?
      params[:include] == 'notification_access'
    end

    def user
      @user ||= case params[:id]
                when 'current'
                  current_user
                else
                  current_account.users.find(params.expect(:id))
                end
    end

    def site
      @site ||= current_account.spaces.find(site_id)
    end

    def editor_finding_self?
      current_user.editor? && (params[:id] == 'current' || current_user.id == params[:id].to_i)
    end

    def update_user
      begin
        User::Update.perform(user_context: user_context, user_to_update: user,
                             params: user_params_for_update, user_billing_level: 'full')
      rescue StandardError => e
        user.errors.add(:base, message: e.message) if user.errors.empty?
      end

      user
    end

    def user_params_for_create
      options = params.require(:user).permit(permitted_params.push(:role, group_ids: []))

      options[:site_permissions] = site_permission_params if site_permission_params.present?

      options
    end

    def user_params_for_update
      attributes = permitted_params
      attributes.delete(:role) if current_account.has_feature?(:roles_via_groups)
      attributes.delete(:deactivated) if user.owner?

      options = params.require(:user).permit(attributes)

      prevent_editor_from_changing_attrs options
      options
    end

    def filter_params
      @filter_params ||= params.permit(:active, :allow_billing_access, :allow_pdf_template_access,
                                       :asset_id, :asset_type,
                                       :assigned_to_site_id, :course_id, :course_collection_id,
                                       :filter_class, :group_id, :id,
                                       :include_notification_stats, :lesson_id, :name, :role,
                                       :section_id, :site_id, :sort_by)
    end

    def permitted_params
      %i[allow_billing_access allow_pdf_template_access auto_subscribe deactivated
         email external_id first_name invite_pending last_name login organization password
         password_confirmation remote_authentication_user role send_new_user_email
         terms_of_service time_zone]
    end

    def prevent_editor_from_changing_attrs(options)
      return unless current_user.editor?

      options.delete(:deactivated)
      options.delete(:role)
    end
  end
end
