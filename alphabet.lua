-- Завантажуємо стан при старті
lingua.languages = lingua.storage.load_languages()
lingua.known     = lingua.storage.load_known()


-- ---------------------------------------------------------------------------
-- Ліміт мов на одного гравця
-- 0 = без ліміту. Адміни (lingua_admin або server) — завжди без ліміту.
-- ---------------------------------------------------------------------------

local cfg_max = minetest.settings:get("lingua_max_languages_per_player")
lingua.MAX_LANGUAGES_PER_PLAYER = (cfg_max and tonumber(cfg_max)) or 3


-- ---------------------------------------------------------------------------
-- UTF-8 helper: розбити рядок на масив символів (codepoint'ів)
-- ---------------------------------------------------------------------------

local function utf8_split(s)
	local chars = {}
	local i = 1

	while i <= #s do
		local b = s:byte(i)
		local len = 1

		if b >= 0xF0 then
			len = 4
		elseif b >= 0xE0 then
			len = 3
		elseif b >= 0xC0 then
			len = 2
		end

		chars[#chars + 1] = s:sub(i, i + len - 1)
		i = i + len
	end

	return chars
end


-- ---------------------------------------------------------------------------
-- Пул символів для заміни
-- ---------------------------------------------------------------------------

local SYMBOL_POOL = utf8_split(
	"!@#$%^&*()_+-=[]{}|;:,.<>?/~`'\"\\" ..
	"αβγδεζηθλμξπσφψω" ..
	"ΑΒΓΔΕΖΘΛΞΠΣΦΨΩ"
)


-- ---------------------------------------------------------------------------
-- Абетка: англійська + українська (тільки малі літери)
-- ---------------------------------------------------------------------------

local LETTERS = utf8_split(
	"abcdefghijklmnopqrstuvwxyz" ..
	"абвгдеєжзиіїйклмнопрстуфхцчшщьюя"
)


-- Генерує випадковий алфавіт
local function generate_alphabet()
	local pool = {}

	for _, c in ipairs(SYMBOL_POOL) do
		pool[#pool + 1] = c
	end

	for i = #pool, 2, -1 do
		local j = math.random(i)
		pool[i], pool[j] = pool[j], pool[i]
	end

	local alphabet = {}

	for i, ch in ipairs(LETTERS) do
		alphabet[ch] = pool[i]
	end

	return alphabet
end


-- Обернений алфавіт
local function make_reverse(alphabet)
	local rev = {}
	for k, v in pairs(alphabet) do
		rev[v] = k
	end
	return rev
end


-- ---------------------------------------------------------------------------
-- Публічне API
-- ---------------------------------------------------------------------------

function lingua.create_language(name, author, secret)
	if not name or name == "" then
		return nil, "Name is required"
	end
	if not name:match("^[%w_]+$") then
		return nil, "Name must be a-z, 0-9 or _"
	end
	if lingua.languages[name] then
		return nil, "Language '" .. name .. "' already exists"
	end

	-- Ліміт мов на гравця
	local max = lingua.MAX_LANGUAGES_PER_PLAYER
	if max and max > 0 then
		if not lingua.is_admin(author) then
			local count = 0
			for _, lang in pairs(lingua.languages) do
				if lang.author == author then
					count = count + 1
				end
			end

			if count >= max then
				return nil, "You have already created "
					.. count .. " language(s) — limit is "
					.. max .. "."
			end
		end
	end

	local alphabet = generate_alphabet()

	lingua.languages[name] = {
		name     = name,
		author   = author,
		created  = os.time(),
		secret   = secret or false,
		alphabet = alphabet,
	}

	lingua.storage.save_languages(lingua.languages)

	return lingua.languages[name]
end


function lingua.delete_language(name)
	if not lingua.languages[name] then
		return false, "Not found"
	end
	lingua.languages[name] = nil
	lingua.storage.save_languages(lingua.languages)
	return true
end


function lingua.get_language(name)
	return lingua.languages[name]
end


function lingua.list_languages()
	local list = {}
	for _, lang in pairs(lingua.languages) do
		table.insert(list, lang)
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end


function lingua.encode(text, lang)
	if not lang then return text end

	local chars = utf8_split(text)
	local out = ""

	for _, ch in ipairs(chars) do
		local code = lang.alphabet[ch]

		if not code and #ch == 1 then
			code = lang.alphabet[ch:lower()]
		end

		if code then
			out = out .. code
		else
			out = out .. ch
		end
	end

	return out
end


function lingua.decode(text, lang)
	if not lang then return text end

	local rev = make_reverse(lang.alphabet)
	local chars = utf8_split(text)
	local out = ""

	for _, ch in ipairs(chars) do
		if rev[ch] then
			out = out .. rev[ch]
		else
			out = out .. ch
		end
	end

	return out
end


function lingua.knows(player_name, lang_name)
	return lingua.known[player_name]
		and lingua.known[player_name][lang_name]
		or false
end


function lingua.learn(player_name, lang_name)
	if not lingua.languages[lang_name] then
		return false, "Language not found"
	end
	lingua.known[player_name] = lingua.known[player_name] or {}
	lingua.known[player_name][lang_name] = true
	lingua.storage.save_known(lingua.known)
	return true
end


function lingua.forget(player_name, lang_name)
	if lingua.known[player_name] then
		lingua.known[player_name][lang_name] = nil
	end
	lingua.storage.save_known(lingua.known)
	return true
end


function lingua.get_known_languages(player_name)
	local list = {}
	for _, lang in ipairs(lingua.list_languages()) do
		if lingua.knows(player_name, lang.name) then
			table.insert(list, lang.name)
		end
	end
	return list
end


-- ---------------------------------------------------------------------------
-- Маркери [lang]...[/lang]
-- ---------------------------------------------------------------------------

function lingua.find_markers(text)
	local list = {}
	for lang, content in text:gmatch("%[([%w_]+)%](.-)%[/%1%]") do
		table.insert(list, { lang = lang, content = content })
	end
	return list
end


function lingua.wrap(text, lang)
	return "[" .. lang .. "]" .. text .. "[/" .. lang .. "]"
end


function lingua.decode_marked(text, player_name)
	return (text:gsub("%[([%w_]+)%](.-)%[/%1%]", function(lang, content)
		if lingua.knows(player_name, lang) then
			local l = lingua.get_language(lang)
			if l then
				return lingua.decode(content, l)
			end
		end
		return "[" .. lang .. "]" .. content .. "[/" .. lang .. "]"
	end))
end