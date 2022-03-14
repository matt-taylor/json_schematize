# frozen_string_literal: true

require "json_schematize/field"
require "json_schematize/introspect"

class JsonSchematize::Generator
  EMPTY_VALIDATOR = ->(_transformed_value, _raw_value) { true }
  PROTECTED_METHODS = [:assign_values!, :convenience_methods, :validate_required!, :validate_optional!, :validate_value]

  include JsonSchematize::Introspect

  def self.add_field(name:, type: nil, types: nil, dig_type: nil, dig: nil, validator: nil, required: nil, converter: nil, array_of_types: nil, empty_value: nil)
    field_params = {
      converter: converter || schema_defaults[:converter],
      dig: dig || schema_defaults[:dig],
      dig_type: dig_type || schema_defaults[:dig_type],
      name: name,
      required: (required.nil? ? schema_defaults.fetch(:required, true) : required),
      type: type || schema_defaults[:type],
      types: types || schema_defaults.fetch(:types, []),
      empty_value: empty_value || schema_defaults.fetch(:empty_value, JsonSchematize::EmptyValue),
      validator: validator || schema_defaults.fetch(:validator, EMPTY_VALIDATOR),
      array_of_types: (array_of_types.nil? ? schema_defaults.fetch(:array_of_types, false) : array_of_types),
    }

    field = JsonSchematize::Field.new(**field_params)
    field.setup!

    if field_params[:required] == true
      required_fields << field
    else
      optional_fields << field
    end
    convenience_methods(field: field)
  end

  def self.schema_default(option:, value:)
    if fields.length > 0
      ::Kernel.warn("Default [#{option}] set after fields #{fields.map(&:name)} created. #{option} default will behave inconsistently")
    end

    schema_defaults[option.to_sym] = value
  end

  def self.schema_defaults
    @schema_defaults ||= {}
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

  attr_reader :__raw_params, :raise_on_error, :values_assigned

  # stringified_params allows for params with stringed keys
  def initialize(stringified_params = nil, raise_on_error: true, **params)
    @values_assigned = false
    @__params = stringified_params.nil? ? params : stringified_params
    @__raw_params = @__params
    @raise_on_error = raise_on_error

    if @__params
      validate_required!
      validate_optional!
      assign_values!
      @values_assigned = true
    end
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
