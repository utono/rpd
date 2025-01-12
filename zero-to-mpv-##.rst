Configuring Gamepad Input for MPV Using Evdev
=============================================

Helpful Commands
----------------

.. code-block:: bash

   # Reload the systemd user daemon
   systemctl --user daemon-reload

   systemctl --user enable --now gamepad_to_mpv.service
   systemctl --user restart gamepad_to_mpv.service
   systemctl --user status gamepad_to_mpv.service
   journalctl --user -u gamepad_to_mpv.service
   systemctl --user start gamepad_to_mpv.service
   systemctl --user stop gamepad_to_mpv.service
   systemctl --user enable gamepad_to_mpv.service
   systemctl --user disable gamepad_to_mpv.service

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

      /usr/bin/python3 ~/.config/mpv/scripts/gamepad_to_mpv.py

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

      ls /dev/input/
      evtest /dev/input/your-keyboard-device

3. Map Gamepad Inputs to MPV Functions
   -----------------------------------

   Create a Python script at `~/.config/mpv/scripts/gamepad_to_mpv.py`:

   .. code-block:: python
   .. code-block:: python

   #!/usr/bin/env python3
   
   from evdev import InputDevice, categorize, ecodes
   import socket
   import json
   import time
   import os
   
   DEVICE_PATH = '/dev/input/event19'
   MPV_SOCKET = '/tmp/mpvsocket'
   
   def send_to_mpv(command):
       retries = 5
       for attempt in range(retries):
           try:
               with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                   sock.connect(MPV_SOCKET)
                   sock.sendall(json.dumps(command).encode() + b'\n')
               return
           except ConnectionRefusedError:
               if attempt < retries - 1:
                   time.sleep(2)
               else:
                   print("Error: MPV socket connection refused. Is MPV running with --input-ipc-server?")
           except Exception as e:
               print(f"Error sending command to MPV: {e}")
               return
   
   key_map = {
       ecodes.KEY_K: {"command": ["cycle", "pause"]},
       ecodes.KEY_C: {"command": ["script-message", "write_chapters"]},
       ecodes.KEY_E: {"command": ["add", "chapter", -1]},
       ecodes.KEY_F: {"command": ["add", "chapter", 1]},
       ecodes.KEY_D: {"command": ["show-progress"]},
       ecodes.KEY_N: {"command": ["script-message", "add_chapter"]},
       ecodes.KEY_O: {"command": ["script-message", "remove_chapter"]},
       ecodes.KEY_I: {"command": ["no-osd", "seek", -2, "exact"]},
       ecodes.KEY_G: {"command": ["no-osd", "seek", 2, "exact"]},
       ecodes.KEY_H: {"command": ["add", "volume", 2]},
       ecodes.KEY_J: {"command": ["add", "volume", -2]},
   }
   
   def wait_for_device():
       print(f"Waiting for device at {DEVICE_PATH}...")
       while not os.path.exists(DEVICE_PATH):
           time.sleep(1)
       print(f"Device connected: {DEVICE_PATH}")
   
   def open_device():
       while True:
           try:
               device = InputDevice(DEVICE_PATH)
               device.grab()
               print(f"Listening to {device.name} at {DEVICE_PATH}...")
               return device
           except FileNotFoundError:
               wait_for_device()
   
   def main():
       while True:
           device = open_device()
           try:
               for event in device.read_loop():
                   if event.type == ecodes.EV_KEY:
                       key_event = categorize(event)
                       if key_event.keystate == key_event.key_down:
                           command = key_map.get(key_event.scancode)
                           if command:
                               send_to_mpv(command)
           except OSError as e:
               if e.errno == 19:
                   print("Device disconnected. Reinitializing...")
                   device.close()
                   wait_for_device()
               else:
                   print(f"Unhandled OSError: {e}")
   
   if __name__ == "__main__":
       main()

4. Test the Script
   ----------------

   .. code-block:: bash

      mpv your_video_file.mkv
      ~/.config/mpv/scripts/gamepad_to_mpv.py

5. Automate the Script
   --------------------

   Create a systemd service file at `~/.config/systemd/user/keyboard-to-mpv.service`:

   .. code-block:: ini

      [Unit]
      Description=Keyboard Input to MPV
      After=mpv.service

      [Service]
      ExecStart=/usr/bin/python3 /home/mlj/.config/mpv/scripts/gamepad_to_mpv.py
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
