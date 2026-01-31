#!/bin/bash
set -e

# Start X server
Xvfb :0 -screen 0 1920x1080x24 &
export DISPLAY=:0

# Wait for X server to be ready
sleep 2

# Start D-Bus session bus (required by XFCE settings)
eval $(dbus-launch --sh-syntax)
export DBUS_SESSION_BUS_ADDRESS

# Start XFCE desktop
startxfce4 &

# Wait a bit for desktop to start
sleep 3

# Start x11vnc (no password for default connection)
x11vnc -display :0 -nopw -listen localhost -xkb -forever -shared -rfbport 5900 &

# Create an index.html redirect that auto-connects to the VNC session
cat > /opt/noVNC/index.html <<'REDIRECT'
<!DOCTYPE html>
<html>
<head><meta http-equiv="refresh" content="0;url=vnc.html?autoconnect=true&resize=scale"></head>
</html>
REDIRECT

# Start noVNC on port 8080 with auto-connect
/opt/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8080 --web /opt/noVNC &

# Keep container running
echo "Web VNC is running on http://localhost:8080"
wait

