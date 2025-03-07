
lint:
	luacheck cc-libs

test:
	cd tests && lua runtests.lua

.PHONY: test
