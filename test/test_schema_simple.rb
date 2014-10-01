require 'minitest/autorun'
require 'parameters_schema'
require_relative 'helpers'

describe 'Empty schema' do
  before do
    ParametersSchema::Options.reset_defaults
    @schema = ParametersSchema::Schema.new do end
  end

  it 'accepts nil params' do
    @schema
      .validate!(nil)
      .must_equal_hash({})
  end

  it 'accepts empty params' do
    @schema
      .validate!({})
      .must_equal_hash({})
  end

  it 'wont accept non-empty params' do
    Proc
      .new{ @schema.validate!(potatoe: 'Eramosa') }
      .must_raise(ParametersSchema::InvalidParameters)
      .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::UNKNOWN)
  end
end

describe 'Simple schema' do
  before do
    @schema = ParametersSchema::Schema.new do
      param :potatoe
    end
  end

  it 'accepts string or symbol keys' do
    ['potatoe', :potatoe].each do |key|
      @schema
        .validate!(key => 'Eramosa')
        .must_equal_hash(key => 'Eramosa')
    end
  end

  it 'validates a valid input' do
    @schema
      .validate!(potatoe: 'Eramosa')
      .must_equal_hash(potatoe: 'Eramosa')
  end

  it 'validates an invalid input because of a missing key' do
    exception = Proc
      .new{ @schema.validate!({}) }
      .must_raise(ParametersSchema::InvalidParameters)
      .errors.must_equal_hash(potatoe: :missing)
  end
end
