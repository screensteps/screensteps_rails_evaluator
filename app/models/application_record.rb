class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  class << self
    # Creates a simple scope named "search_text" that performs a LIKE query over the named
    # column or columns.
    def search_text_scope(columns)
      scope :search_text, lambda { |text|
        if text.present?
          search_string = "%#{sanitize_sql_like(text)}%"
          Array(columns).map { |column| where(arel_table[column].matches(search_string)) }.reduce(&:or)
        end
      }
    end
  end
end
