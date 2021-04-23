" C File Settings

set tabstop=2
set softtabstop=2
set shiftwidth=2

set colorcolumn=80

set cino=N-s        " don't indent namespace block
set cinoptions+=t0  " don't indent return type above function decl

" Run make
nnoremap <Leader>m :w <Bar> make!<CR>
