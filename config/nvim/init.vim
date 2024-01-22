let g:config_home = empty($XDG_CONFIG_HOME) ? expand('~/.config') : $XDG_CONFIG_HOME
let g:cache_home  = empty($XDG_CACHE_HOME)  ? expand('~/.cache')  : $XDG_CACHE_HOME

let g:vim_dir  = g:config_home . '/nvim'
let g:dein_dir = g:cache_home  . '/nvim/dein'

if &compatible
    set nocompatible
endif

" reset augroup
augroup MyAutoCmd
    autocmd!
augroup END

" dein settings {{{
" dein自体の自動インストール
let s:dein_repo_dir = g:dein_dir . '/repos/github.com/Shougo/dein.vim'
if !isdirectory(s:dein_repo_dir)
    call system('git clone https://github.com/Shougo/dein.vim ' . shellescape(s:dein_repo_dir))
endif
let &runtimepath = s:dein_repo_dir .",". &runtimepath

" プラグイン読み込み＆キャッシュ作成
let s:toml_file = g:vim_dir.'/dein.toml'
let s:lazy_toml_file = g:vim_dir.'/dein_lazy.toml'
call dein#begin(g:dein_dir)
call dein#load_toml(s:toml_file,      {'lazy': 0})
call dein#load_toml(s:lazy_toml_file, {'lazy': 1})
call dein#end()

filetype plugin indent on
syntax enable

" 不足プラグインの自動インストール
if dein#check_install()
    call dein#install()
endif
" }}}

"set cursorline
set autoindent
set autochdir
set clipboard+=unnamed
set expandtab
set hlsearch
set ignorecase
set list
set listchars=tab:»\ ,trail:･,extends:»,precedes:«
set nowrap
set number
set ruler
set shiftwidth=4
set showcmd
set showmatch
set smartcase
set smarttab
set softtabstop=4
set tabstop=4
set whichwrap=b,s,<,>,[,]
set wildmenu

" インサートモードでEmacs風に移動できるようにする
imap <C-a> <Home>
imap <C-b> <Left>
imap <C-d> <Delete>
imap <C-e> <End>
imap <C-f> <Right>
imap <C-n> <Down>
imap <C-p> <Up>
imap <C-v> <PageDown>
imap <M-v> <PageUp>

" Y を行末までのヤンクに変更
nnoremap Y y$
