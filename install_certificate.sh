#!/bin/bash
DEVICE_NAME=Pixel_5_API_32
CERTIFICATE_PATH=~/.mitmproxy/mitmproxy-ca-cert.pem

NOCOLOR=$'\033[0m'
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLO=$'\033[0;33m'

wait_for_device(){
  echo "${YELLO} Wait for device... ${NOCOLOR}"
  while [ "`adb shell getprop sys.boot_completed | tr -d '\r' `" != "1" ] ; do sleep 1; done
}

root_device(){
  echo "${YELLO} Rooting device... ${NOCOLOR}"
  adb root
  wait_for_device
}

unroot_device(){
  echo "${YELLO} Unrooting device... ${NOCOLOR}"
  adb unroot
  wait_for_device
}

reboot_device(){
  echo "${YELLO} Rebooting... ${NOCOLOR}"
  adb reboot
  wait_for_device
}

remount(){
  echo "${YELLO} Remounting... ${NOCOLOR}"
  adb remount
  wait_for_device
}

install_certificate(){
  echo "${YELLO}Installing certificate on OS...${NOCOLOR}"
  echo "${RED}Type your password to continue:${NOCOLOR}"
  sudo security add-trusted-cert -d -p ssl -p basic -k /Library/Keychains/System.keychain $CERTIFICATE_PATH
  echo "${YELLO}Installing certificate on emulator: ${DEVICE_NAME}...${NOCOLOR}"
  hash=$(openssl x509 -noout -subject_hash_old -in $CERTIFICATE_PATH)
  adb push $CERTIFICATE_PATH /system/etc/security/cacerts/$hash.0
  adb shell chmod 777 /system/etc/security/cacerts/$hash.0
  unroot_device
  reboot_device
  check_certificate="$(adb shell ls /system/etc/security/cacerts/ | grep c8750f0d.0)"
  if [ "$check_certificate" == "c8750f0d.0" ];
  then echo "${GREEN} Certificate installed!${NOCOLOR}"
  else echo "${RED} ERROR: Certificate could not be installed${NOCOLOR}";
  fi
}

echo "${YELLO}Verify if certificate exists...${NOCOLOR}"
if [ -f "$CERTIFICATE_PATH" ]; then
  echo "${YELLO}Certificate found:${NOCOLOR}"
  cat $CERTIFICATE_PATH
  echo "${YELLO}Starting ${DEVICE_NAME} in writable state...${NOCOLOR}"
  emulator -avd $DEVICE_NAME -http-proxy http://0.0.0.0:8080 -writable-system &
  wait_for_device
  root_device
  adb shell avbctl disable-verification
  reboot_device
  root_device
  remount
  # root_device
  # remount
  install_certificate
else
  echo "${RED} ERROR: Certificate was not found${NOCOLOR}";
fi