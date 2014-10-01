require 'minitest/autorun'
require 'parameters_schema'
require_relative 'helpers'

describe 'Allow and Deny' do
  before do
    ParametersSchema::Options.reset_defaults
  end

  it 'allows :any and denies :none by default' do
    [{}, { allow: :any }, { deny: :none }, { allow: :any, deny: :none }].each do |options|
      schema = ParametersSchema::Schema.new do
        param :potatoe, options.merge(type: Fixnum)
      end
        .must_allow((-10..10))
    end
  end

  it 'allows multiple :allow values' do
    schema = ParametersSchema::Schema.new do
      param :potatoe, type: Fixnum, allow: [(1..2), (4..5)]
    end
      .must_allow([1, 2, 4, 5])
      .must_deny(3)
  end

  it 'allows multiple :deny values' do
    schema = ParametersSchema::Schema.new do
      param :potatoe, type: Fixnum, deny: [(1..2), (4..5)]
    end
      .must_allow([-1, 0, 3, 6, 7])
      .must_deny([1, 2, 4, 5])
  end

  it 'gives priority to :any and :none in multiple :allow values' do
    schema = ParametersSchema::Schema.new do
      param :potatoe, type: Fixnum, allow: [(1..2), :any]
    end
      .must_allow((-10..10))

    schema = ParametersSchema::Schema.new do
      param :potatoe, type: Fixnum, allow: [(1..2), :none]
    end
      .must_deny((-10..10))
  end

  it 'gives priority to :any and :none in  multiple :deny values' do
    schema = ParametersSchema::Schema.new do
      param :potatoe, type: Fixnum, deny: [(1..2), :none]
    end
      .must_allow((-10..10))

    schema = ParametersSchema::Schema.new do
      param :potatoe, type: Fixnum, deny: [(1..2), :any]
    end
      .must_deny((-10..10))
  end

  it 'when using an array, the :allow is applied on the array values' do
    schema = ParametersSchema::Schema.new do
      param :potatoe, type: Fixnum, array: true, allow: (1..3)
    end

    schema
      .validate!(potatoe: [1, 2, 3, 2, 1])
      .must_equal_hash(potatoe: [1, 2, 3, 2, 1])

    Proc.new do
      schema.validate!(potatoe: [1, 2, 3, 2, 1, 0])
    end
      .must_raise(ParametersSchema::InvalidParameters)
      .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::DISALLOWED)
  end

  it 'when using an array, the :deny is applied on the array values' do
    schema = ParametersSchema::Schema.new do
      param :potatoe, type: Fixnum, array: true, deny: (1..3)
    end

    schema
      .validate!(potatoe: [-1, 0, 4, 5, 6])
      .must_equal_hash(potatoe: [-1, 0, 4, 5, 6])

    Proc.new do
      schema.validate!(potatoe: [-1, 0, 4, 5, 6, 1])
    end
      .must_raise(ParametersSchema::InvalidParameters)
      .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::DISALLOWED)
  end

  it 'allows a subset of values defined by a range' do
    schema = ParametersSchema::Schema.new do
      param :potatoe, type: Fixnum, allow: (1..10)
    end
      .must_allow((1..10))
      .must_deny(((-10..0).to_a + (11..20).to_a))
  end

  it 'allows a subset of values by choices' do
    schema = ParametersSchema::Schema.new do
      param :potatoe, allow: ['a', 'b', 'c']
    end
      .must_allow(['a', 'b', 'c'])
      .must_deny('d')
  end

  it 'allows a subset of values by regex' do
    schema = ParametersSchema::Schema.new do
      param :potatoe, allow: /^[A-Z]+$/
    end
      .must_allow(['A', 'BB', 'CDE'])
      .must_deny(['a', 'Aa', 'F1'])
  end
end
