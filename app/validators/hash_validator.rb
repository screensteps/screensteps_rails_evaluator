class HashValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil? || value.is_a?(Hash)

    record.errors.add(attribute, :invalid, message: options[:message] || 'must be a Hash')
  end
end
