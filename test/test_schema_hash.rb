require 'minitest/autorun'
require 'parameters_schema'
require_relative 'helpers'

describe 'Object' do
  it 'creates a sub-schema for objects' do
    ParametersSchema::Schema.new do
      param :potatoe do
        param :name
      end
    end
      .must_allow({ name: 'Eramosa' })
  end

  it 'creates a as many sub-schemas as needed' do
    schema = ParametersSchema::Schema.new do
      param :potatoe do
        param :quantity, type: Fixnum
        param :description do
          param :name
          param :local, type: :boolean
        end
      end
    end

    schema
      .validate!(potatoe: { quantity: '10', description: { name: 'Eramosa', local: 't' } })
      .must_equal_hash(potatoe: { quantity: 10, description: { name: 'Eramosa', local: true } })
  end

  it 'allows an empty sub-schema' do
    schema = ParametersSchema::Schema.new do
      param :potatoe do end
    end
      .must_deny(nil, ParametersSchema::ErrorCode::NIL)
      .must_deny({}, ParametersSchema::ErrorCode::EMPTY)

    Proc
      .new{ schema.validate!(potatoe: { name: 'Eramosa' }) }
      .must_raise(ParametersSchema::InvalidParameters)
      .errors.must_equal_hash(potatoe: { name: ParametersSchema::ErrorCode::UNKNOWN })
  end

  it 'can be embeded in array' do
    [{ array: true}, type: { Array => Hash }].each do |array_format|
      schema = ParametersSchema::Schema.new do
        param :potatoes, array_format do
          param :name
        end
      end

      schema
        .validate!(potatoes: [{ name: 'Ac Belmont' }, { name: 'Eramosa' }])
        .must_equal_hash(potatoes: [{ name: 'Ac Belmont' }, { name: 'Eramosa' }])
    end
  end

  it 'can be embeded in array - complex' do
    schema = ParametersSchema::Schema.new do
      param :potatoes, array: true do
        param :quantity, type: Fixnum
        param :description do
          param :name
          param :local, type: :boolean
        end
      end
    end

    potatoes = [
      {
        quantity: 10,
        description: {
          name: 'Eramosa',
          local: true
        }
      },
      {
        quantity: 1000,
        description: {
          name: 'Eramosa II',
          local: false
        }
      }
    ]

    schema
      .validate!(potatoes: potatoes)
      .must_equal_hash(potatoes: potatoes)
  end
end
