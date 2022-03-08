# frozen_string_literal: true

require 'json_schematize/field_transformations'
require 'json_schematize/field_validators'

class JsonSchematize::Field

  attr_reader :name, :types, :dig, :symbol, :validator, :acceptable_types, :required, :converter

  EXPECTED_DIG_TYPE = [DIG_SYMBOL = :symbol, DEFAULT_DIG = DIG_NONE =:none, DIG_STRING = :string]

  def initialize(name:, types:, dig:, dig_type:, validator:, type:, required:, converter:)
    @name = name
    @types = types
    @type = type
    @dig = dig.nil? ? [name] : dig
    @dig_type = dig_type || DEFAULT_DIG
    @required = required
    @validator = validator
    @acceptable_types = []
    @converter = converter
  end

  def setup!
    # validations must be done beofre transformations
    valiadtions!
    transformations!
  end

  def value_transform(value:)
    converter.call(value)
  end

  def acceptable_value?(transformed_value:, raise_on_error:)
    boolean = @acceptable_types.include?(transformed_value.class)
    if raise_on_error && (boolean==false)
      raise JsonSchematize::InvalidFieldByType, ":#{name} is an invalid option based on acceptable klass types [#{@acceptable_types}]"
    end

    boolean
  end

  def acceptable_value_by_validator?(transformed_value:, raw_value:, raise_on_error:)
    boolean = validator.call(transformed_value, raw_value)
    if raise_on_error && (boolean==false)
      raise JsonSchematize::InvalidFieldByValidator, ":#{name} is an invalid option based on validator :proc option; #{validator}"
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

  include JsonSchematize::FieldTransformations
  include JsonSchematize::FieldValidators
end
