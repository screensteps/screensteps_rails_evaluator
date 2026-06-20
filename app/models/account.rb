class Account < ApplicationRecord
  CANCELED_ACCOUNT_STATUS = %w[canceled expired_trial no_payment].freeze
  ACTIVE_ACCOUNT_STATUS   = %w[active trial].freeze

  enum :status, {
    active: 'active',
    trial: 'trial',
    expired_trial: 'expired trial',
    canceled: 'canceled',
    no_payment: 'no_payment',
    paused: 'paused'
  }, validate: true

  store_accessor :data, :billing_usage_start_day, :full_user_overage_price,
                 :light_user_overage_price, :replay_secret

  belongs_to :owner, class_name: 'User', optional: true

  has_many :users,   dependent: :destroy
  has_many :spaces,  dependent: :destroy
  has_many :manuals, through: :spaces

  validates :company, presence: true
  validates :domain,  presence: true

  validate :generate_public_id, on: :create

  before_validation :sanitize_company
  before_save :generate_api_key, if: :needs_api_key?
  before_create :downcase_domain_name
  before_destroy :approve_destroy, prepend: true

  scope :expired,             -> { where(trial_expires_at: (...Time.zone.today)) }
  scope :all_active_accounts, -> { where(status: ACTIVE_ACCOUNT_STATUS) }

  def to_s         = company
  def display_name = company || domain

  def host
    "#{domain}.#{Rails.configuration.settings.host}"
  end

  def canceled?
    %w[canceled inactive].include?(status)
  end

  def active_account_status?
    ACTIVE_ACCOUNT_STATUS.include?(status)
  end

  def expired?
    !active_account_status?
  end

  def trial_days_left
    trial? && trial_expires_at.present? ? (trial_expires_at.to_date - Date.current).to_i : 0
  end

  def generate_public_id
    return if public_id.present?

    key = SecureRandom.hex(5)
    key = SecureRandom.hex(5) while Account.find_by(public_id: key)
    self.public_id = key
  end

  def schedule_deletion(date = 90.days.from_now)
    self.flagged_for_deletion  = true
    self.scheduled_deletion_at = date
  end

  def clear_deletion_schedule
    self.flagged_for_deletion  = false
    self.scheduled_deletion_at = nil
  end

  def needs_api_key?
    api_enabled && api_key.blank?
  end

  private

  def sanitize_company
    self.company = Rails::Html::FullSanitizer.new.sanitize(company)&.gsub(%r{\bhttps?://}, '')
  end

  def downcase_domain_name
    self.domain = domain&.downcase
  end

  def generate_api_key
    key = Digest::SHA1.hexdigest(Time.zone.now.to_s + rand(12_341_234).to_s)[1..15]
    update_attribute(:api_key, key)
  end

  def approve_destroy
    if spaces.any?
      errors.add(:base, message: 'cannot delete an account with spaces')
      throw :abort
    end

    return unless active?

    errors.add(:base, message: 'account is active')
    throw :abort
  end
end
