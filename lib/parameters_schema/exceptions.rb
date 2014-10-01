module ParametersSchema
  module ErrorCode
    unless defined? UNKNOWN # Make sure we don't redefine the constants twice.
      UNKNOWN = :unknown
      MISSING = :missing
      NIL = :nil
      EMPTY = :empty
      DISALLOWED = :disallowed
    end
  end

  class InvalidParameters < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end

    def message
      @errors.to_s
    end
  end
end
