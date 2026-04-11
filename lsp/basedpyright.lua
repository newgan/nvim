-- #############################################################
-- ####### basedpyright
-- #############################################################
-- main purpose is exact type checking diagnostics
-- It has very slow lsp completion to use
return {
	cmd = { 'basedpyright-langserver', '--stdio' },
	filetypes = { 'python' },
	root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'pyrightconfig.json', '.git' },
	on_attach = function(client, _)
		client.server_capabilities.completionProvider        = false -- use pyrefly for fast response
		client.server_capabilities.definitionProvider        = false -- use pyrefly for fast response
		client.server_capabilities.documentHighlightProvider = false -- use pyrefly for fast response
		client.server_capabilities.renameProvider            = false -- use pyrefly as I think it is stable
		client.server_capabilities.semanticTokensProvider    = false -- use pyrefly it is more rich
	end,
	settings = {                                               -- see https://docs.basedpyright.com/latest/configuration/language-server-settings/
		basedpyright = {
			disableOrganizeImports = true,                     -- use ruff instead of it
			analysis = {
				autoImportCompletions = true,
				autoSearchPaths = true, -- auto serach command paths like 'src'
				diagnosticMode = 'openFilesOnly',
				useLibraryCodeForTypes = true,
				diagnosticSeverityOverrides = {
					reportUnknownMemberType = 'none', -- ignore warning : cannot infer member type of object like matplot
					reportUnusedCallResult = 'none', -- ignore warning : If we don't use result of function, it must add '_ = '  in front of statement
				},
				exclude = {
					'**/.venv',
					'**/venv',
					'**/__pycache__',
					'**/dist',
					'**/build'
				}
			}
		},
	},
}
