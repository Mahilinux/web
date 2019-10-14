#!/bin/bash -       
#title           :azuresapfs.sh
#description     :This script will be used to create/configure SAP File Systems.
#author		 :Mahesh
#date            :12072019
#version         :0.1
#usage		 :bash azuresapfs.sh
#bash_version    :4.3-release
# Notes
# Run the script as a root user
# Max 3 disks are allowed
# If the file system is already configured the script wouldn't run.
# Verify host caching is enabled for any File System

#Verify the user is superuser or not
if [ $(id -un) != root ]; then
echo "You are not a super user, please run script with super user"
exit
fi

# Snan and verify the disks.
for i in `ls /sys/class/scsi_host/`;do echo "- - -" >/sys/class/scsi_host/$i/scan; done

sresult=`grep -i host /proc/scsi/scsi |wc -l`
echo "No of existings/available disks: $sresult"

/sbin/blkid | cut -d ':' -f1 | cut -c 1-8 |sort -n| uniq >/tmp/busy
ls -l /dev/sd* | awk '{print $NF}' | cut -c 1-8| sort -n | uniq > /tmp/all

# Available/Free disks
cat /tmp/all | grep -vf /tmp/busy > /tmp/pvs
fresult=`cat /tmp/pvs| wc -l`

echo "Enter No of disks attached"
read disks

if [ $fresult != "$disks" ]; then
echo "The result is not maching with: No of disks Entered, No of Scanned disks and No of Free/Available disks"
echo "Ensure the attached disks are available for partitioning"
exit
else
echo "disks have been validated"
fi

# Create Physical Volumes
for i in `cat /tmp/pvs`; do pvcreate $i; done

# Creating a Volume Group
#pvs | grep 64 | awk '{print $1}' | xargs vgcreate vgsap

echo "Below are avialable physical volumes"
pvs| grep -v vg
echo ""
echo -e "Enter the $(tput setaf 1)\e[4mHANA-SAP$(tput sgr 0) physical volume names ex: /dev/sda"
read -p "Enter first disk name:" n1
read -p "Enter second disk name:" n2
read -p "Enter third disk name:" n3
echo $n1 $n2 $n3 | xargs vgcreate vgsap

echo "Below are avialable physical volumes"
pvs| grep -v vg
echo ""
echo -e "Enter the $(tput setaf 1)\e[4mHANA-SHARED$(tput sgr 0) physical volume names ex: /dev/sda"
read -p "Enter first disk name:" n1
read -p "Enter second disk name:" n2
read -p "Enter third disk name:" n3
echo $n1 $n2 $n3 | xargs vgcreate vgshared

echo "Below are avialable physical volumes"
pvs| grep -v vg
echo ""
echo -e "Enter the $(tput setaf 1)\e[4mHANA-LOG$(tput sgr 0) physical volume names ex: /dev/sda"
read -p "Enter first disk name:" n1
read -p "Enter second disk name:" n2
read -p "Enter third disk name:" n3
echo $n1 $n2 $n3| xargs vgcreate vglog


echo "Below are avialable physical volumes"
pvs| grep -v vg
echo ""
echo -e "Enter the $(tput setaf 1)\e[4mHANA-DATA$(tput sgr 0) physical volume names ex: /dev/sda"
read -p "Enter first disk name:" n1
read -p "Enter second disk name:" n2
read -p "Enter third disk name:" n3
echo $n1 $n2 $n3 | xargs vgcreate vgdata


echo "Below are avialable physical volumes"
pvs| grep -v vg
echo ""
echo -e "Enter the $(tput setaf 1)\e[4mHANA-BACKUP$(tput sgr 0) physical volume names ex: /dev/sda"
read -p "Enter first disk name:" n1
read -p "Enter second disk name:" n2
read -p "Enter third disk name:" n3
echo $n1 $n2 $n3 | xargs vgcreate vgbackup

# Creating logical volumes
#!/bin/bash
ihana=`pvs | grep vgdata | wc -l`
lvcreate -i $ihana -I 64 -l 100%FREE -n hanadata vgdata

ilog=`pvs | grep vglog | wc -l`
lvcreate -i $ilog -I 32 -l 100%FREE -n hanalog vglog

lvcreate -l +100%FREE -n hanabackup vgbackup
lvcreate -l 100%FREE -n hanasap vgsap
lvcreate -l 100%FREE -n hanashared vgshared

# formating FS
lvscan | awk '{print $2}' | tr -d "'" >/tmp/ftab
for i in `cat /tmp/ftab`; do mkfs.xfs $i; done

# Creating directories
mkdir /hana /hana/shared /hana/data /hana/backup /hana/log

# Make permanent mountpoints
if [ $(grep hana /etc/fstab| wc -l) -gt 0 ]; then
echo "It seems file exports were already exists"
else
echo "Exporting Hana File Systems"
cp -ip /etc/fstab  /tmp/fbackup.`date +%Y%m%d-%H%M%S`

cat <<EOF>> /etc/fstab
/dev/vgsap/hanasap      /usr/sap xfs defaults 0 0
/dev/vgdata/hanadata    /hana/data xfs defaults 0 0
/dev/vglog/hanalog      /hana/log xfs defaults 0 0
/dev/vgshared/hanashared        /hana/shared xfs defaults 0 0
/dev/vgbackup/hanabackup        /hana/backup xfs defaults 0 0
EOF
fi
# Mounting File systems
mount -a
if [ $? -ne 0 ]; then
echo "File Systems did not mounted successfully ..! please validate the file systems manually"
else
echo ""
echo "File Systems have been mounted successfully"
echo "Below File Systems have been successfully mounted"
df -Th | grep xfs

fi

rm -f /tmp/busy /tmp/all /tmp/pvs /tmp/ftab
