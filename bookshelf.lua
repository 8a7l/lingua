-- bookshelf.lua
-- Полиця з трьома режимами: normal / copy / locked.
-- За замовчуванням — locked.
--
-- У режимі copy копіюються лише:
--   * default:book_written          (записана книга)
--   * lingua:coded_book із текстом  (невідома книга)
--   * lingua:dictionary із lang     (постійний словник)
--
-- lingua:dictionary_once НЕ копіюється — щоб секретні мови
-- не можна було роздавати через публічну полицю.
--
-- Анти-дюп-ланцюг: копія отримує мітку lingua:is_copy=1 і з неї
-- копію зробити вже не можна. Розмноження лінійне.

local S = minetest.get_translator("lingua")

local vanilla = minetest.registered_nodes["default:bookshelf"]

local DEFAULT_MODE = "locked"

local MODE_LABEL = {
	normal = "Normal",
	copy   = "Copy",
	locked = "Locked",
}


local ALLOWED = {
	["lingua:coded_book"]      = true,
	["lingua:dictionary"]      = true,
	["lingua:dictionary_once"] = true,
	["default:book"]           = true,
	["default:book_written"]   = true,
}


local COPY_MARK = "lingua:is_copy"


local function copy_tiles(tiles)
	if type(tiles) == "string" then return tiles end
	local result = {}
	for i, t in ipairs(tiles) do result[i] = t end
	return result
end


local function copy_groups(groups)
	local result = {}
	if groups then
		for k, v in pairs(groups) do result[k] = v end
	end
	return result
end


local function normalize_mode(mode)
	if not mode or mode == "" then return DEFAULT_MODE end
	if mode == "public" then return "copy" end
	return mode
end


local function mode_display(mode)
	return MODE_LABEL[mode] or mode
end


local function get_mode(meta)
	return normalize_mode(meta:get_string("mode"))
end


-- ---------------------------------------------------------------------------
-- Що можна копіювати?
-- ---------------------------------------------------------------------------

local function is_copyable(stack)
	local name = stack:get_name()

	if name == "default:book_written" then
		return true
	end

	if name == "lingua:coded_book" then
		local meta = stack:get_meta()
		return meta:get_string("text") ~= ""
	end

	if name == "lingua:dictionary" then
		local meta = stack:get_meta()
		return meta:get_string("lang") ~= ""
	end

	-- lingua:dictionary_once — НЕ копіюється (захист секретних мов)
	return false
end


-- Чи це вже копія? (тоді копіювати не можна)
local function is_marked_copy(stack)
	local meta = stack:get_meta()
	return meta:get_string(COPY_MARK) == "1"
end


-- Помітити стак як копію
local function mark_as_copy(stack)
	local meta = stack:get_meta()
	meta:set_string(COPY_MARK, "1")

	local base = stack:get_description()
	if not base:find("%(copy%)") then
		meta:set_string("description", base .. "\n(copy)")
	end
end


-- ---------------------------------------------------------------------------
-- Форма
-- ---------------------------------------------------------------------------

local function build_formspec(pos, player)
	local meta = minetest.get_meta(pos)
	local mode = get_mode(meta)

	local owner = meta:get_string("owner")
	local pname = player and player:get_player_name() or ""
	local is_owner = (owner == "" or owner == pname)

	local title = "Bookshelf [" .. mode_display(mode) .. "]"
	if owner ~= "" then
		title = title .. "  owner: " .. owner
	end

	local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z

	local fs = "size[10,9]" ..
		"label[0,0;" .. title .. "]" ..
		"list[nodemeta:" .. pos_str .. ";books;1,0.5;8,2;]" ..
		"list[current_player;main;1,4;8,4;]" ..
		"label[0,3.2;Allowed: unknown books, written books, dictionaries, empty books]" ..
		"listring[nodemeta:" .. pos_str .. ";books]" ..
		"listring[current_player;main]"

	if is_owner then
		fs = fs ..
			"button[0,8.2;2.5,0.8;mode_normal;Normal]" ..
			"button[2.6,8.2;2.5,0.8;mode_copy;Copy]" ..
			"button[5.2,8.2;2.5,0.8;mode_locked;Locked]"
	end

	fs = fs .. "button_exit[8,8.2;1.8,0.8;close;Close]"

	return fs
end


local function is_locked_owner(pos, player)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	if owner == "" then return true end
	return player:get_player_name() == owner
end


-- ---------------------------------------------------------------------------
-- Нода
-- ---------------------------------------------------------------------------

minetest.register_node("lingua:bookshelf", {
	description = "Bookshelf (multi-mode)\n"
		.. "Modes: normal, copy (filled books & bound dictionaries), locked",
	tiles = vanilla and copy_tiles(vanilla.tiles)
		or { "default_bookshelf.png" },
	paramtype2 = vanilla and vanilla.paramtype2 or "facedir",
	is_ground_content = false,
	groups = vanilla and copy_groups(vanilla.groups)
		or { choppy = 2, oddly_breakable_by_hand = 2, flammable = 3 },
	sounds = default.node_sound_wood_defaults(),

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:get_inventory():set_size("books", 16)
		meta:set_string("mode", DEFAULT_MODE)
		meta:set_string("infotext",
			"Bookshelf [" .. mode_display(DEFAULT_MODE) .. "]")
	end,

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local owner = placer:get_player_name()
		meta:set_string("owner", owner)
		meta:set_string("infotext",
			"Bookshelf [" .. mode_display(DEFAULT_MODE) .. "] — " .. owner)
	end,

	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local pname = clicker:get_player_name()
		local formname = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z
		minetest.show_formspec(pname, formname, build_formspec(pos, clicker))
	end,

	-- -----------------------------------------------------------------
	-- PUT
	-- -----------------------------------------------------------------
	allow_metadata_inventory_put = function(pos, listname, index,
		stack, player)

		if not stack then return 0 end
		if not ALLOWED[stack:get_name()] then return 0 end

		local meta = minetest.get_meta(pos)
		local mode = get_mode(meta)

		if mode == "locked" and not is_locked_owner(pos, player) then
			return 0
		end

		-- У режимі copy не можна класти взагалі — закриває
		-- swap-обхід (Luanti issue #6534).
		if mode == "copy" then
			return 0
		end

		return stack:get_count()
	end,

	-- -----------------------------------------------------------------
	-- TAKE
	-- -----------------------------------------------------------------
	allow_metadata_inventory_take = function(pos, listname, index,
		stack, player)

		if not stack then return 0 end

		local pname = player:get_player_name()
		local meta = minetest.get_meta(pos)
		local mode = get_mode(meta)

		if mode == "locked" and not is_locked_owner(pos, player) then
			return 0
		end

		if mode == "copy" then
			-- 1) має бути чим копіювати
			if not is_copyable(stack) then
				minetest.chat_send_player(pname,
					"Only filled books or bound dictionaries "
					.. "can be copied. (Switch to Normal mode "
					.. "to take this item out.)")
				return 0
			end

			-- 2) анти-дюп-ланцюг: копію копіювати не можна
			if is_marked_copy(stack) then
				minetest.chat_send_player(pname,
					"This is already a copy — it cannot "
					.. "be copied again.")
				return 0
			end

			-- 3) по одному за раз (проти shift-click дюпу)
			if stack:get_count() ~= 1 then
				return 0
			end

			-- 4) робимо копію та маркуємо її
			local copy = stack:peek_item(1)
			mark_as_copy(copy)

			local inv = player:get_inventory()
			if inv:room_for_item("main", copy) then
				inv:add_item("main", copy)
			else
				minetest.chat_send_player(pname,
					"No room in your inventory for a copy.")
			end

			-- оригінал лишається на полиці
			return 0
		end

		return stack:get_count()
	end,

	-- -----------------------------------------------------------------
	-- MOVE
	-- -----------------------------------------------------------------
	allow_metadata_inventory_move = function(pos, from_list, from_index,
		to_list, to_index, count, player)

		local meta = minetest.get_meta(pos)
		local mode = get_mode(meta)

		if mode == "locked" and not is_locked_owner(pos, player) then
			return 0
		end

		if mode == "copy" then
			return 0
		end

		return count
	end,

	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local mode = get_mode(meta)

		if mode == "locked" and not is_locked_owner(pos, player) then
			return false
		end

		if inv:get_size("books") == 0 then
			return true
		end

		return inv:is_empty("books")
	end,

	after_destruct = function(pos, oldnode)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		if inv:get_size("books") == 0 then return end

		local list = inv:get_list("books")
		if not list then return end

		for _, stack in ipairs(list) do
			if not stack:is_empty() then
				minetest.add_item(pos, stack)
			end
		end
	end,
})


-- ---------------------------------------------------------------------------
-- Кнопки режиму
-- ---------------------------------------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local pname = player:get_player_name()

	if not formname:match("^nodemeta:") then return end

	local mode = nil
	if fields.mode_normal then mode = "normal"
	elseif fields.mode_copy then mode = "copy"
	elseif fields.mode_locked then mode = "locked"
	end

	if not mode then return end

	local pos_str = formname:match("^nodemeta:(.+)$")
	if not pos_str then return end

	local pos = minetest.string_to_pos(pos_str)
	if not pos then return end

	local node = minetest.get_node(pos)
	if node.name ~= "lingua:bookshelf" then return end

	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	if owner ~= "" and owner ~= pname then
		minetest.chat_send_player(pname,
			"Only the owner can change the mode.")
		return
	end

	meta:set_string("mode", mode)
	meta:set_string("infotext",
		"Bookshelf [" .. mode_display(mode) .. "] — " .. owner)

	minetest.show_formspec(pname, formname, build_formspec(pos, player))
end)


minetest.register_craft({
	output = "lingua:bookshelf",
	recipe = {
		{ "default:bookshelf", "default:paper" },
	},
})