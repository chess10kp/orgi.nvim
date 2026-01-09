return {
  "yourusername/orgi.nvim",
  dependencies = {
    "folke/snacks.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("orgi").setup()
  end,
}
