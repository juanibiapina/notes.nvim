require "date"
require "tempfile"

RSpec.describe "NotesCompleteItem" do
  let(:today) { Time.now.strftime('%Y-%m-%d') }
  let(:daily_directory) { Dir.mktmpdir }
  let(:tempfile_path) { File.join(daily_directory, "#{today}.md") }

  before do
    # Set up the daily directory
    vim.command("let g:notes_done_directory = '#{daily_directory}/'")
  end

  after do
    FileUtils.remove_entry(daily_directory)
  end

  it "moves the current line to daily/YYYY-MM-DD.md" do
    # Given
    vim.command 'nmap zz <Plug>NotesCompleteItem'
    vim.command 'set hidden'
    vim.insert '- Todo item'
    vim.normal
    vim.feedkeys 'gg'

    # When
    vim.feedkeys 'zz'

    # Check if the current line has been deleted
    expect(vim.command('echo getline("1")')).to eq('')

    # Read the contents of the daily file
    daily_file_contents = File.readlines(tempfile_path)

    # Check if the item has been moved to the daily file
    expect(daily_file_contents[0]).to eq("- Todo item\n")
  end

end