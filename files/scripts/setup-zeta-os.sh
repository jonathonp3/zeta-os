#!/bin/bash
set -euo pipefail

echo "🚀 Starting Zeta-OS PIA Assembly..."

# --- 1: IDENTITY (Universal Family Blueprint) ---
mkdir -p /usr/lib/sysusers.d
cat <<EOF > /usr/lib/sysusers.d/wolf-os.conf
# 1. Create the shared groups
g piavpn - -
g piahnsd - -

# 2. Add YOU to the groups on all 4 PCs
m jonathon libvirt
m jonathon piavpn

# 3. Add the Kids (Systemd will only apply the name that exists on the local PC)
m kyle libvirt
m kyle piavpn

m james libvirt
m james piavpn

m lucas libvirt
m lucas piavpn

m nicholas libvirt
m nicholas piavpn
EOF

# --- 2. WIRING BLUEPRINT --
# Note with Silverblue, /opt is a link to /var/opt. Using /var/opt
mkdir -p /usr/lib/tmpfiles.d
cat <<EOF > /usr/lib/tmpfiles.d/piavpn.conf
d /var/lib/piavpn 0775 root piavpn -
d /var/run/piavpn 0775 root piavpn -
d /var/opt/piavpn 0755 root root -
d /var/opt/piavpn/etc 0775 root piavpn -

# --- 3. BLUEPRINT: Every directory the app needs ---
L /var/opt/piavpn/bin - - - - /usr/libexec/piavpn/opt/piavpn/bin
L /var/opt/piavpn/lib - - - - /usr/libexec/piavpn/opt/piavpn/lib
L /var/opt/piavpn/plugins - - - - /usr/libexec/piavpn/opt/piavpn/plugins
L /var/opt/piavpn/qml - - - - /usr/libexec/piavpn/opt/piavpn/qml
L /var/opt/piavpn/share - - - - /usr/libexec/piavpn/opt/piavpn/share
L /var/opt/piavpn/var - - - - /var/lib/piavpn
EOF

# ---- 4. EXTRACT & STORE ---
mkdir -p /usr/libexec/piavpn
tar -xpJf /tmp/files/tmp/pia-backup.tar.xz -C /usr/libexec/piavpn/

# --- 5: SYSTEM INTEGRATION ---
mkdir -p /usr/lib/systemd/system /usr/lib/NetworkManager/conf.d /usr/share/applications /usr/share/pixmaps

# --- 6: Replicating successful fedora Workstation steps
cp /usr/libexec/piavpn/etc/systemd/system/piavpn.service /usr/lib/systemd/system/piavpn.service
cp /usr/libexec/piavpn/usr/share/applications/piavpn.desktop /usr/share/applications/piavpn.desktop
cp /usr/libexec/piavpn/usr/share/pixmaps/piavpn.png /usr/share/pixmaps/piavpn.png
cp /usr/libexec/piavpn/etc/NetworkManager/conf.d/wgpia.conf /usr/lib/NetworkManager/conf.d/wgpia.conf

# --- 7 APPLY THE WORKING DIRECTORY FIX - TESTED ON WORKSTATION ---
sed -i 's|ExecStart=.*|ExecStart=/opt/piavpn/bin/pia-daemon|' /usr/lib/systemd/system/piavpn.service
sed -i '/\[Service\]/a WorkingDirectory=/opt/piavpn' /usr/lib/systemd/system/piavpn.service

# --- 8: SET PERMISSIONS & FINALISE ---

# Allow pia-unbound to bind/listen on privileged ports (<1024) via Linux capabilities, not root
setcap 'cap_net_bind_service=+ep' /usr/libexec/piavpn/opt/piavpn/bin/pia-unbound || true

# Make the binaries owned by root, but the GROUP is 'piavpn'
chown root:piavpn /usr/libexec/piavpn/opt/piavpn/bin/pia-client
chown root:piavpn /usr/libexec/piavpn/opt/piavpn/bin/piactl

# Set permissions to 755 
# (Owner=Root can do anything, Group=Family can run it, Others=Can run it)
chmod 755 /usr/libexec/piavpn/opt/piavpn/bin/pia-client
chmod 755 /usr/libexec/piavpn/opt/piavpn/bin/piactl

systemctl enable libvirtd.service virtlogd.service piavpn.service docker.service sshd.service

echo "✅ Zeta-OS Custom Assembly Complete! Ready for Deployment."

