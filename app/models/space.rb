class Space < ApplicationRecord
  HOST_REGEXP = %r{\A(?:https?://)?(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,63}/?\z}

  attr_accessor :asset_type, :asset_title, :cloning

  store_accessor :data, :colors, :site_strings, :site_settings

  normalizes :host_mapping, with: -> { _1.downcase.presence }
  normalizes :permalink, with: -> { _1.presence }

  belongs_to :account

  has_many :manuals, -> { exposed }

  validates :title, presence: true
  validates :host_mapping, uniqueness: { allow_nil: true }
  validates :meta_description, length: { maximum: 255 }
  validates :meta_title, length: { maximum: 255 }
  validates :permalink, format: { with: /\A[a-zA-Z][a-zA-Z0-9_-]+\z/, allow_blank: true },
                        uniqueness: { scope: :account_id, allow_nil: true }
  validates :colors, hash: true
  validates :site_strings, hash: true
  validates :site_settings, hash: true

  validate :validate_host_mapping, if: :host_mapping_changed?
  validate :ratings_only_allowed_on_public_sites

  after_initialize :init_data

  before_create :set_defaults

  scope :private_spaces,       -> { where(protected: true) }
  scope :public_spaces,        -> { where(protected: false) }
  scope :prefer_private_first, -> { reorder(protected: :desc, id: :asc) }

  def to_s = title
  def to_param = permalink_or_id
  def public? = !protected?
  def host_mapping? = host_mapping.present?
  def template_2019? = (content_template == '2019')
  def template_2015? = (content_template == '2015')

  def permalink_or_id
    permalink.presence || id.to_s
  end

  def self.find_by_id_or_permalink(permalink)
    raise ActiveRecord::RecordNotFound if permalink.nil?

    permalink.to_i.positive? ? find_by(id: permalink.to_i) : find_by(permalink: permalink)
  end

  def make_company_space!
    account.update!(company_space_id: id)
  end

  def company_space?
    account.company_space_id == id
  end

  def generate_uncategorized_manual!
    manuals.find_or_create_by!(title: Manual::UNCATEGORIZED_TITLE, internal: true, account: account)
  end

  def uncategorized_manual
    manuals.rewhere(internal: true).find_by!(title: Manual::UNCATEGORIZED_TITLE)
  rescue ActiveRecord::RecordNotFound
    account.manuals.create!(title: Manual::UNCATEGORIZED_TITLE, internal: true)
  end

  def reset_asset_positions!
    assets_spaces.each_with_index { |record, i| record.update!(position: i + 1) }
  end

  def clone_space(params = {})
    new_attrs = attributes.with_indifferent_access.merge({ domain: nil })
                          .merge(params)
                          .merge({ id: nil, authentication_endpoint_id: nil, permalink: nil,
                                   host_mapping: nil, logo_id: nil, favicon_id: nil, cloning: true })
    new_space = account.spaces.build(new_attrs)
    new_space.title = "#{title} (copy)" if params[:title].blank?

    if new_space.valid?
      new_space.save!
      manuals.each do |manual|
        new_manual = manual.dup
        new_manual.space = new_space
        new_manual.save!
      end
    end
    new_space
  end

  private

  def init_data
    self.colors ||= {}
    self.site_strings ||= {}
    self.site_settings ||= {}
  end

  def set_defaults
    self.language ||= 'en'
  end

  def validate_host_mapping
    return if host_mapping.blank?

    errors.add(:host_mapping, message: "Invalid domain: #{host_mapping}") unless HOST_REGEXP.match?(host_mapping)
  end

  def ratings_only_allowed_on_public_sites
    errors.add(:allow_ratings, message: 'cannot be enabled on a public site') if allow_ratings && public?
  end
end
