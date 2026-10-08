lingua.storage = {}

-- ВАЖЛИВО: handle отримуємо ОДИН РАЗ при завантаженні моду.
-- Інакше get_mod_storage() не працює з callback-ів.
local storage = minetest.get_mod_storage()

local LANG_KEY  = "lingua:languages"
local KNOWN_KEY = "lingua:known"


function lingua.storage.load_languages()
	local raw = storage:get_string(LANG_KEY)
	if raw == "" then return {} end
	return minetest.deserialize(raw) or {}
end


function lingua.storage.save_languages(langs)
	storage:set_string(LANG_KEY, minetest.serialize(langs))
end


function lingua.storage.load_known()
	local raw = storage:get_string(KNOWN_KEY)
	if raw == "" then return {} end
	return minetest.deserialize(raw) or {}
end


function lingua.storage.save_known(known)
	storage:set_string(KNOWN_KEY, minetest.serialize(known))
end