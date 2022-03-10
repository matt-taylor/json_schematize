# JsonSchematize

`JsonSchematize` is emant to be a simple schema control version used to aprse data returned from any API.

It can handle nested Schematized versions and build the tree all the way down

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'json_schematize'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install json_schematize

## Usage

Given hash value of the following:
```json
{
  "status":"complete",
  "id":"127392",
  "body":
    [
      {
        "status":"failed",
        "id":"12345",
        "field_i_dont_care_about": false
      },
      {
        "status":"failed",
        "id":"6347",
        "field_i_dont_care_about": true
      }
    ]
}
```

```ruby
# lib/schema/internal_body
require 'json_schematize/generator'

class InternalBody < JsonSchematize::Generator
  ALLOWED_STATUSES = [:failed, :completed, :success]

  add_field name: :id, type: Integer
  add_field name: :status, type: Symbol, validator: ->(transformed_value, raw_value) { ALLOWED_STATUSES.include?(transformed_value) }
end

###
# lib/schema/my_first_schema
require 'json_schematize/generator'
require 'internal_body' #dependeing on load order

class MyFirstSchema < JsonSchematize::Generator
  add_field name: :internals, type: InternalBody, array_of_types: true, dig: ["body"]
  add_field name: :id, type: Integer
  add_field name: :status, type: Symbol
end

schema = MyFirstSchema.new(**json_hash)
schema.internals.count #=> 2
schema.internals.first.status #=> :failed
schema.id #=> 127392
schema.id = 999999  #assignments are still subject to validation logic for each field
schema.id #=> 999999
```

### Field options:
```bash
name -- Name of the field. Field name can be accessed from the instance
type -- Class of the expected field type
types -- To be used when you want the field to have multiple types. Useful for similar classes like DateTime, Date, Time (converter must be supplied when multiple types are given)
dig_type -- Methodolgy of how to dig into the given param for the field. All values of the `dig` array will be converted accordingly. Default is `none` and will attempt to use what is given. [:symbol, :string, :none].
dig -- Array telling JsonSchematize how to dig into the provided hash
validator -- Proc value to validate the data found in the params. Proc given (transformed_value, original_value) when calling in
required -- Default is true. When not set, each instance class can optionally decide if they want to raise when an this is set to false.
converter -- Proc return is set to the field value. No furter validation is done. Given (value) as a parameter
array_of_types -- Detailed example above. Set this value to true when the dig param is to an array and you want all values in array to be parsed the given type
```
### Custom Classes

```ruby
class CustomClasses < JsonSchematize::Generator
  # JsonSchematize::Boolean can be used as a type when expecting a conversion of possible true or false values converted into a TrueClass or FalseClass
  add_field name: :internals, type: JsonSchematize::Boolean
end
```

## Development

This gem can be developed against local machine or while using docker. Simpleified Docker commands can be found in the `Makefile` or execute `make help`

## Contributing

This gem welcomes contribution.

Bug reports and pull requests are welcome on GitHub at
https://github.com/matt-taylor/json_schematize.


