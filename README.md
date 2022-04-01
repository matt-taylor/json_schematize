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
```
name -- Name of the field. Field name can be accessed from the instance
type -- Class of the expected field type
types -- To be used when you want the field to have multiple types. Useful for similar classes like DateTime, Date, Time (converter must be supplied when multiple types are given)
dig_type -- Methodolgy of how to dig into the given param for the field. All values of the `dig` array will be converted accordingly. Default is `none` and will attempt to use what is given. [:symbol, :string, :none].
dig -- Array telling JsonSchematize how to dig into the provided hash
validator -- Proc value to validate the data found in the params. Proc given (transformed_value, original_value) when calling in
required -- Default is true. When not set, each instance class can optionally decide if they want to raise when an this is set to false.
converter -- Proc return is set to the field value. No furter validation is done. Given (value) as a parameter
array_of_types -- Detailed example above. Set this value to true when the dig param is to an array and you want all values in array to be parsed the given type
empty_value -- When required is false, this value is used to fill the field. By default it is JsonSchematize::EmptyValue, but can be changed to anything
```

### Schema defaults

Defaults can be added for all fields for any of the available options. This can be useful for returned API calls when the body is parsed as a Hash with String keys.

```ruby
class SchemaWithDefaults < JsonSchematize::Generator
  schema_default option: :dig_type, value: :string

  add_field name: :internals, type: InternalBody, array_of_types: true
  add_field name: :id, type: Integer
  add_field name: :status, type: Symbol, required: false, empty_value: "empty"
end
```

### Custom Classes

```ruby
class CustomClasses < JsonSchematize::Generator
  # JsonSchematize::Boolean can be used as a type when expecting a conversion of possible true or false values converted into a TrueClass or FalseClass
  add_field name: :internals, type: JsonSchematize::Boolean
end
```

### Caching Adapter

JsonSchematize is built to be schema for API results. But what happens when you dont expect the result to change? Introducing the caching layer. This layer lets you cache a `JsonSchematize` object that can be queried from later

**Note: This requires redis**

```ruby
class CachedClass < JsonSchematize::Generator
  include JsonSchematize::Cache
  cache_options key: ->(instance_of_cached_class, cache_key_from_initialization) { "#{instance_of_cached_class.id}:#{cache_key_from_initialization}" }
  cache_options ttl: 7.days.to_i

  schema_default option: :dig_type, value: :string

  add_field name: :id, type: Integer
end

params = { id: 1 }
CachedClass.new(cache_key: User.first.id, **params)
###
params = { "id" => 1 }
CachedClass.new(params, cache_key: User.first.id)
```

#### Instance methods for Cache
```ruby
# optional cache_key added on initialization: Can be used to customize the cache entry for the instance
item = CachedClass.new(cache_key: User.first.id, **params)

# Update the cached item -- Note: This will overwrite the previous cached item IFF the `__cache_key__` remains the same. This is not gaurenteed
# Optional Param: with_delete, Default true -- Will attempt to delete the original object
item.__update_cache_item__

# Manually delete the cached entry
item.__clear_entry__!

# Cache key for the item
item.__cache_key__
```

#### Class methods for Cache
```ruby
# Retrieve all cached items for the class. Returns an array of CachedClass objects. Only objects that have not expired via TTL
# Optional: key_includes: "string_expected_in_cache", default is nil and return everthing
CachedClass.cached_items

# Retrieves all valid object keys from the cache
CachedClass.cached_keys

# Clears all cached items for the given class
CachedClass.clear_cache!

# manually clear objects that have expired
CachedClass.clear_unscored_items!
```
### Cache options
```ruby
# [Required] false; [Expect] Proc; [Return] String to be used as instance key; [Default] key will be the hash of the object
cache_options key: ->(instance_of_class, custom_key) { }

# [Required] false; [Expect] String; [Default] ENV["CACHE_LAYER_REDIS_URL"] || ENV["REDIS_URL"]
cache_options redis_url: _redis_url_value

# [Required] false; [Expect] Redis Object or Proc that returns value of Redis Client; [Default] Redis.new(url: redis_url)
cache_options redis_client: redis_client

# [Required] false; [Expect] Object that plays with to_s and has no spaces; [Default] Full class name downcased
cache_options cache_namespace: cache_namespace

# [Required] false; [Expect] Integer in seconds; [Default] 1 day
cache_options ttl: (60 * 60)

# [Required] false; [Expect] Boolean; [Default] true
# Update the cache when a value has been changed manually
cache_options update_on_change: true
```

## Development

This gem can be developed against local machine or while using docker. Simpleified Docker commands can be found in the `Makefile` or execute `make help`

## Contributing

This gem welcomes contribution.

Bug reports and pull requests are welcome on GitHub at
https://github.com/matt-taylor/json_schematize.


