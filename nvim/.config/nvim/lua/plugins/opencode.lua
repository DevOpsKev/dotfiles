-- opencode — open source AI coding agent (provider-agnostic)
-- Requires the opencode CLI: https://opencode.ai
return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>ac",
      function() Snacks.terminal("opencode", { cwd = vim.fn.getcwd(), win = { position = "right", width = 0.4 } }) end,
      desc = "Open opencode",
    },
    {
      "<leader>tr",
      function() Snacks.terminal(nil, { cwd = vim.fn.getcwd(), win = { position = "bottom", height = 0.4 } }) end,
      desc = "Open terminal",
    },
  },
}
