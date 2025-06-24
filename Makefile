.PHONY: test
test:
	nvim --headless -c "lua require('plenary.test_harness').test_directory('tests', {minimal_init='tests/minimal_init.vim'})"
