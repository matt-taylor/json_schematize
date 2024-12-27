# frozen_string_literal: true

module JsonSchematize::Introspect
  module ClassMethods
    def introspect(deep: false, prepend_dig: [], introspection: {})
      fields.each do |field|
        naming = (prepend_dig + field.dig).compact
        type_metadata = __field_type__(field)
        introspection[naming.join(".")] = {
          required: field.required,
          allowed: type_metadata[:humanize],
        }

        if deep && type_metadata[:deep_introspection]
          prepended_naming = if field.array_of_types
            naming.dup.tap { _1[-1] = "#{_1[-1]}[x]"}
          else
            naming.dup
          end
          type_metadata[:types][0].introspect(deep:, prepend_dig: prepended_naming, introspection: introspection)
        end
      end

      introspection
    end

    def __field_type__(field)
      types = Array(field.type || field.types)
      deep_introspection = false
      type_string = if types.length == 0
        "Anything"
      elsif types.length == 1
        type = types.first
        if JsonSchematize::Generator > type
          deep_introspection = true
          if field.array_of_types
            "Array of #{type}"
          else
            type
          end
        else
          type
        end
      else
        "One of [#{types}]"
      end

      {
        humanize: type_string,
        types:,
        deep_introspection:,
      }
    end
  end
end
