local args = { ... }

-- Pass args so version tag can be set for both
shell.run('install-cc-libs', table.unpack(args))
shell.run('install-cc-apps', table.unpack(args))
