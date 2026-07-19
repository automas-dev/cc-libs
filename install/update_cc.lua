local args = { ... }

-- Pass args so version tag can be set for both
shell.run('install_cc-libs', table.unpack(args))
shell.run('install_cc-apps', table.unpack(args))
