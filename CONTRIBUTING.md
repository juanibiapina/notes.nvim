# Contributing Guide

This guide outlines the development practices and coding standards for this project.

## Development Practices

### Test-Driven Development (TDD)

**TDD should always be used** when developing new features or fixing bugs. Follow this cycle:

1. **Red**: Write a failing test first
2. **Green**: Write the minimal code to make the test pass
3. **Refactor**: Improve the code while keeping tests passing

All new functionality must have corresponding tests before implementation.

### Code Quality Standards

- Always run `make ci` before committing and fix any issues
- Functions should be small and focused on a single responsibility. If a function is doing too many things, break it down into smaller, more focused functions.

#### Same Level of Abstraction

All parts of a function should operate at the same level of abstraction. A good example from this codebase is the `magic` function:

```lua
function M.magic()
  if handle_obsidian_link() then
    return
  end

  if handle_task_toggle() then
    return
  end

  if handle_list_item() then
    return
  end

  -- Do nothing (no applicable context found)
end
```

This function delegates to three helper functions that each handle a specific type of behavior at the same conceptual level. It doesn't mix high-level orchestration with low-level implementation details.

#### Refactoring Guidelines

- **Refactoring should be done after tests are passing**
- Never refactor and add new functionality at the same time
- Ensure all tests continue to pass after refactoring
- Make small, incremental improvements rather than large rewrites

## Testing

Run tests with:
```bash
make test
```

Run linting with:
```bash
make lint
```

Run CI locally with:
```bash
make ci
