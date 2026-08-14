# Agent Rules

- NEVER run the `godot` binary or execute Godot via shell/headless commands.
- NEVER use dot/slash property syntax like `node.theme_override_font_sizes/font_size = 14` or `node.theme_override_styles/panel = style`. This is invalid GDScript syntax and causes parse errors.
- ALWAYS use Theme Type Variations (`node.theme_type_variation = &"VariantName"`) instead of theme overrides. Check `src/misc/theme.tres` for available theme type variations.
