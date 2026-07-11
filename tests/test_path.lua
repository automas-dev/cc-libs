local path = require 'cc-libs.util.path'

local test = {}

function test.path_relative()
    expect_eq('a', path.resolve('a'))
    expect_eq('a', path.resolve('a/'))
    expect_eq('a/b', path.resolve('a/b'))
    expect_eq('a/b', path.resolve('a/b/'))
end

function test.path_relative_cwd()
    expect_eq('/c/a', path.resolve('a', '/c'))
    expect_eq('/c/a', path.resolve('a/', '/c'))
    expect_eq('/c/a/b', path.resolve('a/b', '/c'))
    expect_eq('/c/a/b', path.resolve('a/b/', '/c'))
end

function test.path_relative_cwd_with_slash()
    expect_eq('/c/a', path.resolve('a', '/c/'))
    expect_eq('/c/a', path.resolve('a/', '/c/'))
    expect_eq('/c/a/b', path.resolve('a/b', '/c/'))
    expect_eq('/c/a/b', path.resolve('a/b/', '/c/'))
end

function test.path_absolute()
    expect_eq('/', path.resolve('/'))
    expect_eq('/a', path.resolve('/a'))
    expect_eq('/a', path.resolve('/a/'))
    expect_eq('/a/b', path.resolve('/a/b'))
    expect_eq('/a/b', path.resolve('/a/b/'))
end

function test.path_absolute_cwd()
    expect_eq('/', path.resolve('/', '/c'))
    expect_eq('/a', path.resolve('/a', '/c'))
    expect_eq('/a', path.resolve('/a/', '/c'))
    expect_eq('/a/b', path.resolve('/a/b', '/c'))
    expect_eq('/a/b', path.resolve('/a/b/', '/c'))
end

function test.path_absolute_cwd_with_slash()
    expect_eq('/', path.resolve('/', '/c/'))
    expect_eq('/a', path.resolve('/a', '/c/'))
    expect_eq('/a', path.resolve('/a/', '/c/'))
    expect_eq('/a/b', path.resolve('/a/b', '/c/'))
    expect_eq('/a/b', path.resolve('/a/b/', '/c/'))
end

function test.path_empty()
    expect_eq('', path.resolve(''))
end

function test.path_empty_cwd()
    expect_eq('/c', path.resolve('', '/c'))
end

function test.single_dot_relative()
    expect_eq('', path.resolve('.'))
    expect_eq('', path.resolve('./'))
    expect_eq('a', path.resolve('./a'))
    expect_eq('a', path.resolve('././a'))
    expect_eq('a', path.resolve('./a/.'))
    expect_eq('a', path.resolve('./a/./'))
end

function test.single_dot_absolute()
    expect_eq('/', path.resolve('/.'))
    expect_eq('/', path.resolve('/./.'))
    expect_eq('/a', path.resolve('/./a'))
    expect_eq('/a', path.resolve('/././a'))
    expect_eq('/a', path.resolve('/./a/.'))
    expect_eq('/a', path.resolve('/./a/./'))
end

function test.single_dot_relative_cwd()
    expect_eq('/c', path.resolve('.', '/c'))
    expect_eq('/c', path.resolve('./', '/c'))
    expect_eq('/c/a', path.resolve('./a', '/c'))
    expect_eq('/c/a', path.resolve('././a', '/c'))
    expect_eq('/c/a', path.resolve('./a/.', '/c'))
    expect_eq('/c/a', path.resolve('./a/./', '/c'))
end

function test.single_dot_absolute_cwd()
    expect_eq('/', path.resolve('/.', '/c'))
    expect_eq('/', path.resolve('/./.', '/c'))
    expect_eq('/a', path.resolve('/./a', '/c'))
    expect_eq('/a', path.resolve('/././a', '/c'))
    expect_eq('/a', path.resolve('/./a/.', '/c'))
    expect_eq('/a', path.resolve('/./a/./', '/c'))
end

function test.double_dot_relative()
    expect_eq('..', path.resolve('..'))
    expect_eq('..', path.resolve('../'))
    expect_eq('../a', path.resolve('../a'))
    expect_eq('../../a', path.resolve('../../a'))
    expect_eq('..', path.resolve('../a/..'))
    expect_eq('..', path.resolve('../a/../'))
end

function test.double_dot_absolute()
    expect_eq('/', path.resolve('/..'))
    expect_eq('/', path.resolve('/../..'))
    expect_eq('/a', path.resolve('/../a'))
    expect_eq('/a', path.resolve('/../../a'))
    expect_eq('/', path.resolve('/../a/..'))
    expect_eq('/', path.resolve('/../a/../'))
end

function test.double_dot_relative_cwd()
    expect_eq('/', path.resolve('..', '/c'))
    expect_eq('/', path.resolve('../', '/c'))
    expect_eq('/a', path.resolve('../a', '/c'))
    expect_eq('/a', path.resolve('../../a', '/c'))
    expect_eq('/', path.resolve('../a/..', '/c'))
    expect_eq('/', path.resolve('../a/../', '/c'))
end

function test.double_dot_absolute_cwd()
    expect_eq('/', path.resolve('/..', '/c'))
    expect_eq('/', path.resolve('/../..', '/c'))
    expect_eq('/a', path.resolve('/../a', '/c'))
    expect_eq('/a', path.resolve('/../../a', '/c'))
    expect_eq('/', path.resolve('/../a/..', '/c'))
    expect_eq('/', path.resolve('/../a/../', '/c'))
end

function test.double_slash_relative()
    expect_eq('', path.resolve('.//'))
    expect_eq('a', path.resolve('a//'))
    expect_eq('a/b', path.resolve('a//b'))
end

function test.double_slash_absolute()
    expect_eq('/', path.resolve('///'))
    expect_eq('/a', path.resolve('/a///'))
    expect_eq('/a/b', path.resolve('/a///b'))
end

function test.double_slash_relative_cwd()
    expect_eq('/c', path.resolve('.//', '/c'))
    expect_eq('/c/a', path.resolve('a//', '/c'))
    expect_eq('/c/a/b', path.resolve('a//b', '/c'))
end

function test.double_slash_absolute_cwd()
    expect_eq('/', path.resolve('///', '/c'))
    expect_eq('/a', path.resolve('/a///', '/c'))
    expect_eq('/a/b', path.resolve('/a///b', '/c'))
end

return test
