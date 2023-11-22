#!/bin/sh
#
#NBH
#Script will run on both hnx and hsx server, and hostname of these servers must contain "hnx" or "hsx"
#Requires:
#	- Tested on Ubuntu 20
#	- Script must run as root
#
#Adding directly to /etc/crontab file (change the path if needed):
# 30 18 * * 1-6 root sh /opt/apps/script/sftp_krx.sh | tee -a /opt/apps/script/logs/sftp_krx.log
#Specific these values in SET PARAM block:
#	hnx (ip1, ip2)
#	hsx (ip1, ip2)
#	sftp username
#	sftp password
#	sftp_path
#


echo "==========================================="
echo "=========== KRX SFTP DOWNLOADER ==========="
echo "==========================================="
echo ""

### SET PARAM
# We check working server base on server hostname. So hostname must content "hnx" or "hsx" to continue this script.
# Or you can declare other string to differentiate HNX and HSX server, depend on your hostname.
# total_files_download is number of file that you downloaded everyday. script will check number of file after download and compare to this value.
# sftp_path is woking directory path of sftp, normaly is /opt/apps/sftp (not include / at the end)
# script_path is location of this script (not include / at the end)

total_files_download_hnx=9

total_files_download_hsx=10

sftp_path=/opt/apps/sftp

script_path=/opt/apps/script

hostname=$(hostname)

if echo ${hostname} | grep "hnx"
then
        ## Working server us HNX
        ## hnx (ip1, ip2)
        echo $(date +%r)": Working server is HNX..."
        ip1=172.24.253.15
        ip2=172.24.253.16
        sftp_password=xftp00014!
        sftp_username=xftp00014
        total_files_download=${total_files_download_hnx}
elif echo ${hostname} | grep "hsx"
then
        ## Working server is HSX
        ## hsx (ip1, ip2)
        echo $(date +%r)": Working server is HSX..."
        ip1=172.24.251.15
        ip2=172.24.251.16
        sftp_password=oftp00014!
        sftp_username=oftp00014
        total_files_download=${total_files_download_hsx}
else
        echo $(date +%r)": Cannot run this script on other server. Exitting...."
	sleep 2
        exit
fi
echo $(date +%r)": - SFTP IP 1: ${ip1}"
echo $(date +%r)": - SFTP IP 2: ${ip2}"
echo $(date +%r)": - Number of file expected: ${total_files_download}"
echo $(date +%r)": - SFTP local path: ${sftp_path}"
echo $(date +%r)": - Script location: ${sftp_path}"
echo ""

### REMOVE CURRENT CRON JOB
# Get current time: hour and minute for cron
# Round minute for crontab. We just create and check crontab at every 30 minutes.
# check if system date format is 24 hours
if ! grep -q "LC_TIME=\"C.UTF-8\"" /etc/default/locale
then
	echo $(date +%r)": System date format is not set to 24 hours. We recommend to use 24 hours format for this script working perfectly."
	echo $(date +%r)": Modify LC_TIME...."
	echo "LC_TIME=\"C.UTF-8\"" | tee -a /etc/default/locale
fi
echo ""
c_hour=$(date +%H)
c_minute=$(date +%M)

if [ ${c_minute} -ge 30 ]
then
	c_minute_round_pass=30
	c_minute_round_fu=00
else
	c_minute_round_pass=00
	c_minute_round_fu=30
fi

if grep -q "auto_crontab_reconnect" /etc/crontab
then
	#remove auto genarate crontab. we will re-gen later if download failed.
	#backup crontab file also
	echo "==========================================="
        cp /etc/crontab /etc/crontab.${c_hour}${c_minute}.bk
	echo $(date +%r)": Attempt to run auto_crontab: ${c_hour}:${c_minute_round_pass}"
	awk '!/auto_crontab/' /etc/crontab > ~/auto_cron_temp && mv ~/auto_cron_temp /etc/crontab
	awk '!/auto_crontab_reconnect/' /etc/crontab > ~/auto_cron_temp && mv ~/auto_cron_temp /etc/crontab
fi

### CHECK CONNECTION
# Check connection by telnet ssh port 22
nc -z -w5 ${ip1} 22
if [ $? = 0 ]
then
	echo $(date +%r)": Connected to HSX IP 15."
	ip=${ip1}
	success=1
else
	echo $(date +%r)": Connect to HSX IP 15 failed. Try to connect HSX IP 16."
	nc -z -w5 ${ip2} 22
	if [ $? = 0 ]
	then
		echo $(date +%r)": Connected to HSX IP 16."
		ip=${ip2}
		success=1
	else
		echo $(date +%r)": Connect to HSX failed. Try to reconnect after 30 minutes."
		success=0
	fi
fi
echo ""
### DOWNLOAD FILES
# Download files first even files are exist or not.
# We download files first, then check if files are exist or not later.
# If Script delay till next day, set date to last date

if [ ${c_hour} -ge 0 ] && [ ${c_hour} -le 8 ]
then
	date=$(date -d '-1 day' '+%Y%m%d')
else
	date=$(date '+%Y%m%d')
fi

if [ ${success} = 1 ]
then
	echo $(date +%r)": Start download file from ${ip}...."
	export SSHPASS=${sftp_password}

	folder=${sftp_path}/${date}

	echo ""
	echo "==== Download sftp file day ${date} ===="
	echo ""

	if [ ! -d ${folder} ]
	then
		mkdir ${folder} -p
		echo $(date +%r)": Mkdir :${folder}"
	fi

	echo $(date +%r)": Start download file:"
	sshpass -e sftp -oStrictHostKeyChecking=accept-new -oBatchMode=no -b - ${sftp_username}@${ip} <<-EOF
		cd download
		mget ${date}/*.TXT ${folder}/
#		mget *${date}.TXT ${folder}/
		bye
	EOF

	chown -R vgaia.vgaia ${folder}
	echo ""
	echo $(date +%r)": Done"
fi
echo ""

### CHECK FILES EXIST
# If files are not exist, add crontab to redownload later.
# We also check if total files after download are less then ${total_files_download}
# If you dont want to redownload, just add comment out these lines by adding # at every first line.
if [ ${success} = 1 ]
then
	numfile=$(ls ${folder} | wc -l)
	echo $(date +%r)": Number of file after download: ${numfile}"
	if [ ${numfile} -lt ${total_files_download} ]
	then
		echo $(date +%r)": Missing file in SFTP folder. Try to redownload later..."
		success=0
	fi
fi

### GENERATE NEW CRONTAB
# Create new crontab if all above checks are failed
# Last cron job will be created at 7h30 AM everydat. After that, this loop will be stopped even files are downloaded or not.

if [ ${success} = 0 ]
then
	if [ ${c_hour} -ge 8 ] && [ ${c_hour} -lt 18 ]
	then
		echo $(date +%r)": Cannot download file through SFTP. Check log file for more detail..."
	else
		echo $(date +%r)": Adding new crontab...."
		if [ ${c_minute_round_pass} -eq 30 ]
		then
			c_hour_new=$((${c_hour}+1))
   			if [ ${c_hour_new} -eq 24 ]
      			then
				c_hour_new=00
  			fi
		else
			c_hour_new=${c_hour}
		fi
		echo "#auto_crontab_reconnect" | tee -a /etc/crontab
		echo "${c_minute_round_fu} ${c_hour_new} * * 1-6 root sh ${script_path}/sftp_krx.sh | tee -a ${script_path}/logs/auto_crontab.log" | tee -a /etc/crontab
		# Create log folder if not exist
		if [ ! -d ${script_path}/logs ]
		then
			mkdir ${script_path}/logs/ -p
		fi
	fi
else
        echo $(date +%r)": Download file complete....."
        echo $(date +%r)": Exiting....."
        echo ""
fi
echo ""
echo ""
