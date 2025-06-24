std = luajit
codes = true

globals = {
    "vim",
}

read_globals = {
    "describe",
    "it",
    "before_each",
    "after_each",
    "assert",
}

exclude_files = {
    "vendor/**/*.lua",
}

ignore = {
    "631",  -- max_line_length, leave to stylua
}