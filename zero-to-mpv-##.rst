$HOME/.config/mpv/scripts/zero-to-mpv-19.py
===========================================

Systemctl Commands Reference
----------------------------

.. code-block:: bash

   # Reload the systemd user daemon
   systemctl --user daemon-reload

   # Restart the service
   systemctl --user restart 8bitdo_zero_2_to_mpv.service



   # List systemd services
   sudo systemctl list-units --type=service
   systemctl --user list-units --type=service
   sudo systemctl list-units --type=service --all
   systemctl --user list-units --type=service --all

   # Start or stop a service
   sudo systemctl start <service-name>.service
   systemctl --user start <service-name>.service
   sudo systemctl stop <service-name>.service
   systemctl --user stop <service-name>.service

   # Reload the daemon
   sudo systemctl daemon-reload
   systemctl --user daemon-reload

   # Check the status of a service
   sudo systemctl status <service-name>.service
   systemctl --user status <service-name>.service
   journalctl -u <service-name>.service
   journalctl --user -u <service-name>.service

   # Enable or disable a service
   sudo systemctl enable <service-name>.service
   systemctl --user enable <service-name>.service
   sudo systemctl disable <service-name>.service
   systemctl --user disable <service-name>.service

   # Enable and start the service immediately
   systemctl --user enable --now 8bitdo_zero_2_to_mpv.service

   # Check status and logs of the service
   systemctl --user status 8bitdo_zero_2_to_mpv.service
   journalctl --user -u 8bitdo_zero_2_to_mpv.service

Granting Permission to Access Gamepad Device
============================================

If you encounter a "Permission denied" error when accessing the gamepad device (e.g., `/dev/input/event19`), follow these steps:

1. **Check the Group and Permissions of the Device**

   .. code-block:: bash

      ls -l /dev/input/event19

   Example output:

   .. code-block:: text

      crw-rw---- 1 root input 13, 83 Dec 28 13:00 /dev/input/event19

   The device is owned by the `root` user and belongs to the `input` group.

2. **Add the User to the `input` Group**

   Add your user (`mlj`) to the `input` group:

   .. code-block:: bash

      sudo usermod -aG input mlj

3. **Log Out and Log Back In**

   Changes to group membership take effect only after logging out and logging back in.

4. **Verify Group Membership**

   After logging back in, confirm your user is in the `input` group:

   .. code-block:: bash

      groups

5. **Test Access**

   Retry running the Python script to verify access:

   .. code-block:: bash

      /usr/bin/python3 ~/.config/systemd/user/8bitdo_zero_2_to_mpv.py

Configuring Gamepad Input for MPV Using Evdev
=============================================

These instructions guide you through setting up a gamepad (recognized as a keyboard) to control MPV on Arch Linux using `evdev`.

Requirements
------------

Ensure the following tools are installed:

.. code-block:: bash

   sudo pacman -S python-evdev socat

- **`python-evdev`**: For reading input events from devices.
- **`socat`**: For sending JSON commands to MPV's IPC socket.

Steps
-----

1. Enable MPV's IPC Server
   -----------------------

   Edit the MPV configuration file:

   .. code-block:: bash

      nvim ~/.config/mpv/mpv.conf

   Add the following line:

   .. code-block:: ini

      input-ipc-server=/tmp/mpvsocket

   Save and close the file.

2. Identify the Gamepad Device
   ---------------------------

   .. code-block:: bash

      ls /dev/input/by-path/
      evtest /dev/input/by-path/your-keyboard-device

3. Map Gamepad Inputs to MPV Functions
   -----------------------------------

   Create a Python script at `~/keyboard_to_mpv.py`:

   .. code-block:: python

      # Python script content here

4. Test the Script
   ----------------

   .. code-block:: bash

      mpv your_video_file.mkv
      ~/keyboard_to_mpv.py

5. Automate the Script
   --------------------

   Create a systemd service file at `~/.config/systemd/user/keyboard-to-mpv.service`:

   .. code-block:: ini

      [Unit]
      Description=Keyboard Input to MPV
      After=mpv.service

      [Service]
      ExecStart=/usr/bin/python3 /home/mlj/.config/mpv/scripts/8bitdo_zero_2_to_mpv.py
      Restart=always

      [Install]
      WantedBy=default.target

   Enable and start the service:

   .. code-block:: bash

      systemctl --user enable --now keyboard-to-mpv.service

Debugging
---------

- Check if the MPV socket exists:

   .. code-block:: bash

      ls /tmp/mpvsocket

- Send test commands to MPV:

   .. code-block:: bash

      echo '{ "command": ["cycle", "pause"] }' | socat - /tmp/mpvsocket

This setup ensures the gamepad (acting as a keyboard) exclusively controls MPV.
