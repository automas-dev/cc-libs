local model = require 'cc-libs.net.proto.model_validate'
local Model = model.Model
local FieldType = model.FieldType

local test = {}

function test.check_schema_types()
    expect_true(pcall(function()
        Model:new({
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
        Model:new({
            ---@diagnostic disable-next-line: assign-type-mismatch
            a = { type = nil },
        })
    end))
    expect_false(pcall(function()
        Model:new({
            ---@diagnostic disable-next-line: assign-type-mismatch
            a = { type = 'not a type' },
        })
    end))
end

function test.check_schema_array()
    expect_true(
        pcall(function()
            Model:new({
                a = { type = FieldType.ARRAY },
            })
        end),
        'array type is optional'
    )
    -- expect_false(pcall(function()
    --     Model:new({
    --         a = { type = FieldType.ARRAY },
    --     })
    -- end))
end

function test.validate_basic()
    local m = Model:new({
        a = { type = FieldType.STRING },
        b = { type = FieldType.INTEGER },
        c = { type = FieldType.FLOAT },
    })

    expect_true(m:validate({
        a = 'one',
        b = 2,
        c = 3.0,
    }))
end

return test
