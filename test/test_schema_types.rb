require 'minitest/autorun'
require 'parameters_schema'
require_relative 'helpers'

describe 'Types' do
  describe String do
    before do
      ParametersSchema::Options.reset_defaults

      @schema = ParametersSchema::Schema.new do
        param :potatoe, type: String
      end
    end

    it 'allow this type' do
      @schema
        .validate!(potatoe: 'Eramosa')
        .must_equal_hash(potatoe: 'Eramosa')
    end

    it 'allow a Symbol value' do
      @schema
        .validate!(potatoe: :eramosa)
        .must_equal_hash(potatoe: 'eramosa')
    end

    it 'wont allow other values (no implicit conversion with #to_s)' do
      [true, 1, 1.0, Date.today, DateTime.now, [1], { nope: true }].each do |value|
        Proc
          .new{ @schema.validate!(potatoe: value) }
          .must_raise(ParametersSchema::InvalidParameters)
          .errors.must_equal_hash(potatoe: :disallowed)
      end
    end

    it 'must have a value' do
      Proc
        .new{ @schema.validate!(potatoe: nil) }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::NIL)

      Proc
        .new{ @schema.validate!(potatoe: '') }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::EMPTY)
    end
  end

  describe Symbol do
    before do
      ParametersSchema::Options.reset_defaults

      @schema = ParametersSchema::Schema.new do
        param :potatoe, type: Symbol
      end
    end

    it 'allow this type' do
      @schema
        .validate!(potatoe: :eramosa)
        .must_equal_hash(potatoe: :eramosa)
    end

    it 'allow a String value' do
      @schema
        .validate!(potatoe: 'eramosa')
        .must_equal_hash(potatoe: :eramosa)
    end

    it 'wont allow other values' do
      [true, 1, 1.0, Date.today, DateTime.now, [1], { nope: true }].each do |value|
        Proc
          .new{ @schema.validate!(potatoe: value) }
          .must_raise(ParametersSchema::InvalidParameters)
          .errors.must_equal_hash(potatoe: :disallowed)
      end
    end

    it 'must have a value' do
      Proc
        .new{ @schema.validate!(potatoe: nil) }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::NIL)

      Proc
        .new{ @schema.validate!(potatoe: :'') }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::EMPTY)
    end
  end

  describe Fixnum do
    before do
      ParametersSchema::Options.reset_defaults

      @schema = ParametersSchema::Schema.new do
        param :potatoe, type: Fixnum
      end
    end

    it 'allow this type' do
      @schema
        .validate!(potatoe: 1)
        .must_equal_hash(potatoe: 1)
    end

    it 'allow a String value' do
      @schema
        .validate!(potatoe: '2')
        .must_equal_hash(potatoe: 2)
    end

    it 'allow a Float value' do
      @schema
        .validate!(potatoe: 2.1)
        .must_equal_hash(potatoe: 2)
    end

    it 'allow a String value representing a Float value' do
      @schema
        .validate!(potatoe: '2.1')
        .must_equal_hash(potatoe: 2)
    end

    it 'wont allow other values' do
      [true, '1a', '1.2.3.4', Date.today, DateTime.now, [1], { nope: true }].each do |value|
        Proc
          .new{ @schema.validate!(potatoe: value) }
          .must_raise(ParametersSchema::InvalidParameters)
          .errors.must_equal_hash(potatoe: :disallowed)
      end
    end

    it 'must have a value' do
      Proc
        .new{ @schema.validate!(potatoe: nil) }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::NIL)
    end
  end

  describe Float do
    before do
      ParametersSchema::Options.reset_defaults

      @schema = ParametersSchema::Schema.new do
        param :potatoe, type: Float
      end
    end

    it 'allow this type' do
      @schema
        .validate!(potatoe: 1.0)
        .must_equal_hash(potatoe: 1.0)
    end

    it 'allow a String value' do
      @schema
        .validate!(potatoe: '1.2')
        .must_equal_hash(potatoe: 1.2)
    end

    it 'allow a Fixnum value' do
      @schema
        .validate!(potatoe: 3)
        .must_equal_hash(potatoe: 3.0)
    end

    it 'allow a String value representing a Fixnum value' do
      @schema
        .validate!(potatoe: '3')
        .must_equal_hash(potatoe: 3)
    end

    it 'wont allow other values' do
      [true, '1a', '1.2.3.4', Date.today, DateTime.now, [1], { nope: true }].each do |value|
        Proc
          .new{ @schema.validate!(potatoe: value) }
          .must_raise(ParametersSchema::InvalidParameters)
          .errors.must_equal_hash(potatoe: :disallowed)
      end
    end

    it 'must have a value' do
      Proc
        .new{ @schema.validate!(potatoe: nil) }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::NIL)
    end
  end

  describe :boolean do
    before do
      ParametersSchema::Options.reset_defaults

      @schema = ParametersSchema::Schema.new do
        param :potatoe, type: :boolean
      end
    end

    it 'allow this type' do
      (ParametersSchema::Options.boolean_true_values + ParametersSchema::Options.boolean_false_values).each do |value|
        @schema
          .validate!(potatoe: value)
          .must_equal_hash(potatoe: ParametersSchema::Options.boolean_true_values.include?(value))
      end
    end

    it 'is not case-sensitive' do
      %w(t T true True TRUE tRuE).each do |value|
        @schema
          .validate!(potatoe: value)
          .must_equal_hash(potatoe: true)
      end
    end

    it 'wont allow other values' do
      [2, 1.2, 'whatever', Date.today, DateTime.now, [1], { nope: true }].each do |value|
        Proc
          .new{ @schema.validate!(potatoe: value) }
          .must_raise(ParametersSchema::InvalidParameters)
          .errors.must_equal_hash(potatoe: :disallowed)
      end
    end

    it 'must have a value' do
      Proc
        .new{ @schema.validate!(potatoe: nil) }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::NIL)
    end
  end

  describe :any do
    before do
      ParametersSchema::Options.reset_defaults

      @schema = ParametersSchema::Schema.new do
        param :potatoe, type: :any
      end
    end

    it 'allow this type' do
      [2, 1.2, 'whatever', Date.today, DateTime.now, [1], { nope: true }].each do |value|
        @schema
          .validate!(potatoe: value)
          .must_equal_hash(potatoe: value)
      end
    end

    it 'must have a value' do
      Proc
        .new{ @schema.validate!(potatoe: nil) }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::NIL)
    end
  end

  describe Date do
    before do
      ParametersSchema::Options.reset_defaults

      @schema = ParametersSchema::Schema.new do
        param :potatoe, type: Date
      end
    end

    it 'allow this type' do
      date = Date.today

      @schema
        .validate!(potatoe: date)
        .must_equal_hash(potatoe: date)
    end

    it 'accepts a String using the default format' do
      date = Date.today

      @schema
        .validate!(potatoe: date.to_s)
        .must_equal_hash(potatoe: date)
    end

    it 'accepts a DateTime' do
      datetime = DateTime.now

      @schema
        .validate!(potatoe: datetime)
        .must_equal_hash(potatoe: datetime.to_date)
    end

    it 'accepts a String representing a DateTime' do
      datetime = DateTime.now

      @schema
        .validate!(potatoe: datetime.to_s)
        .must_equal_hash(potatoe: datetime.to_date)
    end

    it 'wont allow other values' do
      [2, 1.2, 'whatever', true, [1], { nope: true }, :lol].each do |value|
        Proc
          .new{ @schema.validate!(potatoe: value) }
          .must_raise(ParametersSchema::InvalidParameters)
          .errors.must_equal_hash(potatoe: :disallowed)
      end
    end

    it 'must have a value' do
      Proc
        .new{ @schema.validate!(potatoe: nil) }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::NIL)
    end
  end

  describe DateTime do
    before do
      ParametersSchema::Options.reset_defaults

      @schema = ParametersSchema::Schema.new do
        param :potatoe, type: DateTime
      end
    end

    it 'allow this type' do
      time = DateTime.now

      @schema
        .validate!(potatoe: time)
        .must_equal_hash(potatoe: time)
    end

    it 'accepts a String using the default format' do
      time = DateTime.now

      @schema
        .validate!(potatoe: time.to_s)
        .must_equal_hash(potatoe: DateTime.parse(time.to_s))
    end

    it 'accepts a Date' do
      date = Date.today

      @schema
        .validate!(potatoe: date)
        .must_equal_hash(potatoe: date.to_datetime)
    end

    it 'accepts a String representing a Date' do
      date = Date.today

      @schema
        .validate!(potatoe: date.to_s)
        .must_equal_hash(potatoe: date.to_datetime)
    end

    it 'wont allow other values' do
      [2, 1.2, 'whatever', true, [1], { nope: true }, :lol].each do |value|
        Proc
          .new{ @schema.validate!(potatoe: value) }
          .must_raise(ParametersSchema::InvalidParameters)
          .errors.must_equal_hash(potatoe: :disallowed)
      end
    end

    it 'must have a value' do
      Proc
        .new{ @schema.validate!(potatoe: nil) }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::NIL)
    end
  end

  describe Hash do
    before do
      ParametersSchema::Options.reset_defaults

      @schema = ParametersSchema::Schema.new do
        param :potatoe, type: Hash
      end
    end

    it 'allow this type' do
      [{ id: 1 }, { id: '1' }, { id: :'1' }, { description: { name: 'Eramosa' } }].each do |value|
        @schema
          .validate!(potatoe: value)
          .must_equal_hash(potatoe: value)
      end
    end

    it 'wont allow other values' do
      [2, 1.2, 'whatever', true, [1], :lol].each do |value|
        Proc
          .new{ @schema.validate!(potatoe: value) }
          .must_raise(ParametersSchema::InvalidParameters)
          .errors.must_equal_hash(potatoe: :disallowed)
      end
    end

    it 'must have a value' do
      Proc
        .new{ @schema.validate!(potatoe: nil) }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::NIL)

      Proc
        .new{ @schema.validate!(potatoe: '') }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::EMPTY)
    end
  end

  describe Array do
    before do
      ParametersSchema::Options.reset_defaults

      @schema = ParametersSchema::Schema.new do
        param :potatoe, type: Array
      end
    end

    it 'allow this type' do
      [[1], [:a], ['a', 'b', 'c'], [nil], [1, true, 'a', :b]].each do |value|
        @schema
          .validate!(potatoe: value)
          .must_equal_hash(potatoe: value)
      end
    end

    it 'wont allow other values' do
      [2, 1.2, 'whatever', true, { test: 1 }, :lol].each do |value|
        Proc
          .new{ @schema.validate!(potatoe: value) }
          .must_raise(ParametersSchema::InvalidParameters)
          .errors.must_equal_hash(potatoe: :disallowed)
      end
    end

    it 'must have a value' do
      Proc
        .new{ @schema.validate!(potatoe: nil) }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::NIL)

      Proc
        .new{ @schema.validate!(potatoe: []) }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::EMPTY)
    end
  end
end
