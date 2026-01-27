return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "yaml-language-server",
        "yamllint",
        "dockerfile-language-server",
        "docker-compose-language-service",
        "hadolint",
      },
    },
  },
}
