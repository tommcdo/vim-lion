lion.vim
========

Lion.vim is a tool for aligning text by some character. It defines some
Vim operators that can be used with motion commands to align a targetted
block of text.

The two operators are `gl` and `gL`. `gl` will add spaces to the left of
the alignment character, and `gL` will add spaces to the right. Both
operators accept a count, a motion, and a single character.

For example, `glip=` will turn

    $i = 5;
    $username = 'tommcdo';
    $stuff = array(1, 2, 3);

into

    $i        = 5;
    $username = 'tommcdo';
    $stuff    = array(1, 2, 3);

Typing `3gLi(,` with the cursor somewhere inside `(` and `)` will turn

    $names = array(
        'bill', 'samantha', 'ray', 'ronald',
        'mo', 'harry', 'susan', 'ted',
        'timothy', 'bob', 'wolverine', 'cat',
        'lion', 'alfred', 'batman', 'linus',
    );

into

    $names = array(
        'bill',    'samantha', 'ray',       'ronald',
        'mo',      'harry',    'susan',     'ted',
        'timothy', 'bob',      'wolverine', 'cat',
        'lion',    'alfred',   'batman',    'linus',
    );

Installation
------------

If you don't have a preferred installation method, I recommend
installing [pathogen.vim](https://github.com/tpope/vim-pathogen), and
then simply copy and paste:

    cd ~/.vim/bundle
    git clone git://github.com/tommcdo/vim-lion.git

Once help tags have been generated, you can view the manual with
`:help lion`.
