-- DevOps tools LSP configuration (YAML, Docker)
-- Mason tools are in mason-tools.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        yamlls = {
          settings = {
            yaml = {
              keyOrdering = false,
            },
          },
        },
        dockerls = {},
        docker_compose_language_service = {},
      },
    },
  },
}
