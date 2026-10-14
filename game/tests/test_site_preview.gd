extends SceneTree

var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	check(SitePreview.is_html_path("site/index.html"), "Promoted site/index.html is previewable")
	check(not SitePreview.is_html_path("site/styles.css"), "CSS is source-only")
	check(not SitePreview.is_html_path("../site/index.html"), "Parent traversal cannot preview")
	check(not SitePreview.is_html_path("/tmp/index.html"), "Absolute paths cannot preview")
	check(not SitePreview.is_html_path("C:/studio/index.html"), "Drive paths cannot preview")
	check(not SitePreview.is_html_path("site\\index.html"), "Backslash paths cannot preview")
	check(SitePreview.companion_stylesheet("site/index.html", "<link rel='stylesheet' href='styles.css'>", PackedStringArray(["site/styles.css"])) == "site/styles.css", "Relative stylesheet resolves inside studio/")
	check(SitePreview.companion_stylesheet("site/index.html", "<link rel='stylesheet' href='https://localhost/styles.css'>", PackedStringArray(["site/styles.css"])) == "site/styles.css", "Remote stylesheet href is ignored; same-folder studio CSS may still apply")
	check(SitePreview.companion_stylesheet("site/index.html", "<link rel='stylesheet' href='../secret.css'>", PackedStringArray(["secret.css"])) == "", "Parent CSS href is rejected")
	check(SitePreview.companion_stylesheet("site/index.html", "<link rel='stylesheet' href='styles.css'>", PackedStringArray(["ads/styles.css"])) == "", "Missing studio CSS fails closed")
	var html := "<html><head><style>body{background:url(http://127.0.0.1/x.png)}</style><script>alert(1)</script></head><body onload='steal()'><h1>Offer</h1><p>A prototype.</p><a href='javascript:alert(1)'>Go</a><iframe src='http://localhost'></iframe></body></html>"
	var rendered: Dictionary = SitePreview.render(html, "@import url('https://evil'); body { color: #222; } a { color: #354b98; }")
	check(bool(rendered.get("ok", false)), "Sanitized HTML can still preview")
	var text := str(rendered.get("bbcode", ""))
	check(text.contains("Offer") and text.contains("prototype"), "Preview keeps visible copy")
	check(not text.contains("alert") and not text.contains("javascript") and not text.contains("iframe") and not text.contains("127.0.0.1"), "Preview removes scripts, javascript URLs and private fetches")
	check(str(rendered.get("notice", "")).contains("no network"), "Preview discloses the network ban")
	var empty: Dictionary = SitePreview.render("<script>void 0</script>", "")
	check(not bool(empty.get("ok", false)), "Script-only HTML fails closed")
	if failures.is_empty(): print("Site preview: passed")
	quit(failures.size())
