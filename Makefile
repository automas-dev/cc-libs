
LUA?=lua5.2

lint:
	luacheck --codes .
	stylua --check .

format:
	stylua .

test:
	cd tests && $(LUA) runtests.lua

test_cov: export COVERAGE=1
test_cov: test

check: format lint test

emulate:
	craftos --mount-ro /cc-libs=cc-libs --mount-ro /cc=cc-apps --mount-rw /logs=logs

.PHONY: lint format test check emulate
