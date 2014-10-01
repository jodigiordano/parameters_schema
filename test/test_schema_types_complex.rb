require 'minitest/autorun'
require 'parameters_schema'
require_relative 'helpers'

describe 'Complex types' do
  describe 'Multiple' do
    it 'allows multiple types for a parameter' do
      schema = ParametersSchema::Schema.new do
        param :potatoe, type: [String, :boolean]
      end

      schema
        .validate!(potatoe: 'Eramosa')
        .must_equal_hash(potatoe: 'Eramosa')

      schema
        .validate!(potatoe: true)
        .must_equal_hash(potatoe: true)

      [2, 3.0, Date.today, DateTime.now, [1], { nope: true }].each do |value|
        Proc
          .new{ schema.validate!(potatoe: value) }
          .must_raise(ParametersSchema::InvalidParameters)
          .errors.must_equal_hash(potatoe: :disallowed)
      end
    end

    it 'is swallowed by the :any keyword' do
      schema = ParametersSchema::Schema.new do
        param :potatoe, type: [String, :any]
      end

      [1, 1.0, Date.today, DateTime.now, [1], { nope: true }, 'Eramosa', true].each do |value|
        schema
          .validate!(potatoe: value)
          .must_equal_hash(potatoe: value)
      end
    end
  end

  describe 'Array of something' do
    it 'allows the type' do
      schema = ParametersSchema::Schema.new do
        param :potatoe, type: { Array => String }
      end

      schema
        .validate!(potatoe: ['Eramosa', 'Kennebec', 'Conestoga'])
        .must_equal_hash(potatoe: ['Eramosa', 'Kennebec', 'Conestoga'])

      [2, 3.0, Date.today, DateTime.now, [1], { nope: true }, [true, false, true]].each do |value|
        Proc
          .new{ schema.validate!(potatoe: value) }
          .must_raise(ParametersSchema::InvalidParameters)
          .errors.must_equal_hash(potatoe: :disallowed)
      end
    end

    it 'requires all values to be of the same type by default' do
      schema = ParametersSchema::Schema.new do
        param :potatoe, type: { Array => :boolean }
      end

      schema
        .validate!(potatoe: [true, false, false, true])
        .must_equal_hash(potatoe: [true, false, false, true])

      Proc
        .new{ schema.validate!(potatoe: [true, false, false, 4]) }
        .must_raise(ParametersSchema::InvalidParameters)
        .errors.must_equal_hash(potatoe: :disallowed)
    end

    it 'accepts multiple values' do
      schema = ParametersSchema::Schema.new do
        param :potatoe, type: { Array => [:boolean, Fixnum, Symbol] }
      end

      schema
        .validate!(potatoe: [true, 2, :working, false, 2, :still_working])
        .must_equal_hash(potatoe: [true, 2, :working, false, 2, :still_working])
    end

    it 'accepts an array of arrays of :any' do
      schema = ParametersSchema::Schema.new do
        param :potatoe, type: { Array => Array }
      end

      schema
        .validate!(potatoe: [[1, 2], [true, false], ['a', 'b', 'c'], [{ name: 'Eramosa' }]])
        .must_equal_hash(potatoe: [[1, 2], [true, false], ['a', 'b', 'c'], [{ name: 'Eramosa' }]])
    end

    it 'accepts an array of arrays' do
      schema = ParametersSchema::Schema.new do
        param :potatoe, type: { Array => { Array => Fixnum } }
      end

      schema
        .validate!(potatoe: [[1, 2], [3, 4, 5], [6, 7]])
        .must_equal_hash(potatoe: [[1, 2], [3, 4, 5], [6, 7]])
    end

    it 'can be used in conjunction with array: true' do
      schema = ParametersSchema::Schema.new do
        param :potatoe, type: { Array => :boolean }, array: true
      end

      schema
        .validate!(potatoe: [true, true, false])
        .must_equal_hash(potatoe: [true, true, false])
    end

    it 'doesnt make sense for any other type so fallback to the key' do
      schema = ParametersSchema::Schema.new do
        param :potatoe, type: { Date => Fixnum }
      end

      today = Date.today

      schema
        .validate!(potatoe: today)
        .must_equal_hash(potatoe: today)
    end
  end
end
