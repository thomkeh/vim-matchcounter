matchcounter.vim
================

When searching in vim with `/` or `?` you can jump to matches with `<number>n`
where `<number>` is for example `3` or `42`. (So, `3n` will jump to the 3rd match.)

The problem with that is that you have to know the right number for the match your interested in.
And this is what `matchcounter.vim` solves.
If a search performed with `/` or `?` finds more than 1 match in the visible area,
then this plugin displays a counter for each match,
so that you know which number to type to jump there.
If you don't type a number, then the counter disappears immediately.

![example](https://user-images.githubusercontent.com/7741417/114547302-3083da00-9c56-11eb-948c-a61d7d62dd3e.png)

Usage
-----

Just search something with `/`, and if there are multiple matches visible in your window,
labels will appear that allow you to jump directly to any of the matches.

*This plugin does not change any mappings.*
It uses the `CmdlineLeave` autocommand to know when a search happened,
and merely displays some labels for a while.

Install
-------

- [vim-plug](https://github.com/junegunn/vim-plug)
  - `Plug 'thomkeh/vim-matchcounter', { 'branch': 'main' }`
- [Pathogen](https://github.com/tpope/vim-pathogen)
  - `git clone git://github.com/thomkeh/vim-matchcounter.git ~/.vim/bundle/vim-sneak`
- Manual installation:
  - Copy the files to your `.vim` directory.

Customization
-------------

The only thing that can be customized is the background color
of the counter labels (magenta by default).
See the help for details.

Related
-------

* [Sneak](http://github.com/justinmk/vim-sneak)
* [Seek](https://github.com/goldfeld/vim-seek)
* [EasyMotion](https://github.com/Lokaltog/vim-easymotion)
* [incsearch-easymotion](https://github.com/haya14busa/incsearch-easymotion.vim)
* [smalls](https://github.com/t9md/vim-smalls)
* [improvedft](https://github.com/chrisbra/improvedft)
* [clever-f](https://github.com/rhysd/clever-f.vim)
* [vim-extended-ft](https://github.com/svermeulen/vim-extended-ft)
* [Fanf,ingTastic;](https://github.com/dahu/vim-fanfingtastic)

License
-------

Distributed under the MIT license.
