-- gui.lua
-- Єдине вікно Lingua з вкладками.
-- Editor + Languages + Binder + Help.

local S = minetest.get_translator("lingua")

lingua.gui = {
	state = {},
}


local function get_state(pname)
	local st = lingua.gui.state[pname]
	if not st then
		st = { tab = "editor" }
		lingua.gui.state[pname] = st
	end
	if not st.tab then st.tab = "editor" end
	return st
end


local TABS = {
	{ key = "editor",    label = "Editor" },
	{ key = "languages", label = "Languages" },
	{ key = "binder",    label = "Binder" },
	{ key = "help",      label = "Help" },
}


local function build_tabs(current)
	local parts = {}
	local x = 0.3
	local w = 2.6
	for _, t in ipairs(TABS) do
		local label = S(t.label)
		if current == t.key then
			label = "» " .. label
		end
		parts[#parts + 1] = "button[" .. x .. ",0.55;" .. w
			.. ",0.7;tab_" .. t.key .. ";" .. label .. "]"
		x = x + w + 0.1
	end
	return table.concat(parts)
end


local function tab_title(key)
	for _, t in ipairs(TABS) do
		if t.key == key then return S(t.label) end
	end
	return key
end


local function build_header(st)
	return "size[14,9]" ..
		"label[0.3,0.2;Lingua — " .. tab_title(st.tab) .. "]" ..
		build_tabs(st.tab)
end


local function escape_item(s)
	return (tostring(s):gsub("([\\%;,])", "\\%1"))
end


-- Назви полів textarea з версією.
-- Це потрібно, щоб Luanti перемальовував поле, коли сервер змінює
-- його вміст (інакше після ручного очищення клієнт показує старий
-- текст, поки поле не втратить фокус).
local function field_input(st)
	return "input_" .. (st.input_ver or 1)
end


local function field_output(st)
	return "output_" .. (st.output_ver or 1)
end


-- ---------------------------------------------------------------------------
-- Вкладка: Editor
-- ---------------------------------------------------------------------------

local function build_editor(player, st)
	local pname = player:get_player_name()
	local langs = lingua.get_known_languages(pname)

	local parts = { build_header(st) }

	if #langs == 0 then
		parts[#parts + 1] =
			"label[0.3,2;" ..
				S("You don't know any languages yet.") .. "]" ..
			"label[0.3,2.6;" ..
				S("Create one in the Languages tab.") .. "]" ..
			"button[11.5,8.3;2.2,0.8;close;" .. S("Close") .. "]"
		return table.concat(parts)
	end

	st.lang = st.lang or langs[1]
	st.input = st.input or ""
	st.output = st.output or ""

	local found = false
	for _, l in ipairs(langs) do
		if l == st.lang then found = true break end
	end
	if not found then st.lang = langs[1] end

	local idx = 1
	for i, l in ipairs(langs) do
		if l == st.lang then idx = i break end
	end

	parts[#parts + 1] =
		"label[0.3,1.6;" .. S("Language:") .. "]" ..
		"dropdown[2,1.4;5,0.8;lang;" ..
			table.concat(langs, ",") .. ";" .. idx .. "]" ..

		"label[0.3,2.4;" .. S("Input:") .. "]" ..
		"textarea[0.3,2.8;6.4,5;" .. field_input(st) .. ";;" ..
			minetest.formspec_escape(st.input) .. "]" ..

		"label[7.4,2.4;" .. S("Result:") .. "]" ..
		"textarea[7.4,2.8;6.4,5;" .. field_output(st) .. ";;" ..
			minetest.formspec_escape(st.output) .. "]" ..

		"button[0.3,8.3;2.1,0.8;encode;" .. S("Encode →") .. "]" ..
		"button[2.45,8.3;2.1,0.8;decode;" .. S("Decode →") .. "]" ..
		"button[4.6,8.3;2.1,0.8;swap;" .. S("Swap") .. "]" ..
		"button[6.75,8.3;2.1,0.8;wrap;" .. S("Wrap") .. "]" ..
		"button[8.9,8.3;2.1,0.8;decode_all;" .. S("Decode all") .. "]" ..
		"button[11.5,8.3;2.2,0.8;close;" .. S("Close") .. "]"

	return table.concat(parts)
end


-- ---------------------------------------------------------------------------
-- Вкладка: Languages
-- ---------------------------------------------------------------------------

local function build_languages(player, st)
	local pname = player:get_player_name()
	local all = lingua.list_languages()

	local parts = { build_header(st) }

	parts[#parts + 1] = "label[0.3,1.6;" .. S("Languages:") .. "]"

	if #all == 0 then
		parts[#parts + 1] =
			"label[0.3,2.1;" .. S("No languages yet.") .. "]"
		st.selected = 1
	else
		local items = {}
		for _, lang in ipairs(all) do
			local tag = ""
			if lang.secret then
				tag = tag .. " " .. S("(secret)")
			end
			if lingua.knows(pname, lang.name) then
				tag = tag .. " " .. S("(known)")
			end
			items[#items + 1] = escape_item(
				lang.name .. " — " .. S("by") .. " "
				.. lang.author .. tag
			)
		end

		local selected = st.selected or 1
		if selected < 1 or selected > #items then selected = 1 end
		st.selected = selected

		parts[#parts + 1] =
			"textlist[0.3,2;9.4,3.8;lang_list;" ..
				table.concat(items, ",") .. ";" ..
				selected .. ";false]" ..
			"button[0.3,6.1;2.4,0.8;lang_info;" .. S("Info") .. "]" ..
			"button[2.8,6.1;2.4,0.8;lang_forget;" .. S("Forget") .. "]" ..
			"button[5.3,6.1;2.4,0.8;lang_delete;" .. S("Delete") .. "]"
	end

	st.new_name = st.new_name or ""
	st.new_secret = st.new_secret or false

	parts[#parts + 1] =
		"label[0.3,7.35;" .. S("New language:") .. "]" ..
		"field[2.4,7.5;3.5,0.8;new_name;;" ..
			minetest.formspec_escape(st.new_name) .. "]" ..
		"checkbox[6.1,7.2;new_secret;" .. S("Secret") .. ";" ..
			tostring(st.new_secret) .. "]" ..
		"button[8.0,7.5;2.2,0.8;lang_create;" .. S("Create") .. "]" ..
		"button[11.5,7.5;2.2,0.8;close;" .. S("Close") .. "]"

	return table.concat(parts)
end


-- ---------------------------------------------------------------------------
-- Вкладка: Binder
-- ---------------------------------------------------------------------------

local function hand_description(player)
	local wielded = player:get_wielded_item()
	if not wielded or wielded:is_empty() then
		return S("(empty hand)")
	end
	return wielded:get_name()
end


local function build_binder(player, st)
	local pname = player:get_player_name()
	local langs = lingua.get_known_languages(pname)

	local parts = { build_header(st) }

	parts[#parts + 1] =
		"label[0.3,1.6;" .. S("Bind a dictionary to a language.") .. "]" ..
		"label[0.3,2.1;" ..
			S("Hold a dictionary in your hand, then choose below.") .. "]"

	if #langs == 0 then
		parts[#parts + 1] =
			"label[0.3,3;" ..
				S("You don't know any languages yet.") .. "]" ..
			"button[11.5,8.3;2.2,0.8;close;" .. S("Close") .. "]"
		return table.concat(parts)
	end

	st.binder_lang = st.binder_lang or langs[1]
	local found = false
	for _, l in ipairs(langs) do
		if l == st.binder_lang then found = true break end
	end
	if not found then st.binder_lang = langs[1] end

	local idx = 1
	for i, l in ipairs(langs) do
		if l == st.binder_lang then idx = i break end
	end

	parts[#parts + 1] =
		"label[0.3,3;" .. S("Language:") .. "]" ..
		"dropdown[2,2.8;5,0.8;binder_lang;" ..
			table.concat(langs, ",") .. ";" .. idx .. "]" ..

		"label[0.3,4.2;" ..
			S("In hand:") .. " " ..
			minetest.formspec_escape(hand_description(player)) ..
		"]" ..

		"label[0.3,5;" .. S("Types:") .. "]" ..
		"label[0.9,5.4;" ..
			S("- Dictionary (permanent, reusable)") .. "]" ..
		"label[0.9,5.8;" ..
			S("- One-time Dictionary (single use, for secret languages)") .. "]" ..

		"button[0.3,6.8;4,0.9;binder_bind;" ..
			S("Bind Dictionary") .. "]" ..
		"button[4.6,6.8;4,0.9;binder_bind_once;" ..
			S("Bind One-time") .. "]" ..
		"button[11.5,8.3;2.2,0.8;close;" .. S("Close") .. "]"

	return table.concat(parts)
end


-- ---------------------------------------------------------------------------
-- Вкладка: Help
-- ---------------------------------------------------------------------------

local function build_help(player, st)
	local left = {
		S("Lingua — Help"),
		S("Create your own languages and share them"),
		S("via dictionaries."),
		"",
		S("Editor buttons:"),
		"  " .. S("Encode →") .. "     — " .. S("encode Input"),
		"  " .. S("Decode →") .. "     — " .. S("decode Input"),
		"  " .. S("Swap") .. "         — " .. S("swap Input and Result"),
		"  " .. S("Wrap") .. "         — " .. S("encode + wrap in [lang]...[/lang]"),
		"  " .. S("Decode all") .. "   — " .. S("decode all [lang]...[/lang] markers"),
		"",
		S("Tabs:"),
		"  " .. S("Editor")    .. "    — " .. S("encode / decode"),
		"  " .. S("Languages") .. " — " .. S("create, inspect, forget, delete"),
		"  " .. S("Binder")    .. "    — " .. S("bind dictionary in hand"),
		"  " .. S("Help")      .. "      — " .. S("this page"),
	}

	local right = {
		S("Commands (alternative):"),
		"/lingua gui",
		"/lingua create <name> [secret]",
		"/lingua list",
		"/lingua info <name>",
		"/lingua encode <name> <text>",
		"/lingua decode <name> <text>",
		"/lingua wrap <name> <text>",
		"/lingua decode_all <text>",
		"/lingua bind <name>",
		"/lingua bind_once <name>",
		"/lingua forget <name>",
		"/lingua delete <name>",
	}

	local parts = { build_header(st) }

	local y = 1.5
	for _, line in ipairs(left) do
		parts[#parts + 1] = "label[0.3," .. y .. ";" ..
			minetest.formspec_escape(line) .. "]"
		y = y + 0.4
	end

	y = 1.5
	for _, line in ipairs(right) do
		parts[#parts + 1] = "label[7.4," .. y .. ";" ..
			minetest.formspec_escape(line) .. "]"
		y = y + 0.4
	end

	parts[#parts + 1] =
		"button[11.5,8.3;2.2,0.8;close;" .. S("Close") .. "]"

	return table.concat(parts)
end


-- ---------------------------------------------------------------------------
-- Публічне API
-- ---------------------------------------------------------------------------

function lingua.gui.show(player)
	local pname = player:get_player_name()
	local st = get_state(pname)

	local body
	if st.tab == "help" then
		body = build_help(player, st)
	elseif st.tab == "languages" then
		body = build_languages(player, st)
	elseif st.tab == "binder" then
		body = build_binder(player, st)
	else
		body = build_editor(player, st)
	end

	minetest.show_formspec(pname, "lingua:gui", body)
end


-- ---------------------------------------------------------------------------
-- Дії вкладки Languages
-- ---------------------------------------------------------------------------

local function action_info(player, st)
	local pname = player:get_player_name()
	local all = lingua.list_languages()
	local lang = all[st.selected or 1]
	if not lang then return end

	local lines = {
		S("Language:") .. " " .. lang.name,
		S("Author:") .. " " .. lang.author,
		S("Type:") .. " " .. (lang.secret and S("secret") or S("normal")),
	}

	if lingua.knows(pname, lang.name) then
		local preview = S("Alphabet:") .. " "
		for ch in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do
			preview = preview .. ch .. "=" .. (lang.alphabet[ch] or "?") .. " "
		end
		lines[#lines + 1] = preview
	else
		lines[#lines + 1] = S("You don't know this language.")
	end

	minetest.chat_send_player(pname, table.concat(lines, "\n"))
end


local function action_forget(player, st)
	local pname = player:get_player_name()
	local all = lingua.list_languages()
	local lang = all[st.selected or 1]
	if not lang then return end

	if not lingua.knows(pname, lang.name) then
		minetest.chat_send_player(pname,
			S("You don't know this language."))
		return
	end

	lingua.forget(pname, lang.name)
	minetest.chat_send_player(pname,
		S("You forgot") .. " '" .. lang.name .. "'.")
end


local function action_delete(player, st)
	local pname = player:get_player_name()
	local all = lingua.list_languages()
	local lang = all[st.selected or 1]
	if not lang then return end

	if lang.author ~= pname and not lingua.is_admin(pname) then
		minetest.chat_send_player(pname,
			S("Only the author or an admin can delete a language."))
		return
	end

	lingua.delete_language(lang.name)
	minetest.chat_send_player(pname,
		S("Deleted") .. " '" .. lang.name .. "'.")
end


local function action_create(player, st)
	local pname = player:get_player_name()
	local name = st.new_name or ""

	if name == "" then
		minetest.chat_send_player(pname,
			S("Enter a name for the new language."))
		return
	end

	local lang, err = lingua.create_language(
		name, pname, st.new_secret)

	if not lang then
		minetest.chat_send_player(pname, err)
		return
	end

	lingua.learn(pname, name)

	st.new_name = ""
	st.new_secret = false

	minetest.chat_send_player(pname,
		S("Created language") .. " '" .. name .. "'.")
end


-- ---------------------------------------------------------------------------
-- Дії вкладки Binder
-- ---------------------------------------------------------------------------

local function action_bind(player, st, one_time)
	local pname = player:get_player_name()
	local lname = st.binder_lang
	if not lname then return end

	local lang = lingua.get_language(lname)
	if not lang then
		minetest.chat_send_player(pname, S("Language not found."))
		return
	end

	if not lingua.knows(pname, lname) then
		minetest.chat_send_player(pname,
			S("You don't know this language."))
		return
	end

	local wielded = player:get_wielded_item()
	if not wielded or wielded:is_empty() then
		minetest.chat_send_player(pname,
			S("Hold a dictionary in your hand first."))
		return
	end

	if one_time then
		if lang.secret and lang.author ~= pname then
			minetest.chat_send_player(pname,
				S("Only the author of a secret language can "
				.. "create one-time dictionaries for it."))
			return
		end

		if wielded:get_name() ~= "lingua:dictionary_once" then
			minetest.chat_send_player(pname,
				S("You must hold a One-time Dictionary."))
			return
		end

		local meta = wielded:get_meta()
		meta:set_string("lang", lname)
		meta:set_string("description",
			S("One-time Dictionary:") .. " " .. lname
			.. "\n" .. S("Right-click to learn (single use)"))
		player:set_wielded_item(wielded)

		minetest.chat_send_player(pname,
			S("One-time dictionary bound to") .. " '" .. lname .. "'.")
	else
		if lang.secret then
			minetest.chat_send_player(pname,
				S("Secret language — use Bind One-time."))
			return
		end

		if wielded:get_name() ~= "lingua:dictionary" then
			minetest.chat_send_player(pname,
				S("You must hold a Dictionary."))
			return
		end

		local meta = wielded:get_meta()
		meta:set_string("lang", lname)
		meta:set_string("description",
			S("Dictionary:") .. " " .. lname
			.. "\n" .. S("Right-click to learn"))
		player:set_wielded_item(wielded)

		minetest.chat_send_player(pname,
			S("Dictionary bound to") .. " '" .. lname .. "'.")
	end
end


-- ---------------------------------------------------------------------------
-- Обробка полів
-- ---------------------------------------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "lingua:gui" then return end

	local pname = player:get_player_name()
	local st = lingua.gui.state[pname]
	if not st then return end

	-- Зчитуємо текст із полів за ЇХ ПОТОЧНОЮ версією.
	if st.tab == "editor" then
		local in_name = field_input(st)
		if fields[in_name] ~= nil then
			st.input = fields[in_name]
		end
		-- output не читаємо — це результат сервера.
	end

	if fields.new_name ~= nil then st.new_name = fields.new_name end
	if fields.new_secret ~= nil then
		st.new_secret = (fields.new_secret == "true")
	end
	if fields.binder_lang and fields.binder_lang ~= "" then
		st.binder_lang = fields.binder_lang
	end

	local old_lang = st.lang
	if fields.lang and fields.lang ~= "" then st.lang = fields.lang end

	if fields.close or fields.quit then
		lingua.gui.state[pname] = nil
		minetest.close_formspec(pname, "lingua:gui")
		return
	end

	if fields.tab_editor then
		st.tab = "editor"
		lingua.gui.show(player)
		return
	end
	if fields.tab_languages then
		st.tab = "languages"
		lingua.gui.show(player)
		return
	end
	if fields.tab_binder then
		st.tab = "binder"
		lingua.gui.show(player)
		return
	end
	if fields.tab_help then
		st.tab = "help"
		lingua.gui.show(player)
		return
	end

	-- ----------------------------- Editor -------------------------------
	if st.tab == "editor" then
		if fields.encode then
			local lang = lingua.get_language(st.lang)
			if lang then
				st.output = lingua.encode(st.input or "", lang)
			end
			st.output_ver = (st.output_ver or 1) + 1
			lingua.gui.show(player)
			return
		end

		if fields.decode then
			local lang = lingua.get_language(st.lang)
			if lang then
				st.output = lingua.decode(st.input or "", lang)
			end
			st.output_ver = (st.output_ver or 1) + 1
			lingua.gui.show(player)
			return
		end

		if fields.swap then
			st.input, st.output = st.output, st.input
			st.input_ver  = (st.input_ver  or 1) + 1
			st.output_ver = (st.output_ver or 1) + 1
			lingua.gui.show(player)
			return
		end

		if fields.wrap then
			local lang = lingua.get_language(st.lang)
			if lang then
				local encoded = lingua.encode(st.input or "", lang)
				st.output = lingua.wrap(encoded, st.lang)
			end
			st.output_ver = (st.output_ver or 1) + 1
			lingua.gui.show(player)
			return
		end

		if fields.decode_all then
			local text = st.input or ""
			local markers = lingua.find_markers(text)
			local decoded = lingua.decode_marked(text, pname)

			if #markers == 0 then
				st.output = decoded
				minetest.chat_send_player(pname,
					S("No language markers found in Input."))
			else
				local known = 0
				for _, m in ipairs(markers) do
					if lingua.knows(pname, m.lang) then
						known = known + 1
					end
				end
				st.output = decoded .. "\n\n("
					.. known .. "/" .. #markers
					.. " " .. S("fragments decoded") .. ")"
			end
			st.output_ver = (st.output_ver or 1) + 1
			lingua.gui.show(player)
			return
		end

		if st.lang ~= old_lang then
			lingua.gui.show(player)
			return
		end
	end

	-- ---------------------------- Languages -----------------------------
	if st.tab == "languages" then
		if fields.lang_list then
			local idx = tonumber(fields.lang_list:match(":(%d+)"))
				or tonumber(fields.lang_list)
			if idx then st.selected = idx end
			return
		end

		if fields.lang_info then
			action_info(player, st)
			return
		end

		if fields.lang_forget then
			action_forget(player, st)
			lingua.gui.show(player)
			return
		end

		if fields.lang_delete then
			action_delete(player, st)
			st.selected = 1
			lingua.gui.show(player)
			return
		end

		if fields.lang_create then
			action_create(player, st)
			lingua.gui.show(player)
			return
		end
	end

	-- ----------------------------- Binder -------------------------------
	if st.tab == "binder" then
		if fields.binder_bind then
			action_bind(player, st, false)
			lingua.gui.show(player)
			return
		end

		if fields.binder_bind_once then
			action_bind(player, st, true)
			lingua.gui.show(player)
			return
		end
	end
end)