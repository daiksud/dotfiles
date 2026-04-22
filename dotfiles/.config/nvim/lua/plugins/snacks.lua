return {
  "snacks.nvim",
  opts = {
    image = {
      enabled = true,
    },
    terminal = {
      win = {
        keys = {
          nav_h = false,
          nav_j = false,
          nav_k = false,
          nav_l = false,
          hide_slash = { "<C-/>", "hide", desc = "Hide Terminal", mode = "t" },
          hide_underscore = { "<c-_>", "hide", desc = "which_key_ignore", mode = "t" },
        },
      },
    },
    zen = {
      win = {
        width = 160,
        backdrop = {
          transparent = true,
          blend = 10,
        },
      },
    },
  },
}
