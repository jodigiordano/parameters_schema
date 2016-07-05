require 'minitest/autorun'
require 'parameters_schema'
require_relative 'helpers'

describe 'Default value' do
  before do
    ParametersSchema::Options.reset_defaults
  end

  it 'doesnt keep the parameter when not explicitly set to nil' do
    ParametersSchema::Schema.new do
      param :potatoe, required: false
    end
      .validate!({})
      .must_equal_hash({})
  end

  it 'keeps the parameter when explicitly set to nil' do
    ParametersSchema::Schema.new do
      param :potatoe, default: nil
    end
      .validate!({})
      .must_equal_hash({ potatoe: nil })
  end

  it 'must be set to a value of the same type' do
    ParametersSchema::Schema.new do
      param :potatoe, default: 'Eramosa'
    end
      .validate!({})
      .must_equal_hash({ potatoe: 'Eramosa' })

    Proc.new do
      ParametersSchema::Schema.new do
        param :potatoe, type: Fixnum, default: 'Eramosa'
      end
        .validate!({})
        .must_equal_hash({ potatoe: 'Eramosa' })
    end
      .must_raise(ParametersSchema::InvalidParameters)
      .errors.must_equal_hash(potatoe: ParametersSchema::ErrorCode::DISALLOWED)
  end

  it 'keeps the value provided' do
    ParametersSchema::Schema.new do
      param :potatoe, default: nil
    end
      .validate!(potatoe: 'Eramosa')
      .must_equal_hash({ potatoe: 'Eramosa' })
  end

  it 'works with complex values - array of hashes' do
    ParametersSchema::Schema.new do
      param :potatoes, array: true do
        param :variety, default: 'Eramosa'
        param :origin
      end
    end
      .validate!(potatoes: [{ origin: 'NB' }, { origin: 'Canada' }])
      .must_equal_hash(potatoes: [
        { variety: 'Eramosa', origin: 'NB' },
        { variety: 'Eramosa', origin: 'Canada' }
      ])
  end

  it 'works with complex values - fields of hash' do
    default_value = { variety: 'Eramosa', origin: 'New Brunswick' }

    ParametersSchema::Schema.new do
      param :potatoe do
        param :variety, default: 'Eramosa'
        param :origin, default: 'New Brunswick'
      end
    end
      .validate!(potatoe: { origin: 'Canada' })
      .must_equal_hash(potatoe: { variety: 'Eramosa', origin: 'Canada' })
  end
end
