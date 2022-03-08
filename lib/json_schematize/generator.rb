# frozen_string_literal: true

require "json_schematize/field"

# SchemafiedJSON
# JSONSchematize

class JsonSchematize::Generator
  EMPTY_VALIDATOR = ->(_transformed_value,_raw_value) { true }
  PROTECTED_METHODS = [:assign_values!, :convenience_methods, :validate_required!, :validate_optional!, :validate_value]

  def self.add_field(name:, type: nil, types: [], dig_type: nil, dig: nil, validator: EMPTY_VALIDATOR, required: true, converter: nil, array_of_types: false)
    field_params = {
      converter: converter,
      dig: dig,
      dig_type: dig_type,
      name: name,
      required: required,
      type: type,
      types: types,
      validator: validator,
    }
    field = JsonSchematize::Field.new(**field_params)
    field.setup!

    if required
      required_fields << field
    else
      optional_fields << field
    end
    convenience_methods(field: field)
  end

  def self.fields
    required_fields + optional_fields
  end

  def self.required_fields
    @required_fields ||= []
  end

  def self.optional_fields
    @optional_fields ||= []
  end

  def self.convenience_methods(field:)
    unless self.instance_methods.include?(:"#{field.name}=")
      define_method(:"#{field.name}=") do |value|
        validate_params = {
          field: field,
          raw_value: value,
          transformed_value: value,
          raise_on_error: raise_on_error,
        }
        return false unless validate_value(**validate_params)

        instance_variable_set(:"@#{field.name}", value)
        return true
      end
    end
    unless self.instance_methods.include?(:"#{field.name}")
      define_method(:"#{field.name}") do
        instance_variable_get("@#{field.name}".to_sym)
      end
    end
  end

  attr_reader :__raw_params, :raise_on_error


  def initialize(raise_on_error: true, **params)
    @__params = params
    @raise_on_error = raise_on_error

    validate_required!
    validate_optional!
    assign_values!
  end

  private

  def assign_values!
    self.class.fields.each do |field|
      value = field.value_from_field(@__params)[:transformed_value]

      instance_variable_set(:"@#{field.name}", value)
    end
  end

  def validate_required!
    self.class.required_fields.each do |field|
      value = field.value_from_field(@__params)
      validate_value(field: field, raise_on_error: true, **value)
    end
  end

  def validate_optional!
    self.class.optional_fields.each do |field|
      value = field.value_from_field(@__params)
      validate_value(field: field, raise_on_error: raise_on_error, **value)
    end
  end

  def validate_value(field:, raw_value: nil, **params)
    field.acceptable_value?(**params) && field.acceptable_value_by_validator?(raw_value: raw_value, **params)
  end
end
