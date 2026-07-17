local model = require 'cc-libs.net.proto.model_validate'
local Schema = model.Schema
local FieldType = model.FieldType

local test = {}

function test.check_schema_types()
    expect_true(pcall(function()
        Schema:new({
            a = { type = FieldType.BOOL },
            b = { type = FieldType.INTEGER },
            c = { type = FieldType.FLOAT },
            d = { type = FieldType.STRING },
            e = { type = FieldType.ARRAY },
            f = { type = FieldType.OBJECT },
        })
    end))
end

function test.check_schema_invalid_type()
    expect_false(pcall(function()
        Schema:new({
            ---@diagnostic disable-next-line: assign-type-mismatch
            a = { type = nil },
        })
    end))
    expect_false(pcall(function()
        Schema:new({
            ---@diagnostic disable-next-line: assign-type-mismatch
            a = { type = 'not a type' },
        })
    end))
end

function test.check_schema_optional_not_bool()
    expect_false(pcall(function()
        Schema:new({
            ---@diagnostic disable-next-line: assign-type-mismatch
            a = { type = FieldType.INTEGER, optional = 'not bool' },
        })
    end))
end

function test.check_schema_validate_not_function()
    expect_false(pcall(function()
        Schema:new({
            ---@diagnostic disable-next-line: assign-type-mismatch
            a = { type = FieldType.INTEGER, validate = 'not function' },
        })
    end))
end

function test.check_schema_array()
    expect_true(
        pcall(function()
            Schema:new({
                a = { type = FieldType.ARRAY },
            })
        end),
        'array type is optional'
    )
    expect_true(pcall(function()
        Schema:new({
            a = { type = FieldType.ARRAY, array = { type = FieldType.INTEGER } },
        })
    end))
end

function test.check_schema_array_invalid()
    expect_false(pcall(function()
        Schema:new({
            ---@diagnostic disable-next-line: assign-type-mismatch
            a = { type = FieldType.ARRAY, array = { type = nil } },
        })
    end))
end

function test.check_schema_array_field()
    expect_false(
        pcall(function()
            Schema:new({
                a = { type = FieldType.INTEGER, array = { type = FieldType.INTEGER } },
            })
        end),
        'not array has array field'
    )
end

function test.check_schema_object()
    expect_true(
        pcall(function()
            Schema:new({
                a = { type = FieldType.OBJECT },
            })
        end),
        'object type is optional'
    )
    expect_true(pcall(function()
        Schema:new({
            a = { type = FieldType.OBJECT, object = {
                b = { type = FieldType.INTEGER },
            } },
        })
    end))
end

function test.check_schema_object_invalid()
    expect_false(pcall(function()
        Schema:new({
            ---@diagnostic disable-next-line: assign-type-mismatch
            a = { type = FieldType.OBJECT, object = { 1 } },
        })
    end))
end

function test.check_schema_object_field()
    expect_false(
        pcall(function()
            Schema:new({
                a = { type = FieldType.INTEGER, object = {} },
            })
        end),
        'not object has object field'
    )
end

function test.validate()
    local valid, _, err = Schema:new({
        a = { type = FieldType.BOOL },
    }):validate({
        a = true,
    })
    expect_true(valid, err)

    valid, _, err = Schema:new({
        a = { type = FieldType.INTEGER },
    }):validate({
        a = 1,
    })
    expect_true(valid, err)

    valid, _, err = Schema:new({
        a = { type = FieldType.FLOAT },
    }):validate({
        a = 1.2,
    })
    expect_true(valid, err)

    valid, _, err = Schema:new({
        a = { type = FieldType.STRING },
    }):validate({
        a = 'foo',
    })
    expect_true(valid, err)

    valid, _, err = Schema:new({
        a = { type = FieldType.ARRAY, array = { type = FieldType.INTEGER } },
    }):validate({
        a = { 1, 2, 3 },
    })
    expect_true(valid, err)

    valid, _, err = Schema:new({
        a = { type = FieldType.OBJECT, object = { g = { type = FieldType.STRING } } },
    }):validate({
        a = { g = 'foo' },
    })
    expect_true(valid, err)
end

function test.validate_optional()
    local valid, _, err = Schema:new({
        a = { type = FieldType.INTEGER, optional = true },
    }):validate({})
    expect_true(valid, err)
end

function test.validate_float_fails_int_type()
    local valid, error_path, err = Schema:new({
        a = { type = FieldType.INTEGER },
    }):validate({
        a = 1.1,
    })
    expect_false(valid)
    expect_eq('a', error_path)
    expect_eq('Invalid type float expected integer', err)
end

function test.validate_int_fails_array()
    local valid, error_path, err = Schema:new({
        a = { type = FieldType.ARRAY },
    }):validate({
        a = 1,
    })
    expect_false(valid)
    expect_eq('a', error_path)
    expect_eq('Invalid type number expected array', err)
end

function test.validate_object_fails_array()
    local valid, error_path, err = Schema:new({
        a = { type = FieldType.ARRAY, array = { type = FieldType.INTEGER } },
    }):validate({
        a = { g = 1 },
    })
    expect_false(valid)
    expect_eq('a', error_path)
    expect_eq('Invalid type object expected array', err)
end

function test.validate_object_fails_array_no_type()
    local valid, error_path, err = Schema:new({
        a = { type = FieldType.ARRAY },
    }):validate({
        a = { g = 1 },
    })
    expect_false(valid)
    expect_eq('a', error_path)
    expect_eq('Invalid type object expected array', err)
end

function test.validate_int_fails_object()
    local valid, error_path, err = Schema:new({
        a = { type = FieldType.OBJECT },
    }):validate({
        a = 1,
    })
    expect_false(valid)
    expect_eq('a', error_path)
    expect_eq('Invalid type number expected object', err)
end

function test.validate_array_fails_object()
    local valid, error_path, err = Schema:new({
        a = { type = FieldType.OBJECT, object = { g = { type = FieldType.INTEGER } } },
    }):validate({
        a = { 1, 2, 3 },
    })
    expect_false(valid)
    expect_eq('a', error_path)
    expect_eq('Invalid type array expected object', err)
end

function test.validate_array_fails_object_no_type()
    local valid, error_path, err = Schema:new({
        a = { type = FieldType.OBJECT },
    }):validate({
        a = { 1, 2, 3 },
    })
    expect_false(valid)
    expect_eq('a', error_path)
    expect_eq('Invalid type array expected object', err)
end

function test.validate_empty_table_is_array()
    local valid, error_path, err = Schema:new({
        a = { type = FieldType.ARRAY },
    }):validate({
        a = {},
    })
    expect_true(valid, err)

    valid, error_path, err = Schema:new({
        a = { type = FieldType.OBJECT },
    }):validate({
        a = {},
    })
    expect_false(valid, err)
    expect_eq('a', error_path)
    expect_eq('Invalid type array expected object', err)
end

function test.validate_type_fails()
    local s = Schema:new({
        a = { type = FieldType.INTEGER },
    })

    local valid, error_path, err = s:validate({ a = 'string' })
    expect_false(valid)
    expect_eq('a', error_path)
    expect_eq(err, 'Invalid type string expected integer')
end

function test.validate_extra_fails()
    local s = Schema:new({
        a = { type = FieldType.INTEGER },
    })

    local valid, error_path, err = s:validate({ a = 1, b = 2 }, false)
    expect_false(valid)
    expect_eq('b', error_path)
    expect_eq(err, 'Unexpected field')
end

function test.validate_nil_fails()
    local s = Schema:new({
        a = { type = FieldType.INTEGER },
    })

    local valid, error_path, err = s:validate(nil)
    expect_false(valid)
    expect_eq('', error_path)
    expect_eq(err, 'Value is not table')
end

return test
