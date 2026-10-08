-- default_book.lua
-- Копії default:book_written мають бути read-only.
-- Компонування форми — як у ванільній книзі Minetest Game (вкладка «Читати»).

local COPY_MARK = "lingua:is_copy"

local orig_item = minetest.registered_items["default:book_written"]
local orig_on_use = orig_item and orig_item.on_use or nil


local function extract_title(stack)
	local desc = stack:get_meta():get_string("description")
	if desc == "" then
		return "Book With Text"
	end
	desc = desc:gsub("\n%(copy%)$", "")
	return desc
end


minetest.override_item("default:book_written", {
	on_use = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()

		if meta:get_string(COPY_MARK) == "1" then
			local pname = user:get_player_name()
			local text  = meta:get_string("text")
			local title = extract_title(itemstack)

			-- Відступи: 0.4 з усіх боків
			-- label (title) — y = 0.4
			-- textarea      — y = 1.2 .. 8.6
			-- button        — y = 8.8 .. 9.6 (по центру)
			minetest.show_formspec(pname, "lingua:default_book_readonly",
				"size[10,10]" ..
				"label[0.4,0.4;" ..
					minetest.formspec_escape(title) ..
					"  (copy — read-only)]" ..
				"textarea[0.4,1.2;9.7,9.5;content;;" ..
					minetest.formspec_escape(text) .. "]" ..
				"button_exit[4,9.5;2,0.8;close;Close]")
			return itemstack
		end

		-- Оригінал — поводиться як у default-моді.
		if orig_on_use then
			return orig_on_use(itemstack, user, pointed_thing)
		end
		return itemstack
	end,
})