-- Finding and resolving Markdown links. Everything here is a pure function of
-- a line of text and a file path; opening files is the caller's job.
local M = {}

local MARKDOWN_LINK = "%[[^%]]+%]%(([^%)%]]*)%)"
local WIKILINK = "%[%[([^|%]]+)[^%]]*%]%]"

-- Characters a filename may not contain (the strictest platform rules).
local FORBIDDEN_FILENAME_CHARS = '[<>:"|?*]'
local INVALID_FILENAME_ENDING = "[%s%.]$"

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

---Turns a link into an absolute path. Relative targets are relative to the
---directory of `current_file`, and a wikilink without an extension gets `.md`.
---@param link MarkdownLink
---@param current_file string Path of the file that contains the link
---@return string|nil path
---@return string|nil err
function M.resolve(link, current_file)
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

	local path = target
	if vim.fn.fnamemodify(target, ":p") ~= target then
		local directory = vim.fn.fnamemodify(current_file, ":p:h")
		path = vim.fn.fnamemodify(vim.fs.joinpath(directory, target), ":p")
	end
	return vim.fs.normalize(path, { expand_env = false }), nil
end

return M
