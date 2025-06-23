require "date"
require "tempfile"

RSpec.describe "opening links with a Plug mapping" do

  it "from an obsidian link, one per line" do
    # given
    vim.command 'nmap zz <Plug>NotesOpenCurrent'
    vim.command 'set hidden'
    vim.insert '- This is [[The Target]]'
    vim.normal
    vim.feedkeys 'gg'

    # when
    vim.feedkeys 'zz'

    # then
    filename = vim.command 'echo @%'
    expect(filename).to eq('The Target.md')
  end

  it "from an obsidian link, two per line, not on link" do
    # given
    vim.command 'nmap zz <Plug>NotesOpenCurrent'
    vim.command 'set hidden'
    vim.insert '- a [[The Target]] a [[The Other Target]]'
    vim.normal
    vim.feedkeys 'gg'

    # when
    vim.feedkeys 'zz'

    # then
    filename = vim.command 'echo @%'
    expect(filename).to eq('')
  end

  it "from an obsidian link, two per line, first link" do
    # given
    vim.command 'nmap zz <Plug>NotesOpenCurrent'
    vim.command 'set hidden'
    vim.insert '- a [[The Target]] a [[The Other Target]]'
    vim.normal
    vim.feedkeys 'gglllllll'

    # when
    vim.feedkeys 'zz'

    # then
    filename = vim.command 'echo @%'
    expect(filename).to eq('The Target.md')
  end

  it "from an obsidian link, two per line, second link" do
    # given
    vim.command 'nmap zz <Plug>NotesOpenCurrent'
    vim.command 'set hidden'
    vim.insert '- a [[The Target]] a [[The Other Target]]'
    vim.normal
    vim.feedkeys 'ggllllllllllllllllllllllll'

    # when
    vim.feedkeys 'zz'

    # then
    filename = vim.command 'echo @%'
    expect(filename).to eq('The Other Target.md')
  end

  it "from a list item" do
    # given
    vim.command 'nmap zz <Plug>NotesOpenCurrent'
    vim.command 'set hidden'
    vim.insert '- The Target'
    vim.normal
    vim.feedkeys 'gg'

    # when
    vim.feedkeys 'zz'

    # then
    filename = vim.command 'echo @%'
    expect(filename).to eq('The Target.md')
  end

end