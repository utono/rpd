keyboard.rst
============

TTY
---

Set font and colorscheme:

.. code-block:: bash

    pacman -S terminus-font
    cd /usr/share/kbd/consolefonts
    setfont ter-132n
    :colorscheme ron
    loadkeys dvorak-programmer
    setxkbmap -variant real-prog-dvorak &
    setxkbmap -variant dvorak &

Test `setxkbmap`:

.. code-block:: bash

    setxkbmap -print -verbose 10; zsh -i

