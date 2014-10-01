require 'minitest/autorun'
require 'parameters_schema'
require_relative 'helpers'

describe 'Required' do
  before do
    ParametersSchema::Options.reset_defaults
  end
  
  it 'is required by default' do
    Proc.new do
      ParametersSchema::Schema.new do
        param :potatoe
      end.validate!({})
    end
      .must_raise(ParametersSchema::InvalidParameters)
      .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::MISSING)
  end

  it 'can be explicitly stated as required' do
    Proc.new do
      ParametersSchema::Schema.new do
        param :potatoe, required: true
      end.validate!({})
    end
      .must_raise(ParametersSchema::InvalidParameters)
      .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::MISSING)
  end

  it 'can be set to be not required' do
    ParametersSchema::Schema.new do
      param :potatoe, required: false
    end
      .validate!({})
      .must_equal_hash({})
  end

  it 'applies to object params - validation successful' do
    ParametersSchema::Schema.new do
      param :potatoe do
        param :name
        param :type, required: false
      end
    end
      .validate!(potatoe: { name: 'Eramosa' })
      .must_equal_hash(potatoe: { name: 'Eramosa' })
  end

  it 'applies to object params - validation failed on name' do
    Proc.new do
      ParametersSchema::Schema.new do
        param :potatoe do
          param :name
          param :type, required: false
        end
      end.validate!(potatoe: {})
    end
      .must_raise(ParametersSchema::InvalidParameters)
      .errors.must_equal_hash(potatoe: { name: ParametersSchema::ErrorCode::MISSING })
  end

  it 'applies to object params - validation failed on potatoe' do
    Proc.new do
      ParametersSchema::Schema.new do
        param :potatoe do
          param :name
          param :type, required: false
        end
      end.validate!({})
    end
      .must_raise(ParametersSchema::InvalidParameters)
      .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::MISSING)
  end
end
