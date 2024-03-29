filetype plugin indent on
syntax on

colorscheme Monokai

set exrc secure " source local .vimrc file if present

set number " line numbers

set mouse=a " enable mouse
if &term =~ '^screen'
    " tmux knows the extended mouse mode
    set ttymouse=xterm2
endif

set backspace=indent,eol,start

set tabstop=4     " how many columns a tab counts for
set softtabstop=4 " how many spaces should be treated as a tab
set shiftwidth=4  " how far an indent is with reindent operations
set expandtab     " tab becomes spaces
set autoindent    " applies indent of current line to the next one
set smartindent   " reacts to syntax/style of code

set colorcolumn=80,100 " ruler at col 80 and 100
set cursorline " highlight current line

set laststatus=2          " make statusline appear even with single window
set statusline=%f         " filename
set statusline+=\ %r%m    " readonly, modified flags
set statusline+=%=        " right align the next part
set statusline+=%y        " filetype
set statusline+=\ (%l,%c) " line number, col number

set hlsearch  " highlight found words on search
set incsearch " jump to best fit
set showmatch " highlight matching parentheses

set showcmd " show commands as they are typed
let mapleader = "," " set leader key to comma

" Turn off search highlighting with <CR> (return).
nnoremap <CR> :nohlsearch<CR><CR>

" Set .h files to C by default instead of C++
augroup global
    autocmd!
    autocmd BufRead,BufNewFile *.h set filetype=c
augroup END

" Autoinstall vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

" Specify plugin directory
call plug#begin('~/.vim/plugged')

" FZF 
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }

" NerdTree
Plug 'preservim/nerdtree'

" TagBar
Plug 'preservim/tagbar'

" Initialize the plugin system
call plug#end()

" FZF file searching with ,L
nnoremap <Leader>l :FZF<CR>

" Toggle NerdTree with ,T
nnoremap <Leader>t :NERDTreeToggle<CR>

" Toggle Tagbar with ,B
nnoremap <Leader>b :TagbarToggle<CR>

" Set syntax highlighting for personal extensions
" autocmd BufNewFile,BufRead *.howto set filetype=text
