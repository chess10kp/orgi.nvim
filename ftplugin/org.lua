return {
  "yourusername/orgi.nvim",
  dependencies = {
    "folke/snacks.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("orgi").setup()
  end,
}
