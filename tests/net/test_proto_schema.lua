local model = require 'cc-libs.net.proto.schema'
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
            g = { type = FieldType.UNION, types = { { type = FieldType.STRING } } },
            h = { type = FieldType.ANY },
        })
    end))
end

-- TODO test object, key and types fields with ARRAY in check
-- TODO test types fields with OBJECT in check
-- TODO test object, key and value fields with UNION in check

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
            a = { type = FieldType.ARRAY, value = { type = FieldType.INTEGER } },
        })
    end))
end

function test.check_schema_array_invalid()
    expect_false(pcall(function()
        Schema:new({
            ---@diagnostic disable-next-line: assign-type-mismatch
            a = { type = FieldType.ARRAY, value = { type = nil } },
        })
    end))
end

function test.check_schema_array_field()
    expect_false(
        pcall(function()
            Schema:new({
                a = { type = FieldType.INTEGER, value = { type = FieldType.INTEGER } },
            })
        end),
        'not array has value field'
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

function test.check_schema_union()
    expect_true(pcall(function()
        Schema:new({
            a = { type = FieldType.UNION, types = { { type = FieldType.STRING } } },
        })
    end))
end

function test.check_schema_union_no_types()
    expect_false(pcall(function()
        Schema:new({
            a = { type = FieldType.UNION, types = {} },
        })
    end))
end

function test.check_schema_union_missing_types()
    expect_false(pcall(function()
        Schema:new({
            a = { type = FieldType.UNION },
        })
    end))
end

function test.check_schema_union_invalid_type()
    expect_false(pcall(function()
        Schema:new({
            ---@diagnostic disable-next-line: assign-type-mismatch
            a = { type = FieldType.UNION, types = { { type = 'invalid' } } },
        })
    end))
end

function test.check_schema_any()
    expect_true(pcall(function()
        Schema:new({
            a = { type = FieldType.ANY },
        })
    end))
end

function test.check_schema_key_field()
    expect_false(
        pcall(function()
            Schema:new({
                a = { type = FieldType.INTEGER, key = { type = FieldType.INTEGER } },
            })
        end),
        'not object has key field'
    )
end

function test.check_schema_value_field()
    expect_false(
        pcall(function()
            Schema:new({
                a = { type = FieldType.INTEGER, value = { type = FieldType.INTEGER } },
            })
        end),
        'not object has value field'
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
        a = { type = FieldType.ARRAY, value = { type = FieldType.INTEGER } },
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

    valid, _, err = Schema
        :new({
            a = { type = FieldType.OBJECT, key = { type = FieldType.STRING }, value = { type = FieldType.INTEGER } },
        })
        :validate({
            a = { foo = 1 },
        })
    expect_true(valid, err)

    valid, _, err = Schema:new({
        a = { type = FieldType.UNION, types = { { type = FieldType.INTEGER }, { type = FieldType.STRING } } },
    }):validate({
        a = 1,
    })
    expect_true(valid, err)

    valid, _, err = Schema:new({
        a = { type = FieldType.UNION, types = { { type = FieldType.INTEGER }, { type = FieldType.STRING } } },
    }):validate({
        a = 'foo',
    })
    expect_true(valid, err)

    valid, _, err = Schema:new({
        a = { type = FieldType.ANY },
    }):validate({
        a = 'foo',
    })
    expect_true(valid, err)

    valid, _, err = Schema:new({
        a = { type = FieldType.ANY },
    }):validate({
        a = 1,
    })
    expect_true(valid, err)

    valid, _, err = Schema:new({
        a = { type = FieldType.ANY },
    }):validate({
        a = true,
    })
    expect_true(valid, err)

    valid, _, err = Schema:new({
        a = { type = FieldType.ANY },
    }):validate({
        a = {},
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
        a = { type = FieldType.ARRAY, value = { type = FieldType.INTEGER } },
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

function test.validate_object_fails_key_type()
    local valid, error_path, err = Schema:new({
        a = { type = FieldType.OBJECT, key = { type = FieldType.INTEGER } },
    }):validate({
        a = { g = 1 },
    })
    expect_false(valid)
    expect_eq('a.<key>g', error_path)
    expect_eq('Invalid type string expected integer', err)
end

function test.validate_object_fails_value_type()
    local valid, error_path, err = Schema:new({
        a = { type = FieldType.OBJECT, value = { type = FieldType.STRING } },
    }):validate({
        a = { g = 1 },
    })
    expect_false(valid)
    expect_eq('a.g', error_path)
    expect_eq('Invalid type number expected string', err)
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
end

function test.validate_empty_table_is_object()
    local valid, error_path, err = Schema:new({
        a = { type = FieldType.OBJECT },
    }):validate({
        a = {},
    })
    expect_true(valid, err)
end

function test.validate_union_fails_not_type()
    local valid, error_path, err = Schema:new({
        a = { type = FieldType.UNION, types = { { type = FieldType.INTEGER }, { type = FieldType.BOOL } } },
    }):validate({
        a = 'foo',
    })
    expect_false(valid)
    expect_eq('a', error_path)
    expect_eq('No type matched from union types integer, bool', err)
end

function test.validate_nil_fails_any()
    local valid, error_path, err = Schema:new({
        a = { type = FieldType.ANY },
    }):validate({
        a = nil,
    })
    expect_false(valid)
    expect_eq('a', error_path)
    expect_eq('Missing required field', err)
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
