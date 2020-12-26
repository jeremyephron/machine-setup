" Cpp File Settings

set tabstop=2
set shiftwidth=2
set expandtab

set colorcolumn=100

set cino=N-s        " don't indent namespace block
set cinoptions+=t0  " don't indent return type above function decl

" Run make
nnoremap ,m :w <Bar> make!<CR>
