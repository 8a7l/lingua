-- book.lua
-- «Невідомі книги» (lingua:coded_book): пишуться однією мовою,
-- читаються залежно від знань. Копії не редагуються.

local S = minetest.get_translator("lingua")

local COPY_MARK = "lingua:is_copy"


local function is_copy(stack)
	return stack:get_meta():get_string(COPY_MARK) == "1"
end


-- ---------------------------------------------------------------------------
-- Показ форми читання
-- ---------------------------------------------------------------------------

local function show_read_form(player, itemstack)
	local pname = player:get_player_name()
	local meta = itemstack:get_meta()

	local text      = meta:get_string("text")
	local lang_name = meta:get_string("lang")
	local title     = meta:get_string("title")
	local author    = meta:get_string("author")

	if text == "" then
		minetest.chat_send_player(pname, "This book is empty.")
		return
	end

	local lang = (lang_name ~= "")
		and lingua.get_language(lang_name) or nil

	local knows = (lang_name ~= "" and lang)
		and lingua.knows(pname, lang_name) or false

	local display_title = (title ~= "") and title or "Untitled"
	local display_text  = text
	local status

	if lang_name == "" then
		status = "No language (plain text)"

	elseif not lang then
		status = "Language '" .. lang_name
			.. "' no longer exists."

	elseif knows then
		status = "Language: " .. lang_name .. " (you know it)"

	else
		status = "Language: " .. lang_name
			.. " (you don't know it — showing encoded)"
		display_text  = lingua.encode(text, lang)
		display_title = lingua.encode(display_title, lang)
	end

	display_text = lingua.decode_marked(display_text, pname)

	local header = display_title
	if author ~= "" then
		header = header .. "  — by " .. author
	end

	if is_copy(itemstack) then
		header = header .. "  (copy — read-only)"
	end

	-- Кнопки внизу (по центру)
	local buttons
	if author == pname and not is_copy(itemstack) then
		-- Edit + Close — обидві по центру групою
		buttons =
			"button[2.8,8.6;2,0.8;edit;Edit]" ..
			"button_exit[5.2,8.6;2,0.8;close;Close]"
	else
		-- тільки Close — по центру
		buttons = "button_exit[4,8.6;2,0.8;close;Close]"
	end

	minetest.show_formspec(pname, "lingua:read_book",
		"size[10,9]" ..
		"label[0.4,0.4;" .. minetest.formspec_escape(header) .. "]" ..
		"label[0.4,0.8;" .. minetest.formspec_escape(status) .. "]" ..
		"textarea[0.4,1.4;9.7,8.4;content;;" ..
			minetest.formspec_escape(display_text) .. "]" ..
		buttons
	)
end


-- ---------------------------------------------------------------------------
-- Показ форми написання (або редагування)
-- ---------------------------------------------------------------------------

local function show_write_form(player, existing)
	local pname = player:get_player_name()
	local langs = lingua.get_known_languages(pname)

	if #langs == 0 then
		minetest.chat_send_player(pname,
			"You don't know any languages. Book will be "
			.. "written as plain text.")
		langs = { "(plain)" }
	end

	local title = ""
	local text  = ""
	local selected_lang = langs[1]

	if existing then
		local meta = existing:get_meta()
		title = meta:get_string("title")
		text  = meta:get_string("text")

		local lang = meta:get_string("lang")
		if lang ~= "" then
			selected_lang = lang
		else
			selected_lang = "(plain)"
		end

		local found = false
		for _, l in ipairs(langs) do
			if l == selected_lang then found = true break end
		end
		if not found then
			table.insert(langs, selected_lang)
		end
	end

	local idx = 1
	for i, l in ipairs(langs) do
		if l == selected_lang then idx = i break end
	end

	local header = existing
		and "Edit unknown book"
		or  "Write an unknown book"

	minetest.show_formspec(pname, "lingua:write_book",
		"size[10,9]" ..
		"label[0.3,0.2;" .. header .. "]" ..

		"field[0.3,0.6;9.4,0.8;title;Title;" ..
			minetest.formspec_escape(title) .. "]" ..

		"label[0.3,1.6;Language:]" ..
		"dropdown[2,1.4;5,0.8;lang;" ..
			table.concat(langs, ",") .. ";" .. idx .. "]" ..

		"label[0.3,2.4;Text:]" ..
		"textarea[0.3,2.8;9.4,5;text;;" ..
			minetest.formspec_escape(text) .. "]" ..

		"button[0.3,8.1;2,0.8;save;Save]" ..
		"button[2.5,8.1;2,0.8;cancel;Close]"
	)
end


-- ---------------------------------------------------------------------------
-- Обробка форми написання
-- ---------------------------------------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "lingua:write_book" then return end

	local pname = player:get_player_name()

	if fields.cancel or fields.quit then
		minetest.close_formspec(pname, "lingua:write_book")
		return
	end

	if fields.save then
		local title = fields.title or ""
		local lang  = fields.lang or ""
		local text  = fields.text or ""

		if lang == "(plain)" then
			lang = ""
		end

		if text == "" then
			minetest.chat_send_player(pname,
				"Cannot save an empty book.")
			return
		end

		if title == "" then
			title = "Untitled"
		end

		local wielded = player:get_wielded_item()

		if wielded:get_name() ~= "lingua:coded_book" then
			minetest.chat_send_player(pname,
				"You must hold an Unknown Book.")
			return
		end

		if is_copy(wielded) then
			minetest.chat_send_player(pname,
				"Copies cannot be edited.")
			return
		end

		local meta = wielded:get_meta()

		local author = meta:get_string("author")
		if author == "" then
			author = pname
		end

		meta:set_string("title", title)
		meta:set_string("text", text)
		meta:set_string("lang", lang)
		meta:set_string("author", author)

		meta:set_string("description", "Unknown Book")

		player:set_wielded_item(wielded)

		minetest.chat_send_player(pname,
			"Book saved: '" .. title .. "'.")
	end
end)


-- ---------------------------------------------------------------------------
-- Обробка форми читання (кнопка Edit)
-- ---------------------------------------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "lingua:read_book" then return end

	if fields.edit then
		local wielded = player:get_wielded_item()

		if wielded:get_name() == "lingua:coded_book" then
			if is_copy(wielded) then
				minetest.chat_send_player(player:get_player_name(),
					"Copies cannot be edited.")
				return
			end
			show_write_form(player, wielded)
		else
			minetest.chat_send_player(player:get_player_name(),
				"Hold the book in your hand to edit it.")
		end
	end
end)


-- ---------------------------------------------------------------------------
-- Предмет
-- ---------------------------------------------------------------------------

minetest.register_craftitem("lingua:coded_book", {
	description = "Unknown Book\n"
		.. "Right-click to read or write.",
	inventory_image = "default_book_written.png",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		local text = meta:get_string("text")

		if is_copy(itemstack) then
			-- Копія лише для читання
			if text == "" then
				minetest.chat_send_player(user:get_player_name(),
					"This is a copy and cannot be written.")
				return itemstack
			end
			show_read_form(user, itemstack)
			return itemstack
		end

		if text == "" then
			show_write_form(user, nil)
		else
			show_read_form(user, itemstack)
		end

		return itemstack
	end,
})


minetest.register_craft({
	output = "lingua:coded_book",
	recipe = {
		{"default:paper", "default:paper"},
		{"default:paper", "default:paper"},
		{"",              "default:book"},
	},
})