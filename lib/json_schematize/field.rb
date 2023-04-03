# frozen_string_literal: true

require 'json_schematize/field_transformations'
require 'json_schematize/field_validators'

class JsonSchematize::Field

  attr_reader :name, :types, :dig, :dig_type, :symbol, :validator, :empty_value
  attr_reader :acceptable_types, :required, :converter, :array_of_types

  EXPECTED_DIG_TYPE = [DIG_SYMBOL = :symbol, DEFAULT_DIG = DIG_NONE =:none, DIG_STRING = :string]

  def initialize(name:, types:, dig:, dig_type:, validator:, type:, required:, converter:, empty_value:, array_of_types: false)
    @name = name
    @types = types
    @type = type
    @dig = dig.nil? ? [name] : dig
    @dig_type = dig_type || DEFAULT_DIG
    @required = required
    @validator = validator
    @acceptable_types = []
    @converter = converter
    @empty_value = empty_value
    @array_of_types = array_of_types
  end

  def setup!
    # validations must be done before transformations
    validations!
    transformations!
    @acceptable_types << ((empty_value.class == Class) ? empty_value : empty_value.class)
  end

  def value_transform(value:)
    return iterate_array_of_types(value: value) if array_of_types

    raw_converter_call(value: value)
  end

  def acceptable_value?(transformed_value:, raise_on_error:)
    if array_of_types
      if transformed_value.is_a?(empty_value) && required == false
        boolean = true
      else
        boolean = transformed_value.all? { |val| validate_acceptable_types(val: val) }
      end
    else
      boolean = validate_acceptable_types(val: transformed_value)
    end

    if raise_on_error && (boolean==false)
      raise JsonSchematize::InvalidFieldByType, ":#{name} is an invalid option based on acceptable klass types [#{@acceptable_types}]#{ " -- array_of_types enabled" if array_of_types }"
    end

    boolean
  end

  def acceptable_value_by_validator?(transformed_value:, raw_value:, raise_on_error:)
    if array_of_types
      if transformed_value.is_a?(empty_value) && required == false
        boolean = true
      else
        boolean = transformed_value.all? { |val| validator.call(transformed_value, raw_value) }
      end
    else
      boolean = validator.call(transformed_value, raw_value)
    end

    boolean = validator.call(transformed_value, raw_value)
    if raise_on_error && (boolean==false)
      raise JsonSchematize::InvalidFieldByValidator, ":#{name} is an invalid option based on validator :proc option; #{validator}#{ " -- array_of_types enabled" if array_of_types }"
    end

    boolean
  end

  def value_from_field(params)
    begin
      value = params.dig(*dig)
    rescue TypeError => e
      msg = "Unable to dig #{dig} for field :#{name}. Returning nil"
      ::Kernel.warn(msg)
      return nil
    end

    { raw_value: value, transformed_value: value_transform(value: value)}
  end

  private

  def validate_acceptable_types(val:)
    (all_allowed_types + @acceptable_types).include?(val.class)
  end

  def all_allowed_types
    @all_allowed_types ||= begin
      @acceptable_types.map do |t|
        t.acceptable_types if t.ancestors.include?(JsonSchematize::Base)
      end.compact.flatten
    end
  end

  def iterate_array_of_types(value:)
    return raw_converter_call(value: value) unless array_of_types
    return empty_value.new if value.nil? && required == false

    unless value.is_a?(Array)
      raise JsonSchematize::InvalidFieldByArrayOfTypes, ":#{name} expected to be an array based on :array_of_types flag. Given #{value.class}"
    end

    value.map do |val|
      raw_converter_call(value: val)
    end
  end

  def raw_converter_call(value:)
    return convert_empty_value if value.nil? && (required == false)

    converter.call(value)
  end

  def convert_empty_value
    empty_value.class == Class ? empty_value.new : empty_value
  end

  include JsonSchematize::FieldTransformations
  include JsonSchematize::FieldValidators
end
