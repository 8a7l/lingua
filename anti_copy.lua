-- anti_copy.lua
-- Не дає використовувати копії (з міткою lingua:is_copy) у крафті.
--
-- Примітка: Luanti не має офіційного callback'у «скасувати крафт».
-- register_on_craft спрацьовує ПІСЛЯ списання інгредієнтів.
-- Тому гравець втрачає матеріали, але не отримує результату —
-- це і є запобіжник від використання копій у крафті.

local COPY_MARK = "lingua:is_copy"

minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	if not player or not old_craft_grid then return end

	for _, stack in ipairs(old_craft_grid) do
		if stack and not stack:is_empty() then
			local meta = stack:get_meta()
			if meta:get_string(COPY_MARK) == "1" then
				minetest.chat_send_player(player:get_player_name(),
					"Copies cannot be used in crafting.")
				return ItemStack("")
			end
		end
	end
end)