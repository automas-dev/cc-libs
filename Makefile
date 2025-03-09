
LUA?=lua

lint:
	luacheck --codes .
	stylua --check .

format:
	stylua .

test:
	cd tests && $(LUA) runtests.lua

.PHONY: test
