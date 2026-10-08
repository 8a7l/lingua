minetest.register_chatcommand("lingua", {
	params = "<subcommand> [args]",
	description = "Language commands. Try /lingua help",

	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then return false, "Player not found" end

		local cmd, rest = param:match("^(%S+)%s*(.*)$")

		-- -----------------------------------------------------------------
		-- gui
		-- -----------------------------------------------------------------
		if cmd == "gui" then
			lingua.gui.show(player)
			return true
		end

		if not cmd or cmd == "" or cmd == "help" then
			return true,
				"Commands:\n" ..
				"/lingua gui                  - open GUI editor\n" ..
				"/lingua create <name> [secret] - create a language\n" ..
				"/lingua list                 - list all languages\n" ..
				"/lingua info <name>          - info about a language\n" ..
				"/lingua encode <name> <text> - encode text\n" ..
				"/lingua decode <name> <text> - decode text\n" ..
				"/lingua wrap <name> <text>   - encode + wrap in markers\n" ..
				"/lingua decode_all <text>    - decode all markers\n" ..
				"/lingua bind <name>          - bind held dictionary\n" ..
				"/lingua bind_once <name>     - bind held one-time dictionary\n" ..
				"/lingua forget <name>        - forget a language\n" ..
				"/lingua delete <name>        - delete (author or admin)"
		end

		-- -----------------------------------------------------------------
		-- create
		-- -----------------------------------------------------------------
		if cmd == "create" then
			if rest == "" then
				return false,
					"Usage: /lingua create <name> [secret]"
			end

			local lname, flag = rest:match("^(%S+)%s*(%S*)$")
			local secret = (flag == "secret")

			local lang, err = lingua.create_language(lname, name, secret)
			if not lang then return false, err end

			lingua.learn(name, lname)

			if secret then
				return true, "Secret language '" .. lname
					.. "' created.\n"
					.. "Only you can create dictionaries for it."
			end

			return true, "Language '" .. lname .. "' created.\n"
				.. "Try: /lingua encode " .. lname .. " hello"
		end

		-- -----------------------------------------------------------------
		-- list
		-- -----------------------------------------------------------------
		if cmd == "list" then
			local list = lingua.list_languages()
			if #list == 0 then
				return true, "No languages yet."
			end

			local lines = {}
			for _, lang in ipairs(list) do
				local known  = lingua.knows(name, lang.name) and " ✓" or ""
				local secret = lang.secret and " [secret]" or ""
				table.insert(lines, lang.name
					.. " (by " .. lang.author .. ")"
					.. secret .. known)
			end
			return true, table.concat(lines, "\n")
		end

		-- -----------------------------------------------------------------
		-- info
		-- -----------------------------------------------------------------
		if cmd == "info" then
			if rest == "" then
				return false, "Usage: /lingua info <name>"
			end

			local lang = lingua.get_language(rest)
			if not lang then return false, "Language not found" end

			local knows = lingua.knows(name, rest)

			local lines = {
				"Language: " .. lang.name,
				"Author: " .. lang.author,
				"Type: " .. (lang.secret and "secret" or "normal"),
			}

			if knows then
				local preview = "Alphabet:"
				for ch in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do
					preview = preview .. " " .. ch .. "=" .. lang.alphabet[ch]
				end
				table.insert(lines, preview)
			else
				table.insert(lines, "You don't know this language.")
			end

			return true, table.concat(lines, "\n")
		end

		-- -----------------------------------------------------------------
		-- encode
		-- -----------------------------------------------------------------
		if cmd == "encode" then
			local lname, text = rest:match("^(%S+)%s+(.+)$")
			if not lname then
				return false, "Usage: /lingua encode <name> <text>"
			end

			local lang = lingua.get_language(lname)
			if not lang then return false, "Language not found" end
			if not lingua.knows(name, lname) then
				return false, "You don't know this language."
			end

			return true, lingua.encode(text, lang)
		end

		-- -----------------------------------------------------------------
		-- decode
		-- -----------------------------------------------------------------
		if cmd == "decode" then
			local lname, text = rest:match("^(%S+)%s+(.+)$")
			if not lname then
				return false, "Usage: /lingua decode <name> <text>"
			end

			local lang = lingua.get_language(lname)
			if not lang then return false, "Language not found" end
			if not lingua.knows(name, lname) then
				return false, "You don't know this language."
			end

			return true, lingua.decode(text, lang)
		end

		-- -----------------------------------------------------------------
		-- wrap
		-- -----------------------------------------------------------------
		if cmd == "wrap" then
			local lname, text = rest:match("^(%S+)%s+(.+)$")
			if not lname then
				return false, "Usage: /lingua wrap <name> <text>"
			end

			local lang = lingua.get_language(lname)
			if not lang then return false, "Language not found" end
			if not lingua.knows(name, lname) then
				return false, "You don't know this language."
			end

			local encoded = lingua.encode(text, lang)
			return true, lingua.wrap(encoded, lname)
		end

		-- -----------------------------------------------------------------
		-- decode_all
		-- -----------------------------------------------------------------
		if cmd == "decode_all" then
			if rest == "" then
				return false, "Usage: /lingua decode_all <text>"
			end

			local decoded = lingua.decode_marked(rest, name)
			local markers = lingua.find_markers(rest)

			if #markers == 0 then
				return true, "No language markers found in text."
			end

			local known = 0
			for _, m in ipairs(markers) do
				if lingua.knows(name, m.lang) then
					known = known + 1
				end
			end

			return true, decoded .. "\n\n("
				.. known .. "/" .. #markers .. " fragments decoded)"
		end

		-- -----------------------------------------------------------------
		-- bind (постійний словник)
		-- -----------------------------------------------------------------
		if cmd == "bind" then
			if rest == "" then
				return false, "Usage: /lingua bind <name>"
			end

			local lang = lingua.get_language(rest)
			if not lang then
				return false, "Language not found."
			end

			if lang.secret then
				return false,
					"Secret language — use /lingua bind_once."
			end

			local wielded = player:get_wielded_item()
			if wielded:get_name() ~= "lingua:dictionary" then
				return false, "You must hold an empty dictionary."
			end

			if not lingua.knows(name, rest) then
				return false, "You don't know this language."
			end

			local meta = wielded:get_meta()
			meta:set_string("lang", rest)
			meta:set_string("description",
				"Dictionary: " .. rest .. "\nRight-click to learn")
			player:set_wielded_item(wielded)

			return true, "Dictionary bound to '" .. rest .. "'."
		end

		-- -----------------------------------------------------------------
		-- bind_once (одноразовий словник)
		-- -----------------------------------------------------------------
		if cmd == "bind_once" then
			if rest == "" then
				return false, "Usage: /lingua bind_once <name>"
			end

			local lang = lingua.get_language(rest)
			if not lang then
				return false, "Language not found."
			end

			-- Для секретної мови — тільки автор
			if lang.secret and lang.author ~= name then
				return false,
					"Only the author of a secret language "
					.. "can create dictionaries for it."
			end

			local wielded = player:get_wielded_item()
			if wielded:get_name() ~= "lingua:dictionary_once" then
				return false,
					"You must hold a One-time Dictionary."
			end

			if not lingua.knows(name, rest) then
				return false, "You don't know this language."
			end

			local meta = wielded:get_meta()
			meta:set_string("lang", rest)
			meta:set_string("description",
				"One-time Dictionary: " .. rest
				.. "\nRight-click to learn (single use)")
			player:set_wielded_item(wielded)

			return true,
				"One-time dictionary bound to '" .. rest .. "'."
		end

		-- -----------------------------------------------------------------
		-- forget
		-- -----------------------------------------------------------------
		if cmd == "forget" then
			if rest == "" then
				return false, "Usage: /lingua forget <name>"
			end
			lingua.forget(name, rest)
			return true, "You forgot '" .. rest .. "'."
		end

		-- -----------------------------------------------------------------
		-- delete
		-- -----------------------------------------------------------------
		if cmd == "delete" then
			if rest == "" then
				return false, "Usage: /lingua delete <name>"
			end

			local lang = lingua.get_language(rest)
			if not lang then return false, "Not found" end

			if lang.author ~= name and not lingua.is_admin(name) then
				return false, "Only the author or an admin can delete."
			end

			lingua.delete_language(rest)
			return true, "Deleted '" .. rest .. "'."
		end

		return false, "Unknown subcommand: " .. cmd
	end,
})