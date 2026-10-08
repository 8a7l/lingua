-- Постійний словник
minetest.register_craftitem("lingua:dictionary", {
	description = "Dictionary\n"
		.. "Bind with /lingua bind <name> while holding it.",
	inventory_image = "default_book.png",

	on_use = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		local lang = meta:get_string("lang")

		if lang == "" then
			minetest.chat_send_player(user:get_player_name(),
				"This dictionary is empty. Hold it and use "
				.. "/lingua bind <name>.")
			return itemstack
		end

		local ok, err = lingua.learn(user:get_player_name(), lang)

		if ok then
			minetest.chat_send_player(user:get_player_name(),
				"You learned the language '" .. lang .. "'.")
		else
			minetest.chat_send_player(user:get_player_name(),
				"Cannot learn: " .. err)
		end

		return itemstack
	end,
})


-- Одноразовий словник
minetest.register_craftitem("lingua:dictionary_once", {
	description = "One-time Dictionary\n"
		.. "Disappears after one use. Bind with "
		.. "/lingua bind_once <name>.",
	inventory_image = "default_book.png^[colorize:#ffcc00:120",

	on_use = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		local lang = meta:get_string("lang")

		if lang == "" then
			minetest.chat_send_player(user:get_player_name(),
				"This dictionary is empty. Hold it and use "
				.. "/lingua bind_once <name>.")
			return itemstack
		end

		local ok, err = lingua.learn(user:get_player_name(), lang)

		if ok then
			minetest.chat_send_player(user:get_player_name(),
				"You learned the language '" .. lang
				.. "'. The dictionary vanishes.")

			-- Забираємо предмет
			return ItemStack("")
		else
			minetest.chat_send_player(user:get_player_name(),
				"Cannot learn: " .. err)
			return itemstack
		end
	end,
})


-- Постійний: 3 папір + 1 книга
minetest.register_craft({
	output = "lingua:dictionary",
	recipe = {
		{"default:paper", "default:paper"},
		{"default:paper", "default:book"},
	},
})


-- Одноразовий: 1 папір + 1 книга
minetest.register_craft({
	output = "lingua:dictionary_once",
	recipe = {
		{"default:paper"},
		{"default:book"},
	},
})