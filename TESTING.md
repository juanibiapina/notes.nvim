# Testing Setup

This project uses plenary.nvim for testing instead of Ruby/vimrunner.

## Requirements

- Neovim (any recent version)
- Git (for downloading plenary.nvim)

## Running Tests

The easiest way to run tests:

```bash
make test
```

Or directly:

```bash
./run_tests.sh
```

## Test Structure

- `tests/` - All test files written in Lua
- `tests/minimal_init.lua` - Test initialization
- `tests/helpers.lua` - Test utility functions
- `tests/*_spec.lua` - Individual test files

The test runner automatically downloads plenary.nvim if it's not present.

## Writing Tests

Tests use the plenary.test_harness API:

```lua
describe("feature name", function()
  it("should do something", function()
    -- test code
    assert.are.equal(expected, actual)
  end)
end)
```