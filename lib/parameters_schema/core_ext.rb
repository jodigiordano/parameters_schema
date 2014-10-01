class Object
  #
  # Check if object is numeric.
  # From http://stackoverflow.com/questions/5661466/test-if-string-is-a-number-in-ruby-on-rails
  #
  # p "1".numeric?        # => true
  # p "1.2".numeric?      # => true
  # p "5.4e-29".numeric?  # => true
  # p "12e20".numeric?    # => true
  # p "1a".numeric?       # => false
  # p "1.2.3.4".numeric?  # => false
  #
  def numeric?
    return true if self.kind_of?(Numeric)
    return true if self.to_s =~ /^\d+$/
    Float(self)
    true
  rescue
    false
  end
end
