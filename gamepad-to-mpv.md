# Configuring Gamepad Input for MPV Using Evdev

This guide helps set up a gamepad (acting as a keyboard) to control MPV on Arch Linux using `evdev`.

---

## Step 1: Install Required Tools

Ensure the following tools are installed:

```bash
sudo pacman -S python-evdev socat
```

- `python-evdev`: For reading input events from devices.
- `socat`: For sending JSON commands to MPV's IPC socket.

---

## Step 2: Enable MPV's IPC Server

Edit the MPV configuration file:

```bash
nvim ~/.config/mpv/mpv.conf
```

Add the following line:

```ini
input-ipc-server=/tmp/mpvsocket
```

Save and close the file.

---

## Step 3: Identify the Gamepad Device

Use the following commands to identify your gamepad's device:

```bash
ls /dev/input/
evtest /dev/input/<your-device>
```

Replace `<your-device>` with the correct device name (e.g., `event19`).

---

## Step 4: Grant Permissions to Access the Gamepad Device

If you encounter "Permission denied" errors for the gamepad device (e.g., `/dev/input/event19`):

1. **Check Device Permissions**
   
   ```bash
   ls -l /dev/input/event19
   ```
   Confirm the device is in the `input` group.

2. **Add User to the Input Group**

   ```bash
   sudo usermod -aG input $(whoami)
   ```

3. **Log Out and Back In**

   Group changes take effect after re-logging.

4. **Verify Group Membership**

   ```bash
   groups
   ```

5. **Test Access**

   ```bash
   /usr/bin/python3 ~/.config/mpv/scripts/gamepad_to_mpv.py
   ```

---

## Step 5: Create and Configure the Python Script

Create a Python script to map gamepad inputs to MPV functions:

```bash
nvim ~/.config/mpv/scripts/gamepad_to_mpv.py
```

Paste the script from the original documentation here. Ensure `DEVICE_PATH` matches your device (e.g., `/dev/input/event19`).

Make the script executable:

```bash
chmod +x ~/.config/mpv/scripts/gamepad_to_mpv.py
```

---

## Step 6: Automate the Script with systemd

Create a systemd service file:

```bash
nvim ~/.config/systemd/user/gamepad_to_mpv.service
```

Add the following content:

```ini
[Unit]
Description=Gamepad Input to MPV
After=mpv.service

[Service]
ExecStart=/usr/bin/python3 /home/mlj/.config/mpv/scripts/gamepad_to_mpv.py
Restart=always

[Install]
WantedBy=default.target
```

Enable and start the service:

```bash
systemctl --user enable --now gamepad_to_mpv.service
```

---

## Step 7: Test the Setup

1. Start MPV with your video file:

   ```bash
   mpv your_video_file.mkv
   ```

2. Ensure the Python script is running:

   ```bash
   systemctl --user status gamepad_to_mpv.service
   ```

3. Verify the MPV socket exists:

   ```bash
   ls /tmp/mpvsocket
   ```

4. Send test commands to MPV (optional):  

   ```bash
   echo '{ "command": ["cycle", "pause"] }' | socat - /tmp/mpvsocket
   ```

---

## Debugging

- Restart the service if needed:

  ```bash
  systemctl --user restart gamepad_to_mpv.service
  ```

- View logs:

  ```bash
  journalctl --user -u gamepad_to_mpv.service
  ```

- Stop the service:

  ```bash
  systemctl --user stop gamepad_to_mpv.service
  ```

This setup ensures the gamepad (acting as a keyboard) exclusively controls MPV.
