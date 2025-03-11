
LUA?=lua5.2

lint:
	luacheck --codes .
	stylua --check .

format:
	stylua .

test:
	cd tests && $(LUA) runtests.lua

.PHONY: test
