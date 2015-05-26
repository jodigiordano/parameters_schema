# Parameters Schema

## *"A strict API is the best kind of API."*

In this line of thought, **[strong_parameters](https://github.com/rails/strong_parameters)** lacks some cool validations that this gem provide.

For example, let's say you want your operation `create` to require a `Fixnum` parameter between 1 and 99. With strong_parameters, you're out of luck. With this gem, you simply write in your controller:
``` ruby
class Api::PeopleController < Api::BaseController
  def create
    validated_params = validate_params params do
      param :age, type: Fixnum, allow: (1..99)
    end

    # Do something with the validated parameters.
  end
end
```

So when you use this controller:
``` ruby
> app.post 'api/people', age: 12  # validated_params = { age: 12 }
> app.post 'api/people', age: 100 # throws a ParameterSchema::InvalidParameters 
```

## Why use this gem instead of strong_parameters

* You prefer a procedural approach (via a DSL) over a declarative one.
* You want more control over the parameters of your API, at the type and format level.
* You want to do things differently, you fucking hipster.

## Installation

Add in your Gemfile:
``` ruby
gem 'parameters_schema'
```

Add in your project:
``` ruby
require 'parameters_schema'
```

## Schema

The schema is the heart of this gem.  It provides a simple DSL to express an operation's parameters.

Creating a schema:
``` ruby
schema = ParametersSchema::Schema.new do
  # Define parameters here...
  # ... but an empty schema is also valid.
end
```
Validating parameters against a schema:
``` ruby
params = { potatoe: 'Eramosa' }
schema.validate!(params) 
```

The minimal representation of a parameter is:
``` ruby
param :potatoe
```
This represents a `required` parameter of type `String` accepting any characters and which doesn't allow nil or empty values.

The valid options for a parameter are:
``` ruby
* required  # Whether the parameter is required. Default: true.
* type      # The type of the parameter. Default: String.
* allow     # The allowed values of the parameter. Default: :any.
* deny     # The denied values of the parameter. Default: :none.
* array     # Whether the parameter is an array. Default: false.
```

### Parameter types

The available types are: 
``` ruby
* String
* Symbol
* Fixnum
* Float
* Date
* DateTime
* Array     # An array of :any types.
* Hash      # An object which members are not validated further.
* :boolean  # See options for accepted values.
* :any      # Accepts any value type.
```

To accept more than one type, you can do:
``` ruby
param :potatoe, type: [Boolean, String] # Accepts a boolean or string value.
```

To accept an array of a specific type, you can do:
``` ruby
param :potatoes, type: { Array => String } # Accepts an array of strings.
```

To deeper refine the schema of an object, you pass a block to the parameter:
``` ruby
param :potatoe do # Implicitly of type Hash
  param :variety
  param :origin
end
```

As you have seen above, a parameter can be of type `Array` but can also have the option `array`. Confusing, right? This option was introduced to simplify the `type` syntax. For example:
``` ruby
param :potatoes, type: String, array: true   # This is equivalent...
param :potatoes, type: { Array => String }   # ... to this.
```

But this parameter truly shine with an array of objects:
``` ruby
param :potatoes, array: true do
  param :variety
  param :origin
end

# This syntax is also valid but less sexy:
param :potatoes, type: { Array => Hash } do
  param :variety
  param :origin
end
```

#### Gotchas
* A `Float` value can be passed to a `Fixnum` parameter but will loose its precision.
* Some types accepts more than one representation. Example: `Symbol` accepts any type that respond to `:to_sym`.
* If you define multiple types (ex: `[Symbol, String]`), values are interpreted in this order. So the value `'a'` will be cast to `:a`.
* Defining the type `{ Fixnum => Date }` doesn't make sense so it falls back to `Fixnum` (the key).
* `{ Array => Array }` is accepted. It means a 2D array of `:any`.
* `{ Array => Array => ... }` is not yet supported. Did I hear pull request?

### The `allow` and `deny` options

By default, the value of a parameter can be any one in the spectrum of a type, with the exception of nil and empty. The `allow` and `deny` options can be used to further refine the accepted values.

To accept nil or empty values:
``` ruby
param :potatoe, allow: :nil
# => accepts nil, 'Kennebec' but not ''.

param :potatoe, allow: :empty
# => accepts '', 'Kennebec' but not nil.

param :potatoe, allow: [:nil, :empty]
# => accepts nil, '' and 'Kennebec'
```
Of course, this *nil* or *empty* restriction doesn't make sense for all the types so it will only be applied when it does.

To accept predefined values:
``` ruby
param :potatoe, allow: ['Superior', 'Ac Belmont', 'Eramosa'] # this is case-sensitive.

# Gotcha: this will allow empty values even if you wanted to accept the value 'empty'. You can redefine keywords in the options.
param :potatoe, type: Symbol, allow: [:superior, :ac_belmont, :empty]
```

To accept a value matching a regex:
``` ruby
param :potatoe, allow: /^[a-zA-Z]*$/

# Gotcha: even though the regex above allows empty values, it must be explicitly stated:
param :potatoe, allow: [:empty, /^[a-zA-Z]*$/]
```

To accept a value in a range:
``` ruby
param :potatoe, type: Fixnum, allow: (1..3)
# => accepts 1, 2, 3 but will fail on any other value.
```

The `deny` option is conceptually identical to `allow` but a value will fail the validation if a match is found:
``` ruby
param :potatoe, type: Fixnum, deny: (1..3)
# => accepts any value except 1, 2, 3.
```

The options `allow` and `deny` are validated independently. So beware to not define `allow` and `deny` options that encompass all the possible values of the parameter!

## Exceptions

When the validation fails, an instance of `ParametersSchema::InvalidParameters` is raised. This exception contains the attribute `errors` which is an hash of `{ key: error_code }` that you can work with.

Simple case:
``` ruby
ParametersSchema::Schema.new do
  param :potatoe
end.validate!({})

# => ParametersSchema::InvalidParameters
#      @errors = { potatoe: :missing }
```

The validation process tries to accumulate as many errors as possible before raising the exception, so you can have a precise picture of what went wrong:
``` ruby
ParametersSchema::Schema.new do
  param :potatoe do
    param :name
    param :type, allow: ['Atlantic']
  end
end.validate!(potatoe: { type: 'Conestoga' })

# => ParametersSchema::InvalidParameters
#      @errors = { potatoe: { name: :missing, type: :disallowed } }
```

The possible error codes are (in the order the are validated):
``` ruby
* :unknown          # The parameter is provided but not defined in the schema.
* :missing          # The parameter is required but is missing.
* :nil              # The value cannot be nil but is nil.
* :empty            # The value cannot be empty but is empty.
* :disallowed       # The value has an invalid format (type/allow) other than nil/empty.
```

## Integrate with Rails

This gem can be used outside of Rails but was created with Rails in mind. For example, the parameters `controller, action, format` are skipped by default (see Options section to override this behavior) and the parameters are defined in a `Hash`. However, this gem doesn't insinuate itself in your project so you must manually add it in your controllers or anywhere else that make sense to you. Here is a little recipe to add validation in your API pipeline:

In the base controller of your API, add this **helper**:
``` ruby
    # Validate the parameters of an action, using a schema.
    # Returns the validated parameters and throw exceptions on invalid input.
    def validate_params(&parameters_schema)
      schema = ParametersSchema::Schema.new(&parameters_schema)
      schema.validate!(params)
    end
```
In the base controller of your API, add this **exception handler**:
``` ruby
  # Handle errors related to invalid parameters.
  rescue_from ParametersSchema::InvalidParameters do |e|
    # Do something with the exception (ex: log it).

    # Render the response.
    render json: ..., status: :bad_request
  end
```

Now in any controller where you want to validate the parameters, you can do:
``` ruby
def operation
    validated_params = validate_params do
      # ...
    end
    # ...
end
```

## Options

Options can be specified on the module `ParametersSchema::Options`. Example:

``` ruby
ParametersSchema::Options.skip_parameters = [:internal_stuff]
```

Available options:
* `skip_parameters` an array of first-level parameters to skip. Default: `[:controller, :action, :format]`.
* `empty_keyword` the keyword used to represent an empty value. Default: `:empty`.
* `any_keyword` the keyword used to represent any value. Default: `:any`.
* `none_keyword` the keyword used to represent no value. Default: `:none`.
* `boolean_keyword` the keyword used to represent a boolean value. Default: `:boolean`.
* `nil_keyword` the keyword used to represent a nil value. Default: `:nil`.
* `boolean_true_values` the accepted boolean true values. Not case-sensitive. Default: `true`, `'t'`, `'true'`, `'1'`, `1`, `1.0`.
* `boolean_false_values` the accepted boolean false values. Not case-sensitive. Default: `false`, `'f'`, `'false'`, `'0'`, `0`, `0.0`.

## Contribute

Yes, please. Bug fixes, new features, refactoring, unit tests. Send your precious pull requests.

### Ideas

* Array of arrays of ...
* Min/Max for numeric values
* More `allow` options
* Better refine error codes

## License

Parameters Schema is released under the [MIT License](http://www.opensource.org/licenses/MIT).
