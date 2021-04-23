" Cpp File Settings

set tabstop=4
set softtabstop=4
set shiftwidth=4

set colorcolumn=100

set cino=N-s        " don't indent namespace block
set cinoptions+=t0  " don't indent return type above function decl

" Run make
nnoremap <Leader>m :w <Bar> make!<CR>
