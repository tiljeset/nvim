require('vim._core.ui2').enable()

vim.cmd('packadd nvim.undotree')
vim.cmd('packadd nvim.difftool')

vim.opt.cursorline = true
vim.opt.wrap = false

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.clipboard = "unnamedplus"
vim.opt.updatetime = 300

vim.pack.add({
	{ src = "https://github.com/navarasu/onedark.nvim.git" },
	{ src = "https://github.com/stevearc/conform.nvim" },
	{ src = "https://github.com/romus204/tree-sitter-manager.nvim" },
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/echasnovski/mini.extra" },
	{ src = "https://github.com/saghen/blink.lib" },
	{ src = "https://github.com/saghen/blink.cmp" },
})

require("onedark").setup{ style = 'warmer' }
require("onedark").load()

require('mini.pick').setup()
require('mini.extra').setup()

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)
vim.keymap.set('n', '<leader>u', '<cmd>Undotree<CR>')
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '<leader><leader>', MiniPick.builtin.buffers)
vim.keymap.set('n', '<leader>pf', MiniPick.builtin.files)
vim.keymap.set('n', '<leader>ps', MiniPick.builtin.grep_live)
vim.keymap.set('n', '<leader>ph', MiniPick.builtin.help)
vim.keymap.set('n', '<leader>p.', MiniExtra.pickers.oldfiles)


require('tree-sitter-manager').setup({
  ensure_installed = { 'go', 'lua' },
  highlight = true,
})

require('conform').setup({
  formatters_by_ft = { go = { 'goimports' } },
  format_on_save = { timeout_ms = 500 },
})

require('blink.cmp').setup({
  keymap = {
    ['<C-n>'] = { 'show', 'select_next', 'fallback' },
    ['<C-p>'] = { 'show', 'select_prev', 'fallback' },
  },
  completion = {
    trigger = {
      show_on_keyword = false,
      show_on_trigger_character = false,
    },
    menu = { auto_show = false },
  },
})

vim.lsp.enable('gopls')

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local map = function(lhs, rhs) vim.keymap.set('n', lhs, rhs, { buffer = ev.buf }) end
    map('grr', function() MiniExtra.pickers.lsp({ scope = 'references' }) end)
    map('gri', function() MiniExtra.pickers.lsp({ scope = 'implementation' }) end)
    map('gd', function()
      vim.lsp.buf.definition({
        on_list = function(options)
          if #options.items == 0 then return end
          if #options.items == 1 then
            local item = options.items[1]
            vim.cmd('edit ' .. vim.fn.fnameescape(item.filename))
            vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
          else
            MiniExtra.pickers.lsp({ scope = 'definition' })
          end
        end,
      })
    end)
    map('gD',  function() MiniExtra.pickers.lsp({ scope = 'declaration' }) end)

    if client and client:supports_method('textDocument/documentHighlight') then
      local group = vim.api.nvim_create_augroup('lsp_highlight_' .. ev.buf, { clear = true })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = ev.buf,
        group = group,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd('CursorMoved', {
        buffer = ev.buf,
        group = group,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
    desc = 'Jump to last known position when opening a file',
    pattern = { '*' },
    callback = function()
        if vim.fn.line '\'"' > 1 and vim.fn.line '\'"' <= vim.fn.line '$' then
            vim.cmd('normal! g\'"', false)
        end
    end,
})
