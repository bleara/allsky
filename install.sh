#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
echo -en '\n'
echo -e "${RED}**********************************************"
echo    "*** Welcome to the Allsky Camera installer ***"
echo -e "**********************************************${NC}"
echo -en '\n'

echo -en "${GREEN}* Dependencies installation\n${NC}"
apt-get update && apt-get install libopencv-dev libusb-dev libusb-1.0-0-dev ffmpeg gawk lftp jq imagemagick -y
echo -en '\n'

echo -en "${GREEN}* Compile allsky software\n${NC}"
make all
echo -en '\n'

echo -en "${GREEN}* Sunwait installation"
sudo cp sunwait /usr/local/bin
echo -en '\n'

echo -en "${GREEN}* Using the camera without root access\n${NC}"
install asi.rules /etc/udev/rules.d
udevadm control -R
echo -en '\n'

echo -en "${GREEN}* Autostart script\n${NC}"
sed -i '/allsky.sh/d' /etc/xdg/lxsession/LXDE-pi/autostart
sed -i "s|User=pi|User=`logname`|g" autostart/allsky.service
sed -i "s|/home/pi/allsky|$PWD|g" autostart/allsky.service
cp autostart/allsky.service /lib/systemd/system/
chown root:root /lib/systemd/system/allsky.service
chmod 0644 /lib/systemd/system/allsky.service
echo -en '\n'

echo -en "${GREEN}* Configure log rotation\n${NC}"
cp autostart/allsky /etc/logrotate.d/
chown root:root /etc/logrotate.d/allsky
chmod 0644 /etc/logrotate.d/allsky
cp autostart/allsky.conf /etc/rsyslog.d/
chown root:root /etc/rsyslog.d/allsky.conf
chmod 0644 /etc/rsyslog.d/allsky.conf
echo -en '\n'

echo -en "${GREEN}* Add ALLSKY_HOME environment variable\n${NC}"
echo "export ALLSKY_HOME=$PWD" | sudo tee /etc/profile.d/allsky.sh
echo -en '\n'

if [[ $CAMERA -eq "RPi_VEYE" ]]; then
echo "Setting up VEYE camera drivers"
sudo apt-get install git y
git clone https://github.com/veyeimaging/raspberrypi.git
mkdir veye
cp raspberrypi/i2c_cmd/bin/* ./veye
cp raspberrypi/veye_raspcam/bin/* ./veye
sudo chmod +x veye/*
sudo ln ~/allsky/veye/i2c_write ~/allsky/i2c_write
sudo ln ~/allsky/veye/i2c_read ~/allsky/i2c_read
sudo rm -r raspberrypi
./veye/enable_i2c_vc.sh
./veye/camera_i2c_config

fi

echo -en "${GREEN}* Copy camera settings files\n${NC}"
cp settings_ZWO.json.repo settings_ZWO.json
cp settings_RPiHQ.json.repo settings_RPiHQ.json
cp settings_RPi_VEYE.json.repo settings_RPi_VEYE.json
cp config.sh.repo config.sh
cp scripts/ftp-settings.sh.repo scripts/ftp-settings.sh
sudo chown -R `logname`:`logname` ../allsky
systemctl daemon-reload
systemctl enable allsky.service

# Modify the path permanently
echo '# set PATH so it includes veye directory if it exists' >> $HOME/.profile
echo 'if [ -d "$HOME/allsky/veye" ] ; then '>>$HOME/.profile
echo 'PATH="$HOME/allsky/veye:$PATH" '>> $HOME/.profile
echo 'fi' >> $HOME/.profile
echo -en '\n'


echo -en '\n'
echo -en "The Allsky Software is now installed. You should reboot the Raspberry Pi to finish the installation\n"
echo -en '\n'
read -p "Do you want to reboot now? [y/n] " ans_yn
case "$ans_yn" in
  [Yy]|[Yy][Ee][Ss]) reboot now;;

  *) exit 3;;
esac
