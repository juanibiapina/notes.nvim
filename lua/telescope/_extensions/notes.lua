local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local M = {}

-- List all markdown notes in the current directory
function M.list_notes(opts)
  opts = opts or {}

  -- List all .md files in the current directory
  local output = vim.fn.systemlist("find . -type f -name '*.md'")
  local notes = vim.tbl_map(function(path)
    -- Strip './' prefix and '.md' suffix to get note title
    local title = path:gsub('^%./', ''):gsub('%.md$', '')
    return title
  end, output)

  pickers
    .new(opts, {
      prompt_title = 'List Notes',
      finder = finders.new_table({
        results = notes,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry,
            ordinal = entry,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          require('notes').notes_open(selection.value)
        end)
        return true
      end,
    })
    :find()
end

-- Find all references to the current note
function M.find_references(opts)
  opts = opts or {}
  local current_note = vim.fn.expand('%:t:r')

  -- Get references using the existing find_references function
  local ok, refs = pcall(require('notes').find_references, current_note)
  if not ok then
    print('Error finding references: ' .. refs)
    return
  end

  if #refs == 0 then
    print("No references found for '" .. current_note .. "'")
    return
  end

  pickers
    .new(opts, {
      prompt_title = 'References to [[' .. current_note .. ']]',
      finder = finders.new_table({
        results = refs,
        entry_maker = function(ref)
          return {
            value = ref,
            display = string.format('%s:%d: %s', ref.file, ref.line, ref.text),
            ordinal = ref.file .. ref.text,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local ref = action_state.get_selected_entry().value
          vim.cmd('edit ' .. ref.file)
          vim.fn.cursor(ref.line, 1)
        end)
        return true
      end,
    })
    :find()
end

return require('telescope').register_extension({
  exports = {
    list_notes = M.list_notes,
    find_references = M.find_references,
  },
})
