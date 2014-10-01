module ActiveSupport
  class HashWithIndifferentAccess < Hash
    def must_equal_hash(other)
      self.must_equal(other.with_indifferent_access)
    end
  end
end

module ParametersSchema
  class Schema
    def must_allow(values)
      [values].flatten.each do |value|
        if value.kind_of?(Range)
          value.each do |v|
            execute_must_allow(v)
          end
        else
          execute_must_allow(value)
        end
      end

      self
    end

    def must_deny(values, error_code = ParametersSchema::ErrorCode::DISALLOWED)
      [values].flatten.each do |value|
        if value.kind_of?(Range)
          value.each do |v|
            execute_must_deny(v, error_code)
          end
        else
          execute_must_deny(value, error_code)
        end
      end

      self
    end

    private

    def execute_must_allow(value)
      self
        .validate!(potatoe: value)
        .must_equal_hash(potatoe: value)
    end

    def execute_must_deny(value, error_code)
        Proc.new do
          self
            .validate!(potatoe: value)
        end
          .must_raise(ParametersSchema::InvalidParameters)
          .errors.must_equal_hash(potatoe: error_code)
    end
  end
end
