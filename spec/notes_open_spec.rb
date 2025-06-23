require "date"
require "tempfile"

RSpec.describe "NotesOpen command" do

  it "exposes a command to jump to a specific file" do
    # when
    vim.command 'NotesOpen file.md'

    # then
    filename = vim.command 'echo @%'
    expect(filename).to eq('file.md')
  end

  it "auto-appends .md extension when only note name is provided" do
    # when
    vim.command 'NotesOpen myNote'

    # then
    filename = vim.command 'echo @%'
    expect(filename).to eq('myNote.md')
  end

  it "creates file with header when file doesn't exist" do
    # given
    temp_file = "temp_test_note"

    # when
    vim.command "NotesOpen #{temp_file}"

    # then
    filename = vim.command 'echo @%'
    expect(filename).to eq("#{temp_file}.md")

    # check file content
    content = vim.command 'echo getline(1)'
    expect(content).to eq("# #{temp_file}")

    # cleanup
    vim.command "call delete('#{temp_file}.md')"
  end

end