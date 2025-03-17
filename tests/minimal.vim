set rtp^=.
set rtp^=deps/plenary.nvim
set packpath=

set nocp
let &rtp = &rtp
let &packpath = &rtp
set loadplugins

runtime! plugin/plenary.vim

set noswapfile

lua package.path = vim.fn.expand('<sfile>:p:h:h') .. '/lua/?.lua;' .. vim.fn.expand('<sfile>:p:h:h') .. '/lua/?/init.lua;' .. package.path
lua require('plenary.busted')
