class_name SitePreview
extends RefCounted

## Local, fail-closed HTML/CSS preview. Never opens the filesystem, never fetches.
## Companion CSS must already be a guarded studio-relative path supplied by the worker.

const BLOCKED_TAGS: PackedStringArray = [
	"script", "iframe", "object", "embed", "form", "base", "meta", "link",
	"svg", "video", "audio", "canvas", "noscript", "frame", "frameset", "applet",
]

static func is_html_path(path: String) -> bool:
	var extension := path.get_extension().to_lower()
	return is_safe_relative(path) and (extension == "html" or extension == "htm")


static func is_safe_relative(path: String) -> bool:
	if path.is_empty() or path.contains("\\"):
		return false
	if path.is_absolute_path() or path.begins_with("/") or path.begins_with("~"):
		return false
	if path.contains("://") or path.contains(":"):
		return false
	var segments := path.replace("\\", "/").split("/", false)
	if segments.is_empty():
		return false
	for segment: String in segments:
		if segment.is_empty() or segment == "." or segment == "..":
			return false
	return true


static func companion_stylesheet(html_path: String, html: String, studio_paths: PackedStringArray) -> String:
	if not is_html_path(html_path):
		return ""
	var directory := html_path.get_base_dir()
	var candidates: PackedStringArray = []
	var default_css := "styles.css" if directory.is_empty() else directory.path_join("styles.css")
	if studio_paths.has(default_css):
		candidates.append(default_css)
	var link := RegEx.new()
	link.compile("(?i)<link\\b[^>]*rel\\s*=\\s*[\"']stylesheet[\"'][^>]*>")
	var href := RegEx.new()
	href.compile("(?i)href\\s*=\\s*[\"']([^\"']+)[\"']")
	for match: RegExMatch in link.search_all(html):
		var found := href.search(match.get_string())
		if found == null:
			continue
		var resolved := _resolve_relative(html_path, found.get_string(1).strip_edges())
		if not resolved.is_empty() and studio_paths.has(resolved) and not candidates.has(resolved):
			candidates.append(resolved)
	return candidates[0] if not candidates.is_empty() else ""


static func render(html: String, css: String = "") -> Dictionary:
	var blocked := PackedStringArray()
	var stylesheet := _sanitize_css(css)
	var extracted_style := _extract_style_blocks(html)
	stylesheet = (stylesheet + "\n" + extracted_style).strip_edges()
	var body := _strip_unsafe(html, blocked)
	body = _inline_simple_tags(body)
	var theme := _css_theme(stylesheet)
	var bbcode := _html_to_bbcode(body, theme)
	var readable := bbcode
	var tags := RegEx.new()
	tags.compile("\\[[^\\]]+\\]")
	readable = tags.sub(readable, "", true).strip_edges()
	if readable.is_empty():
		return {"ok": false, "reason": "Preview is unavailable. Open Source to read this file.", "bbcode": "", "blocked": blocked}
	var notice := "Local Studio preview · no network, no scripts."
	if not blocked.is_empty():
		notice = "Local preview with unsafe tags removed · no network."
	return {"ok": true, "reason": "", "bbcode": bbcode, "blocked": blocked, "notice": notice, "background": theme.get("body_bg", ""), "color": theme.get("body_color", "")}


static func _resolve_relative(from_html: String, href: String) -> String:
	var value := href.strip_edges()
	if value.is_empty() or value.begins_with("#") or value.begins_with("?"):
		return ""
	if value.contains("://") or value.begins_with("//") or value.begins_with("/") or value.begins_with("\\"):
		return ""
	if value.to_lower().begins_with("javascript:") or value.to_lower().begins_with("data:") or value.to_lower().begins_with("file:"):
		return ""
	var directory := from_html.get_base_dir()
	var combined := value if directory.is_empty() else directory.path_join(value)
	var parts: PackedStringArray = []
	for segment: String in combined.replace("\\", "/").split("/", false):
		if segment == "." or segment.is_empty():
			continue
		if segment == "..":
			return ""
		parts.append(segment)
	var resolved := "/".join(parts)
	if not is_safe_relative(resolved):
		return ""
	if resolved.get_extension().to_lower() != "css":
		return ""
	return resolved


static func _extract_style_blocks(html: String) -> String:
	var style := RegEx.new()
	style.compile("(?is)<style\\b[^>]*>(.*?)</style>")
	var collected: PackedStringArray = []
	for match: RegExMatch in style.search_all(html):
		collected.append(match.get_string(1))
	return "\n".join(collected)


static func _strip_unsafe(html: String, blocked: PackedStringArray) -> String:
	var text := html
	var comment := RegEx.new()
	comment.compile("(?s)<!--.*?-->")
	text = comment.sub(text, " ", true)
	for tag: String in BLOCKED_TAGS:
		var pair := RegEx.new()
		pair.compile("(?is)<%s\\b[^>]*>.*?</%s>" % [tag, tag])
		if pair.search(text) != null and not blocked.has(tag):
			blocked.append(tag)
		text = pair.sub(text, " ", true)
		var lonely := RegEx.new()
		lonely.compile("(?i)<%s\\b[^>]*/?>" % tag)
		if lonely.search(text) != null and not blocked.has(tag):
			blocked.append(tag)
		text = lonely.sub(text, " ", true)
	var style_block := RegEx.new()
	style_block.compile("(?is)<style\\b[^>]*>.*?</style>")
	text = style_block.sub(text, " ", true)
	var on_attr := RegEx.new()
	on_attr.compile("(?i)\\s+on[a-z]+\\s*=\\s*(\"[^\"]*\"|'[^']*'|[^\\s>]+)")
	if on_attr.search(text) != null and not blocked.has("event-handler"):
		blocked.append("event-handler")
	text = on_attr.sub(text, "", true)
	var proto := RegEx.new()
	proto.compile("(?i)(href|src|action|xlink:href)\\s*=\\s*[\"']\\s*(javascript:|data:|vbscript:|file:|about:)[^\"']*[\"']")
	if proto.search(text) != null and not blocked.has("blocked-url"):
		blocked.append("blocked-url")
	text = proto.sub(text, "", true)
	var remote := RegEx.new()
	remote.compile("(?i)(href|src)\\s*=\\s*[\"']\\s*((https?:)?//|/|\\\\)[^\"']*[\"']")
	if remote.search(text) != null and not blocked.has("remote-url"):
		blocked.append("remote-url")
	text = remote.sub(text, "", true)
	return text


static func _sanitize_css(css: String) -> String:
	if css.is_empty():
		return ""
	var text := css
	var comments := RegEx.new()
	comments.compile("(?s)/\\*.*?\\*/")
	text = comments.sub(text, " ", true)
	var imports := RegEx.new()
	imports.compile("(?i)@import\\b[^;]*;")
	text = imports.sub(text, " ", true)
	var urls := RegEx.new()
	urls.compile("(?i)url\\s*\\([^)]*\\)")
	text = urls.sub(text, "none", true)
	var expression := RegEx.new()
	expression.compile("(?i)expression\\s*\\([^)]*\\)")
	text = expression.sub(text, "none", true)
	var behavior := RegEx.new()
	behavior.compile("(?i)behavior\\s*:[^;]+;")
	text = behavior.sub(text, "", true)
	return text


static func _css_theme(css: String) -> Dictionary:
	var theme := {"body_color": "151515", "body_bg": "fff7e2", "h1": "151515", "link": "354b98"}
	if css.is_empty():
		return theme
	_apply_css_color(theme, css, "body", "color", "body_color")
	_apply_css_color(theme, css, "body", "background-color", "body_bg")
	_apply_css_color(theme, css, "h1", "color", "h1")
	_apply_css_color(theme, css, "a", "color", "link")
	return theme


static func _apply_css_color(theme: Dictionary, css: String, selector: String, property: String, key: String) -> void:
	var rule := RegEx.new()
	rule.compile("(?is)%s\\s*\\{([^}]+)\\}" % selector)
	var match := rule.search(css)
	if match == null:
		return
	var decl := RegEx.new()
	decl.compile("(?i)%s\\s*:\\s*([^;]+)" % property)
	var found := decl.search(match.get_string(1))
	if found == null:
		return
	var hex := _parse_color(found.get_string(1).strip_edges())
	if not hex.is_empty():
		theme[key] = hex


static func _parse_color(value: String) -> String:
	var trimmed := value.strip_edges().trim_prefix("#")
	if trimmed.length() == 3 and trimmed.is_valid_hex_number():
		return "%s%s%s%s%s%s" % [trimmed[0], trimmed[0], trimmed[1], trimmed[1], trimmed[2], trimmed[2]]
	if trimmed.length() == 6 and trimmed.is_valid_hex_number():
		return trimmed.to_lower()
	return ""


static func _inline_simple_tags(html: String) -> String:
	var text := html
	var br := RegEx.new()
	br.compile("(?i)<br\\s*/?>")
	text = br.sub(text, "\n", true)
	var hr := RegEx.new()
	hr.compile("(?i)<hr\\b[^>]*>")
	text = hr.sub(text, "\n———\n", true)
	return text


static func _html_to_bbcode(html: String, theme: Dictionary) -> String:
	var text := html
	var doctype := RegEx.new()
	doctype.compile("(?i)<!doctype[^>]*>")
	text = doctype.sub(text, "", true)
	var head := RegEx.new()
	head.compile("(?is)<head\\b[^>]*>.*?</head>")
	text = head.sub(text, " ", true)
	var html_tag := RegEx.new()
	html_tag.compile("(?i)</?html\\b[^>]*>")
	text = html_tag.sub(text, " ", true)
	var body := RegEx.new()
	body.compile("(?is)<body\\b[^>]*>(.*)</body>")
	var body_match := body.search(text)
	if body_match != null:
		text = body_match.get_string(1)
	text = _replace_pair(text, "h1", "[font_size=24][b][color=#%s]" % theme.h1, "[/color][/b][/font_size]")
	text = _replace_pair(text, "h2", "[font_size=22][b]", "[/b][/font_size]")
	text = _replace_pair(text, "h3", "[font_size=20][b]", "[/b][/font_size]")
	text = _replace_pair(text, "strong", "[b]", "[/b]")
	text = _replace_pair(text, "b", "[b]", "[/b]")
	text = _replace_pair(text, "em", "[i]", "[/i]")
	text = _replace_pair(text, "i", "[i]", "[/i]")
	text = _replace_pair(text, "code", "[code]", "[/code]")
	text = _replace_pair(text, "p", "", "\n\n")
	text = _replace_pair(text, "div", "", "\n")
	text = _replace_pair(text, "section", "", "\n")
	text = _replace_pair(text, "main", "", "\n")
	text = _replace_pair(text, "header", "", "\n")
	text = _replace_pair(text, "footer", "", "\n")
	text = _replace_pair(text, "article", "", "\n")
	text = _replace_pair(text, "li", "• ", "\n")
	text = _replace_pair(text, "ul", "", "\n")
	text = _replace_pair(text, "ol", "", "\n")
	text = _replace_pair(text, "span", "", "")
	text = _replace_pair(text, "a", "[color=#%s][u]" % theme.link, "[/u][/color]")
	var leftover := RegEx.new()
	leftover.compile("(?is)</?[a-z][a-z0-9]*\\b[^>]*>")
	text = leftover.sub(text, "", true)
	text = text.replace("&nbsp;", " ").replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", "\"")
	var spaces := RegEx.new()
	spaces.compile("[ \\t]+")
	text = spaces.sub(text, " ", true)
	var blank := RegEx.new()
	blank.compile("\\n{3,}")
	text = blank.sub(text, "\n\n", true)
	var color := str(theme.get("body_color", "151515"))
	return "[color=#%s]%s[/color]" % [color, text.strip_edges()]


static func _replace_pair(html: String, tag: String, open_bb: String, close_bb: String) -> String:
	var open := RegEx.new()
	open.compile("(?i)<%s\\b[^>]*>" % tag)
	var close := RegEx.new()
	close.compile("(?i)</%s>" % tag)
	return close.sub(open.sub(html, open_bb, true), close_bb, true)
