#!/bin/sh
#tools to install
sudo apt-get install -y wget qemu qemu-utils cloud-utils

SERVER_IMG="xenial-server-cloudimg-arm64-uefi1.img"
#SERVER_IMG="bionic-server-cloudimg-arm64.img"



#Generating RSA key
cp -rf /home/$USER/.ssh ./
mv ./.ssh ssh_backup
rm /home/$USER/.ssh/*
ssh-keygen -t rsa -f /home/$USER/.ssh/id_rsa
rsa_key=$(cat /home/$USER/.ssh/id_rsa.pub)

DIR="boot"
if [ ! -d "$DIR" ]; then
  # Take action if $DIR exists. #
  echo "Installing config files in ${DIR}..."
  mkdir $DIR
else
  rm -rf $DIR/*	
fi

cd $DIR

#creating cloud.txt
FILE=./cloud.txt
	
touch $FILE

echo '#cloud-config' >> $FILE
echo '' >> $FILE
echo "users:" >> $FILE
echo "  - name: $USER">> $FILE
echo "    ssh-authorized-keys:" >> $FILE
echo "      - $rsa_key"    >> $FILE
echo "    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash " >> $FILE

#creating cloud img 
cloud-localds cloud.img $FILE

repo=$(echo $SERVER_IMG | cut -d '-' -f 1) 

#get the ubuntu aarch64 image and QEMU_EFI.fd
wget https://releases.linaro.org/components/kernel/uefi-linaro/15.12/release/qemu64/QEMU_EFI.fd
#wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-arm64.img
wget https://cloud-images.ubuntu.com/$repo/current/$SERVER_IMG


#Resizing the image
qemu-img resize ./$SERVER_IMG +50G
#exit(-1)
#Running the cloud image
qemu-system-aarch64 -smp 2 -m 4096 -M virt -bios QEMU_EFI.fd -nographic \
       -device virtio-blk-device,drive=image \
       -drive if=none,id=image,file=$SERVER_IMG \
       -device virtio-blk-device,drive=cloud \
       -drive if=none,id=cloud,file=cloud.img \
       -netdev user,id=user0 -device virtio-net-device,netdev=user0 -redir tcp:2222::22 \
       -cpu cortex-a57

