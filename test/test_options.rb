require 'minitest/autorun'
require 'parameters_schema'
require_relative 'helpers'

describe 'Skipping parameters' do
  before do
    ParametersSchema::Options.reset_defaults

    @schema = ParametersSchema::Schema.new do
      param :potatoe
    end
  end

  it 'skip default parameters in a Rails context' do
    @schema
      .validate!(potatoe: 'Ac Belmont', controller: 'potatoes', action: 'create', format: 'json')
      .must_equal_hash(potatoe: 'Ac Belmont')
  end

  it 'redefines parameters to skip' do
    ParametersSchema::Options.skip_parameters = [:banana]

    @schema
      .validate!(potatoe: 'Ac Belmont', banana: 'Cavendish')
      .must_equal_hash(potatoe: 'Ac Belmont')

    Proc
      .new{ @schema.validate!(potatoe: 'Ac Belmont', controller: 'potatoes', action: 'create', format: 'json') }
      .must_raise(ParametersSchema::InvalidParameters)
  end

  it 'augments parameters to skip' do
    ParametersSchema::Options.skip_parameters = ParametersSchema::Options.skip_parameters + [:banana]
    @schema
      .validate!(potatoe: 'Ac Belmont', banana: 'Cavendish', controller: 'potatoes', action: 'create', format: 'json')
      .must_equal_hash(potatoe: 'Ac Belmont')
  end
end

describe 'Empty keyword' do
  before do
    ParametersSchema::Options.reset_defaults

    @schema = ParametersSchema::Schema.new do
      param :potatoe, allow: :empty
    end
  end

  it 'uses the default value' do
    ParametersSchema::Schema.new do
      param :potatoe, allow: :empty
    end
      .validate!(potatoe: '')
      .must_equal_hash(potatoe: '')
  end

  it 'redefines the value' do
    ParametersSchema::Options.empty_keyword = :allow_empty

    ParametersSchema::Schema.new do
      param :potatoe, allow: :allow_empty
    end
      .validate!(potatoe: '')
      .must_equal_hash(potatoe: '')

    Proc.new do
      ParametersSchema::Schema.new do
        param :potatoe, allow: :empty
      end.validate!(potatoe: '')
    end
      .must_raise(ParametersSchema::InvalidParameters)
      .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::EMPTY)
  end
end
