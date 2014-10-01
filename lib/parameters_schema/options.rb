module ParametersSchema
  module Options
    def self.reset_defaults
      @@skip_parameters = [:controller, :action, :format]
      @@empty_keyword = :empty
      @@any_keyword = :any
      @@none_keyword = :none
      @@boolean_keyword = :boolean
      @@nil_keyword = :nil
      @@boolean_true_values = [true, 't', 'true', '1', 1, 1.0]
      @@boolean_false_values = [false, 'f', 'false', '0', 0, 0.0]
    end

    def self.skip_parameters
      @@skip_parameters
    end

    def self.skip_parameters=(new_value)
      @@skip_parameters = new_value
    end

    def self.empty_keyword
      @@empty_keyword
    end

    def self.empty_keyword=(new_value)
      @@empty_keyword = new_value
    end

    def self.any_keyword
      @@any_keyword
    end

    def self.any_keyword=(new_value)
      @@any_keyword = new_value
    end

    def self.none_keyword
      @@none_keyword
    end

    def self.none_keyword=(new_value)
      @@none_keyword = new_value
    end

    def self.boolean_keyword
      @@boolean_keyword
    end

    def self.boolean_keyword=(new_value)
      @@boolean_keyword = new_value
    end

    def self.nil_keyword
      @@nil_keyword
    end

    def self.nil_keyword=(new_value)
      @@nil_keyword = new_value
    end

    def self.boolean_true_values
      @@boolean_true_values
    end

    def self.boolean_true_values=(new_value)
      @@boolean_true_values = new_value
    end

    def self.boolean_false_values
      @@boolean_false_values
    end

    def self.boolean_false_values=(new_value)
      @@boolean_false_values = new_value
    end

    self.reset_defaults
  end
end