module ParametersSchema
  class Schema
    def initialize(&schema)
      @schema = schema
    end

    def validate!(params)
      # Make sure we have params we can work with.
      @params = __prepare_params(params)

      # Parse and validate each param.
      @sanitized_params = []
      instance_eval(&@schema)
      # Serve the params if valid, otherwise throw exception.
      __handle_errors
      __serve
    end

    private

    def param(name, options = {}, &inner_params)
      options[:required] = !options.has_key?(:required) || options[:required].present?

      options[:type] = [options[:type] || String].flatten
      options[:allow] = [options[:allow].present? ? options[:allow] : ParametersSchema::Options.any_keyword].flatten
      options[:deny] = [options[:deny].present? ? options[:deny] : ParametersSchema::Options.none_keyword].flatten

      [ParametersSchema::Options.any_keyword, ParametersSchema::Options.none_keyword].each do |dominant_value|
        [:allow, :deny, :type].each do |key|
          options[key] = [dominant_value] if options[key].include?(dominant_value)
        end
      end

      options[:array] = options[:array] || false
      options[:parent] = options[:parent] || @params

      options[:type].map! do |type|
        # Limit to { key => value }
        if type.kind_of?(Hash) && type.count > 1
          type = { type.first[0] => type.first[1] }
        end

        # Limit to { Array => value }
        if type.kind_of?(Hash) && type.first[0] != Array
          type = type.first[0]
        end

        # Apply :array keyword if not already in the format { Array => value }
        if options.delete(:array) && !type.kind_of?(Hash)
          type = { Array => type }
        end

        # The format...
        #
        #   param :potatoe do
        #     ...
        #   end
        #
        # ... is always an Hash.
        if type.kind_of?(Hash) && inner_params.present?
          type = { Array => Hash }
        elsif inner_params.present?
          type = Hash
        end

        type
      end

      @sanitized_params.push(__validate_param(name, options, inner_params))
    end

    def __prepare_params(params)
      params ||= {}
      params = {} unless params.kind_of?(Hash)
      params = params.clone.with_indifferent_access
      ParametersSchema::Options.skip_parameters.each{ |param| params.delete(param) }
      params
    end

    def __validate_param(name, options, inner_params)
      # Validate the presence of the parameter.
      value, error = __validate_param_presence(name, options)
      return __stop_validation(name, value, error, options) if error || (!options[:required] && value.nil?)

      # Validate nil value.
      value, error = __validate_param_value_nil(value, options)
      return __stop_validation(name, value, error, options) if error || value.nil?

      # Validate empty value (except hash).
      value, error = __validate_param_value_empty(value, options)
      return __stop_validation(name, value, error, options) if error || value.nil?

      # Validate the type of the parameter.
      [options[:type]].flatten.each do |type|
        value, error = __validate_type_and_cast(value, type, options, inner_params)
        break if error.blank?
      end
      return __stop_validation(name, value, error, options) if error || value.nil?

      # Validate the allowed and denied values of the parameter
      unless value.kind_of?(Array) || value.kind_of?(Hash)
        [:allow, :deny].each do |allow_or_deny|
          value, error = __validate_param_value_format(value, options, allow_or_deny)
          return __stop_validation(name, value, error, options) if error || value.nil?
        end
      end

      # Validate empty value for hash.
      # This is done at this point to let the validation emit errors when inner parameters are missing.
      # It is preferable that { key: {} } emit { key: { name: :missing } } than { key: :empty }.
      value, error = __validate_param_value_hash_empty(value, options)
      return __stop_validation(name, value, error, options) if error || value.nil?

      __stop_validation(name, value, error, options)
    end

    def __validate_param_presence(name, options)
      error = nil

      if options[:required] && !options[:parent].has_key?(name)
        error = ParametersSchema::ErrorCode::MISSING
      elsif options[:parent].has_key?(name)
        value = options[:parent][name]
      end

      [value, error]
    end

    def __validate_param_value_nil(value, options)
      error = nil

      if !options[:allow].include?(ParametersSchema::Options.nil_keyword) && value.nil?
        error = ParametersSchema::ErrorCode::NIL
      end

      [value, error]
    end

    def __validate_param_value_empty(value, options)
      error = nil

      if !options[:allow].include?(ParametersSchema::Options.empty_keyword) && !value.kind_of?(Hash) && value.respond_to?(:empty?) && value.empty?
        error = ParametersSchema::ErrorCode::EMPTY
      end

      [value, error]
    end

    def __validate_param_value_hash_empty(value, options)
      error = nil

      if !options[:allow].include?(ParametersSchema::Options.empty_keyword) && value.kind_of?(Hash) && value.empty?
        error = ParametersSchema::ErrorCode::EMPTY
      end

      [value, error]
    end

    def __validate_param_value_format(value, options, allow_or_deny)
      conditions = options[allow_or_deny] - [ParametersSchema::Options.empty_keyword, ParametersSchema::Options.nil_keyword]
      inverse = allow_or_deny == :deny
      accept_all_keyword = inverse ? ParametersSchema::Options.none_keyword : ParametersSchema::Options.any_keyword
      refuse_all_keyword = inverse ? ParametersSchema::Options.any_keyword : ParametersSchema::Options.none_keyword

      return [value, nil] if conditions.include?(accept_all_keyword)
      return [value, ParametersSchema::ErrorCode::DISALLOWED] if conditions.include?(refuse_all_keyword)

      error = nil

      conditions.each do |condition|
        error = nil

        if condition.kind_of?(Range)
          condition_passed = condition.include?(value)
          condition_passed = !condition_passed if inverse
          error = ParametersSchema::ErrorCode::DISALLOWED unless condition_passed
        elsif condition.kind_of?(Regexp) && !value.kind_of?(String)
          error = ParametersSchema::ErrorCode::DISALLOWED
        elsif condition.kind_of?(Regexp) && value.kind_of?(String)
          condition_passed = (condition =~ value).present?
          condition_passed = !condition_passed if inverse
          error = ParametersSchema::ErrorCode::DISALLOWED unless condition_passed
        else
          condition_passed = condition == value
          condition_passed = !condition_passed if inverse
          error = ParametersSchema::ErrorCode::DISALLOWED unless condition_passed
        end

        break if inverse ? error.present? : error.blank?
      end

      [value, error]
    end

    def __validate_type_and_cast(value, type, options, inner_params)
      if type.kind_of?(Hash)
        error = ParametersSchema::ErrorCode::DISALLOWED if !value.kind_of?(Array)
        value, error = __validate_array(value, type.values.first, options, inner_params) unless error
      elsif inner_params.present?
        begin
          inner_schema = ParametersSchema::Schema.new(&inner_params)
          value = inner_schema.validate!(value)
        rescue ParametersSchema::InvalidParameters => e
          error = e.errors
        end
      elsif type == ParametersSchema::Options.boolean_keyword
        value = true if ParametersSchema::Options.boolean_true_values.include?(value.kind_of?(String) ? value.downcase : value)
        value = false if ParametersSchema::Options.boolean_false_values.include?(value.kind_of?(String) ? value.downcase : value)
        error = ParametersSchema::ErrorCode::DISALLOWED if !value.kind_of?(TrueClass) && !value.kind_of?(FalseClass)
      elsif type == Fixnum
        error = ParametersSchema::ErrorCode::DISALLOWED if !value.numeric?
        value = value.to_i if error.blank? # cast to right type.
      elsif type == Float
        error = ParametersSchema::ErrorCode::DISALLOWED if !value.numeric?
        value = value.to_f if error.blank? # cast to right type.
      elsif type == Regexp
        error = ParametersSchema::ErrorCode::DISALLOWED unless value =~ options[:regex]
      elsif type == ParametersSchema::Options.any_keyword
        # No validation required.
      elsif type == ParametersSchema::Options.none_keyword
        # Always fail. Why would you want to do that?
        error = ParametersSchema::ErrorCode::DISALLOWED
      elsif type == String
        error = ParametersSchema::ErrorCode::DISALLOWED unless value.kind_of?(String) || value.kind_of?(Symbol)
        value = value.to_s if error.blank? # cast to right type.
      elsif type == Symbol
        error = ParametersSchema::ErrorCode::DISALLOWED unless value.respond_to?(:to_sym)
        value = value.to_sym if error.blank? # cast to right type.
      elsif type == Date
        begin 
          value = value.kind_of?(String) ? Date.parse(value) : value.to_date
        rescue
          error = ParametersSchema::ErrorCode::DISALLOWED
        end
      elsif type == DateTime
        begin 
          value = value.kind_of?(String) ? DateTime.parse(value) : value.to_datetime
        rescue
          error = ParametersSchema::ErrorCode::DISALLOWED
        end
      else
        error = ParametersSchema::ErrorCode::DISALLOWED if !value.kind_of?(type)
      end

      [value, error]
    end

    def __validate_array(value, type, options, inner_params)
      if !value.kind_of?(Array)
        return [value, ParametersSchema::ErrorCode::DISALLOWED]
      end

      value_opts = {
        required: true,
        type: type,
        parent: { value: nil },
        allow: options[:allow],
        deny: options[:deny]
      }

      value.map! do |v|
        value_opts[:parent][:value] = v
        __validate_param(:value, value_opts, inner_params)
      end

      # For now, take the first error.
      [value.map{ |v| v[:value] }, value.find{ |v| v[:error].present? }.try(:[], :error)]
    end

    def __stop_validation(name, value, error, options)
      { param: name, error: error, value: value, keep_if_nil: options[:allow].include?(ParametersSchema::Options.nil_keyword) }
    end

    def __handle_errors
      errors = @sanitized_params
        .select{ |p| p[:error].present? }
        .each_with_object({}.with_indifferent_access) do |p, h|
          h[p[:param]] = p[:error] == :nested_errors ? p[:value] : p[:error]
        end

      (@params.keys.map(&:to_sym) - @sanitized_params.map{ |p| p[:param] }).each do |extra_param|
        errors[extra_param] = ParametersSchema::ErrorCode::UNKNOWN
      end

      raise ParametersSchema::InvalidParameters.new(errors) if errors.any?
    end

    def __serve
      @sanitized_params
        .reject{ |p| p[:value].nil? && !p[:keep_if_nil] }
        .each_with_object({}.with_indifferent_access) do |p, h|
          h[p[:param]] = p[:value]
        end
    end
  end
end