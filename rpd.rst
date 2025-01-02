keyboard.rst
============

TTY
---

.. code-block:: bash

    loadkeys dvorak

Hyprland Configuration Instructions
===================================

.. code-block:: bash

   hyprctl switchxblayout all next

   To activate the custom layout in Hyprland, follow these steps:
   
   !!! As long as ~/utono/rpd/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak 
   !!! has been copied to /usr/share/X11/xkb/symbols,
   !!! Hyprland can make use of the layout.
   
   !!! It is unnecessary, for Hyprland, to update the following:
   !!! /usr/share/X11/xkb/rules/evdev.xml
   !!! /usr/share/X11/xkb/rules/base.lst
   !!! /usr/share/X11/xkb/rules/base.xml
   
   !!! Also unnecessary is:
   !!!
   !!! localectl set-keymap
   
   1. Create the configuration file:
      `~/.config/hypr/config/user-config.conf` with the following content:
   
      .. code-block:: none
   
         input {
             kb_layout = us,real_prog_dvorak
             kb_options = grp:alt_shift_toggle
         }
   
      Set ``kb_layout = us,real_prog_dvorak`` if you want Hyprland to use the
      ``us`` layout for binds. Even when ``real_prog_dvorak`` is the active layout,
      the binds will function as if the active layout is ``us``.
   
      To get the list of keyboard shortcuts you can put in the kb_options to toggle keyboard layouts:
   
         grep 'grp:.*toggle' /usr/share/X11/xkb/rules/base.lst
   
         grp:ctrls_toggle     Both Ctrls together
   
   2. Once configured, use the following command to switch between ``us`` and 
      ``real_prog_dvorak`` layouts:
   
      .. code-block:: shell
   
         hyprctl switchxblayout all next
   
   3. Add the following keybind to your `keybinds.conf` to simplify layout switching:
   
      .. code-block:: none
   
         bind = mainMod SHIFT, Tab, Switch xkb layout, exec, hyprctl switchxkblayout all next
