require 'minitest/autorun'
require 'parameters_schema'
require_relative 'helpers'

describe 'Allow nil' do
  before do
    ParametersSchema::Options.reset_defaults
    
    @schema = ParametersSchema::Schema.new do
      param :potatoe
    end
  end

  it 'requires a non-nil value by default' do
    ParametersSchema::Schema.new do
      param :potatoe
    end
      .must_deny(nil, ParametersSchema::ErrorCode::NIL)
  end

  it 'can be set to accept nil' do
    ParametersSchema::Schema.new do
      param :potatoe, allow: :nil
    end
      .must_allow(nil)
  end

  it 'when set to accept nil, it still reject empty value' do
    ParametersSchema::Schema.new do
      param :potatoe, allow: :nil
    end
      .must_deny('', ParametersSchema::ErrorCode::EMPTY)
  end
end