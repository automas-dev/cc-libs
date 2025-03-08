
lint:
	luacheck --codes .
	stylua --check .

format:
	stylua .

test:
	cd tests && lua runtests.lua

.PHONY: test
