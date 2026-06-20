class User < ApplicationRecord
  include Discard::Model

  attr_accessor :send_new_user_email, :terms_of_service, :invite_sign_up
  attr_writer   :remember_expires_at

  search_text_scope %i[name login email]

  normalizes :first_name, :last_name, with: -> { it.presence }
  normalizes :role, with: -> { it.downcase.presence }

  ROLE_ADMIN       = 'admin'.freeze
  ROLE_EDITOR      = 'editor'.freeze
  ROLE_READER      = 'reader'.freeze
  ROLE_API_ACCESS  = 'api access'.freeze
  ROLE_ROOT        = 'root'.freeze
  ROLE_BACKEND_AGENT = 'backend_agent'.freeze

  USER_ROLES           = ['admin', 'editor', 'reader', 'api access'].freeze
  AGENT_ROLES          = %w[root backend_agent].freeze
  AUTHORIZED_ROLES     = %w[admin editor].freeze
  ALL_ROLES            = (USER_ROLES + AGENT_ROLES).freeze
  LOCK_ROLES           = ['api access'].freeze
  ADMINISTRATIVE_ROLES = %w[admin root backend_agent].freeze
  READ_ONLY_ROLES      = ['reader', 'api access'].freeze
  NON_ADMINISTRATIVE_ROLES = (USER_ROLES - ADMINISTRATIVE_ROLES).freeze

  NAME_AND_EMAIL_ATTRIBUTES = %w[email first_name last_name].freeze

  belongs_to :account, optional: true

  alias_attribute :timezone, :time_zone

  validates :login, presence: { if: :login_required? }, length: 3..100, format: /\A[^ ]+\z/,
                    uniqueness: { scope: :account_id, allow_blank: true,
                                  message: ->(model, data) { model.existing_data_error_message(:login, data[:value]) } }
  validates :email, presence: { if: :email_required? },
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    allow_blank: true,
                    uniqueness: { scope: :account_id, allow_blank: true, case_sensitive: false,
                                  message: ->(model, data) { model.existing_data_error_message(:email, data[:value]) } }
  validates :first_name, length: { maximum: 255 }, format: { without: /[<>]/ }
  validates :last_name,  length: { maximum: 255 }, format: { without: /[<>]/ }
  validates :role, inclusion: { in: USER_ROLES }, if: -> { account.present? }
  validates :role, inclusion: { in: AGENT_ROLES }, if: -> { account.blank? }

  validate :timezone_exists
  validate :generate_public_id, on: :create
  validate :owners_cannot_be_deactivated

  before_save   :update_computed_name
  after_create  :send_new_admin_email, if: :send_new_user_email?
  before_update :check_lock_role
  before_discard :check_discardability
  after_save :send_new_reader_email, if: :send_new_user_email?

  scope :readers,           -> { where(role: 'reader') }
  scope :admins,            -> { where(role: 'admin') }
  scope :editors,           -> { where(role: 'editor') }
  scope :active,            -> { where(deactivated: false) }
  scope :authorized,        -> { where(role: AUTHORIZED_ROLES) }
  scope :non_administrative, -> { where(role: NON_ADMINISTRATIVE_ROLES) }
  scope :with_role, ->(role) { where(role: role) }

  def to_s = name

  class RoleLockedError < StandardError; end

  def check_lock_role
    return unless role_changed? && LOCK_ROLES.include?(role_was)

    raise RoleLockedError, "API Users cannot have their role changed (login: #{login})"
  end

  def role=(value)
    value = 'reader' if 'learner'.casecmp?(value)
    value = 'editor' if 'author'.casecmp?(value)
    self[:role] = value
  end

  def self.find_for_account(account = nil, account_scope: nil, **conditions)
    scope = account_scope || account&.users
    scope&.find_by(**conditions) || User.find_by(role: AGENT_ROLES, account_id: nil, **conditions)
  end

  def has_role?(an_account = nil, *role_symbols)
    return true if agent?
    return role_symbols.any? { |r| send(:"#{r}?") } if an_account.nil?
    return account_id == an_account.id if role_symbols.any? { |r| send(:"#{r}?") }

    false
  end

  def admin?   = (role == 'admin')
  def editor?  = (role == 'editor')
  def reader?  = (role == 'reader')
  def root?    = (role == 'root')
  def api_access?     = (role == 'api access')
  def backend_agent?  = (role == 'backend_agent')
  def agent?          = AGENT_ROLES.include?(role)
  def authorized_user? = admin? || editor?
  def active?         = !deactivated?
  def owner?          = account&.owner_id.present? && account.owner_id == id
  def billable_user?  = AUTHORIZED_ROLES.include?(role)

  def name
    super || compute_name
  end

  def generate_public_id
    return if public_id.present?

    loop do
      self.public_id = SecureRandom.hex(8)
      break unless User.exists?(public_id: public_id)
    end
  end

  def existing_data_error_message(attribute, value)
    other = account.users.find_by(attribute => value)
    return if other == self

    if other.invite_pending
      'is already assigned to another user with a pending invite'
    else
      'is already assigned to another user'
    end
  end

  def access_locked? = deactivated? || discarded?

  private

  def compute_name
    if first_name.present? && last_name.present?
      "#{first_name} #{last_name}"
    else
      first_name.presence || last_name.presence || login
    end
  end

  def update_computed_name
    self.name = compute_name if first_name_changed? || last_name_changed?
  end

  def make_activation_code
    self.activated_at = Time.current
  end

  def login_required? = !invite_pending

  def email_required?
    !(reader? || api_access?)
  end

  def timezone_exists
    return if timezone.blank? || ActiveSupport::TimeZone[timezone].present?

    errors.add(:timezone, message: 'does not exist')
  end

  def send_new_user_email?
    !!send_new_user_email
  end

  def send_new_admin_email
    # OutboundEmailJob.perform_later(:user_account_info, user: self, password: password) if billable_user?
  end

  def send_new_reader_email
    nil unless reader? && email.present? && account.spaces.viewable_by_user(self).any?

    # OutboundEmailJob.perform_later(:new_reader_welcome, user: self, plaintext_password: password)
  end

  def being_deactivated? = deactivated && deactivated_changed?

  def check_discardability
    return unless owner?

    errors.add(:base, message: 'Account owners cannot be discarded')
    throw :abort
  end

  def owners_cannot_be_deactivated
    return unless owner?

    errors.add(:deactivated, message: 'cannot be set for account owners') if deactivated?
    errors.add(:base, message: 'Account owners cannot be discarded') if discarded?
  end
end
