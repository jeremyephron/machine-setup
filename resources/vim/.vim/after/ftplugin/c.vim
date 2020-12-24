" C File Settings

set tabstop=2
set shiftwidth=2
set expandtab

set colorcolumn=80

set cino=N-s        " don't indent namespace block
set cinoptions+=t0  " don't indent return type above function decl

nnoremap ,m :w <Bar> make!<CR>   " run make
