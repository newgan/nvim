return {
	cmd = { "rust-analyzer" },
	filetypes = { "rust" },
	root_markers = {
		"Cargo.toml",
		".git",
	},
	settings = {
		["rust-analyzer"] = {
			diagnostics = {
				enable = false,
			},
			imports = {
				granularity = {
					group = "module",
				},
				prefix = "self",
			},
			cargo = {
				buildScripts = {
					enable = true,
				},
			},
			procMacro = {
				enable = true,
			},
			inlayHints = {
				enable = true,
			},
		},
	},
}
