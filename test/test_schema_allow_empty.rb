require 'minitest/autorun'
require 'parameters_schema'
require_relative 'helpers'

describe 'Allow empty' do
  before do
    ParametersSchema::Options.reset_defaults
  end

  it 'requires a non-empty value by default' do
    ParametersSchema::Schema.new do
      param :potatoe
    end
      .must_deny('', ParametersSchema::ErrorCode::EMPTY)
  end

  it 'can be set to accept empty value' do
    ParametersSchema::Schema.new do
      param :potatoe, allow: :empty
    end
      .must_allow('')
  end

  it 'when set to accept empty, it still reject nil value' do
    ParametersSchema::Schema.new do
      param :potatoe, allow: :empty
    end
      .must_deny(nil, ParametersSchema::ErrorCode::NIL)
  end
end