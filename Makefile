.PHONY: test lint ci

test:
	./bin/test

lint:
	luacheck .
	stylua --check .

ci:
	./bin/ci
