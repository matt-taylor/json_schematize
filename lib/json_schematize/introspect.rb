# frozen_string_literal: true

module JsonSchematize::Introspect
  def to_h
    self.class.fields.map do |field|
      value = method(:"#{field.name}").()
      if field.array_of_types
        [field.name, value.map(&:to_h)]
      elsif JsonSchematize::Generator === value
        [field.name, value.to_h]
      else
        [field.name, value]
      end
    end.to_h
  end
  alias :to_hash :to_h

  def deep_inspect(with_raw_params: false, with_field: false)
    self.class.fields.map do |field|
      value = {
        required: field.required,
        acceptable_types: field.acceptable_types,
        value: instance_variable_get(:"@#{field.name}"),
      }
      value[:field] = field if with_field
      value[:raw_params] = @__raw_params if with_raw_params
      [field.name, value]
    end.to_h
  end

  def inspect
    stringify = to_h.map { |k, v| "#{k}:#{v}" }.join(", ")
    "#<#{self.class} - required fields: #{self.class.required_fields.map(&:name)}; #{stringify}>"
  end
end
