extends SceneTree
## Read-only primary/fallback metric inspection; no worker or scene is started.
func _initialize() -> void:
	for character: String in "会社の計画 产品验证 한글 Привет γειά":
		if not GameFonts.BOLD.has_char(character.unicode_at(0)): print("MISSING ", character, " U+%04X" % character.unicode_at(0))
	for face: Font in [GameFonts.BODY, GameFonts.EMPHASIS, GameFonts.BOLD, GameFonts.BODY.base_font, load("res://assets/fonts/noto-fallback/NotoSansCJKsc-Regular.otf"), load("res://assets/fonts/noto-fallback/NotoSansSymbols2-Regular.ttf"), load("res://assets/fonts/noto-fallback/NotoEmoji.ttf")]:
		for pixels: int in [14, 16, 18, 20, 22]:
			print(face.resource_path, " ", pixels, "px ascent=", face.get_ascent(pixels), " descent=", face.get_descent(pixels), " height=", face.get_height(pixels), " text=", face.get_string_size("Day", HORIZONTAL_ALIGNMENT_LEFT, -1, pixels))
	quit()
