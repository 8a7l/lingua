lingua = {}

-- Реєструємо привілей, щоб його можна було видавати через /grant.
minetest.register_privilege("lingua_admin", {
	description = "Can create unlimited languages "
		.. "and manage all of them",
	give_to_singleplayer = true,
})


-- Універсальна перевірка «чи адмін Lingua».
-- Адмін = priv lingua_admin АБО priv server.
function lingua.is_admin(name)
	return minetest.check_player_privs(name, { lingua_admin = true })
		or minetest.check_player_privs(name, { server = true })
end


local modpath = minetest.get_modpath("lingua")

dofile(modpath .. "/storage.lua")
dofile(modpath .. "/alphabet.lua")
dofile(modpath .. "/book.lua")
dofile(modpath .. "/default_book.lua")
dofile(modpath .. "/bookshelf.lua")
dofile(modpath .. "/anti_copy.lua")
dofile(modpath .. "/dictionary.lua")
dofile(modpath .. "/stackable.lua")
dofile(modpath .. "/gui.lua")
dofile(modpath .. "/commands.lua")

minetest.log("action", "[lingua] Loaded")