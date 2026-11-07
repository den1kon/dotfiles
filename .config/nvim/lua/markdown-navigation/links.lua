-- Finding and resolving Markdown links. Everything here is a pure function of
-- a line of text and a file path; opening files is the caller's job.
local M = {}

local MARKDOWN_LINK = "%[[^%]]+%]%(([^%)%]]*)%)"
local WIKILINK = "%[%[([^|%]]+)[^%]]*%]%]"

-- Characters a filename may not contain (the strictest platform rules).
local FORBIDDEN_FILENAME_CHARS = '[<>:"|?*]'
local INVALID_FILENAME_ENDING = "[%s%.]$"

---@class MarkdownLinkSearch
---@field down integer Levels of subdirectories searched below the file's directory
---@field up integer Levels of parent directories searched above it

---@type MarkdownLinkSearch
M.default_search = { down = 1, up = 1 }

---@alias MarkdownLinkKind "markdown"|"wikilink"

---@class MarkdownLink
---@field start integer 1-based column of the first character
---@field finish integer 1-based column of the last character
---@field target string The path part: `x.md` in `[text](x.md)` and `[[x.md|text]]`
---@field kind MarkdownLinkKind

---@param line string
---@param pattern string
---@param kind MarkdownLinkKind
---@param found MarkdownLink[]
local function collect(line, pattern, kind, found)
	local position = 1
	while true do
		local start, finish, target = line:find(pattern, position)
		if not start then
			return
		end
		table.insert(found, { start = start, finish = finish, target = target, kind = kind })
		position = finish + 1
	end
end

---All links on the line, in order of appearance.
---@param line string
---@return MarkdownLink[]
function M.find(line)
	local found = {}
	collect(line, MARKDOWN_LINK, "markdown", found)
	collect(line, WIKILINK, "wikilink", found)
	table.sort(found, function(first, second)
		return first.start < second.start
	end)
	return found
end

---The link covering a 1-based column of the line.
---@param line string
---@param column integer
---@return MarkdownLink|nil link
---@return string|nil err
function M.at_column(line, column)
	local links = M.find(line)
	if #links == 0 then
		return nil, "No links found on this line."
	end

	for _, link in ipairs(links) do
		if column >= link.start and column <= link.finish then
			return link, nil
		end
	end
	return nil, "No link found at the cursor."
end

---@param path string
---@return boolean
local function is_file(path)
	local stat = vim.uv.fs_stat(path)
	return stat ~= nil and stat.type == "file"
end

---Visible subdirectories of `directory`, in name order.
---@param directory string
---@return string[]
local function subdirectories(directory)
	local found = {}
	if vim.fn.isdirectory(directory) == 1 then
		for name, kind in vim.fs.dir(directory) do
			if kind == "directory" and not vim.startswith(name, ".") then
				table.insert(found, vim.fs.joinpath(directory, name))
			end
		end
	end
	table.sort(found)
	return found
end

---Where a flat wikilink may live, in the order they are tried: the file's own
---directory, then `down` levels of subdirectories (nearest level first), then
---`up` parent directories (nearest first). Siblings of the file's directory are
---not searched.
---@param directory string
---@param search MarkdownLinkSearch
---@return string[]
function M.search_directories(directory, search)
	local directories = { directory }

	local level = { directory }
	for _ = 1, search.down do
		local deeper = {}
		for _, parent in ipairs(level) do
			vim.list_extend(deeper, subdirectories(parent))
		end
		vim.list_extend(directories, deeper)
		level = deeper
	end

	local ancestor = directory
	for _ = 1, search.up do
		local parent = vim.fs.dirname(ancestor)
		if parent == ancestor then
			break
		end
		table.insert(directories, parent)
		ancestor = parent
	end
	return directories
end

---Turns a link into an absolute path.
---
---A markdown link is relative to the directory of `current_file` or absolute.
---A wikilink without an extension gets `.md`, and a relative one is searched
---for in nearby directories (see search_directories); when nothing is found it
---points to a new note next to `current_file`.
---@param link MarkdownLink
---@param current_file string Path of the file that contains the link
---@param search? MarkdownLinkSearch Defaults to one level down and one up
---@return string|nil path
---@return string|nil err
function M.resolve(link, current_file, search)
	local target = link.target
	if target == nil or target == "" then
		return nil, "Link target is empty."
	end

	local filename = vim.fn.fnamemodify(target, ":t")
	if filename == "" then
		return nil, "Link has no filename."
	end
	if filename:match(FORBIDDEN_FILENAME_CHARS) then
		return nil, "Filename contains forbidden characters."
	end
	if filename:match(INVALID_FILENAME_ENDING) then
		return nil, "Filename cannot end with a space or dot."
	end

	if link.kind == "wikilink" and vim.fn.fnamemodify(target, ":e") == "" then
		target = target .. ".md"
	end

	local function normalized(path)
		return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"), { expand_env = false })
	end

	if vim.fn.fnamemodify(target, ":p") == target then
		return normalized(target), nil
	end

	local directory = vim.fn.fnamemodify(current_file, ":p:h")
	if link.kind == "wikilink" then
		for _, candidate_directory in ipairs(M.search_directories(directory, search or M.default_search)) do
			local candidate = normalized(vim.fs.joinpath(candidate_directory, target))
			if is_file(candidate) then
				return candidate, nil
			end
		end
	end
	return normalized(vim.fs.joinpath(directory, target)), nil
end

return M
