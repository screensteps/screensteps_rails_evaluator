class Manual < ApplicationRecord
  include Discard::Model

  UNCATEGORIZED_TITLE = 'Uncategorized'.freeze
  SPACE_ATTRIBUTES    = %w[draft title permalink restricted icon].freeze

  normalizes :permalink, with: -> { it.presence }

  belongs_to :creator, class_name: 'User', optional: true
  belongs_to :space

  alias site space

  validates :title, presence: true
  validates :title, length: { in: 1..255 }, allow_blank: true
  validates :permalink, uniqueness: { scope: :space_id, allow_blank: true },
                        format: { with: /\A([a-zA-Z][a-zA-Z0-9_-]*|\s*)\z/ }

  after_update :touch_spaces, if: :saved_change_to_space_attributes?

  scope :exposed,      -> { where(internal: false) }
  scope :published,    -> { exposed.where(draft: false) }
  scope :draft,        -> { exposed.where(draft: true) }
  scope :restricted,   -> { exposed.where(restricted: true) }
  scope :unrestricted, -> { exposed.where(restricted: false) }

  def to_s = title
  def published? = !draft
  def published  = published?
  def uncategorized? = internal && title == UNCATEGORIZED_TITLE

  def to_param
    permalink.presence || id.to_s
  end

  def title_for_public
    public_title.presence || title
  end

  def saved_change_to_space_attributes?
    SPACE_ATTRIBUTES.intersect?(saved_changes.keys)
  end

  private

  def touch_spaces
    spaces.each(&:touch)
  end
end
