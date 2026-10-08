-- stackable.lua
-- Єдине місце, де задається stack_max для книг і словників.
-- Словники різних мов мають різну meta (lang), тому
-- Luanti 5.x НЕ буде змішувати їх у один стак.

minetest.override_item("default:book", {
	stack_max = 99,
})

minetest.override_item("lingua:dictionary", {
	stack_max = 99,
})

minetest.override_item("lingua:dictionary_once", {
	stack_max = 99,
})