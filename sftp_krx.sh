#!/bin/sh
#
#NBH
#Script will run on both hnx and hsx server, and hostname of these servers must contain "hnx" or "hsx%0A"
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

OUTPUT=""
OUTPUT=${OUTPUT}"===========================================%0A"
OUTPUT=${OUTPUT}"=========== KRX SFTP DOWNLOADER ===========%0A"
OUTPUT=${OUTPUT}"===========================================%0A"
OUTPUT=${OUTPUT}"%0A"


### LOCALE
# We recommend that system date format is set to 24 hours
#
c_hour=$(date +%H)
c_minute=$(date +%M)

if ! grep -q "LC_TIME=\"C.UTF-8\"" /etc/default/locale
then
	OUTPUT=${OUTPUT}$(date +%T)": System date format is not set to 24 hours. We recommend to use 24 hours format for this script working perfectly.%0A"
	OUTPUT=${OUTPUT}$(date +%T)": Modify LC_TIME....%0A"
	OUTPUT=${OUTPUT}"LC_TIME=\"C.UTF-8\"" | tee -a /etc/default/locale
fi
OUTPUT=${OUTPUT}"%0A"

### SET PARAM
# We check working server base on server hostname. So hostname must content "hnx" or "hsx" to continue this script.
# Or you can declare other string to differentiate HNX and HSX server, depend on your hostname.
# total_files_download is number of file that you downloaded everyday. script will check number of file after download and compare to this value.
# sftp_path is woking directory path of sftp, normaly is /opt/apps/sftp (not include / at the end)
# script_path is location of this script (not include / at the end)

total_files_download_hnx=9 		###Changeable
total_files_download_hsx=10 		###Changeable
sftp_path=/opt/apps/sftp 		###Changeable
script_path=/opt/apps/script 		###Changeable
logs_path=/opt/apps/script/logs 	###Changeable

hostname=$(hostname)
success=1

if [ ${success} = 1 ]
then
	if echo ${hostname} | grep "hnx" 	###Changeable
	then
	        ## Working server us HNX
	        ## hnx (ip1, ip2)
	        OUTPUT=${OUTPUT}$(date +%T)": Working server is HNX...%0A"
	        ip1=172.24.253.15 		###Changeable
	        ip2=172.24.253.16 		###Changeable
	        sftp_password=xftp00014! 	###Changeable
	        sftp_username=xftp00014 	###Changeable
	        total_files_download=${total_files_download_hnx}
	elif echo ${hostname} | grep "hsx" 	###Changeable
	then
	        ## Working server is HSX
	        ## hsx (ip1, ip2)
	        OUTPUT=${OUTPUT}$(date +%T)": Working server is HSX...%0A"
	        ip1=172.24.251.15 		###Changeable
	        ip2=172.24.251.16 		###Changeable
	        sftp_password=oftp00014! 	###Changeable
	        sftp_username=oftp00014 	###Changeable
	        total_files_download=${total_files_download_hsx}
	else
	        OUTPUT=${OUTPUT}$(date +%T)": Cannot run this script on other server. Exitting....%0A"
		success=-1
	fi

	OUTPUT=${OUTPUT}"%0A"
	OUTPUT=${OUTPUT}$(date +%T)": - SFTP IP 1: ${ip1}%0A"
	OUTPUT=${OUTPUT}$(date +%T)": - SFTP IP 2: ${ip2}%0A"
	OUTPUT=${OUTPUT}$(date +%T)": - Number of file expected: ${total_files_download}%0A"
	OUTPUT=${OUTPUT}$(date +%T)": - SFTP local path: ${sftp_path}%0A"
	OUTPUT=${OUTPUT}$(date +%T)": - Script location: ${sftp_path}%0A"
	OUTPUT=${OUTPUT}"%0A"
fi

### REMOVE CURRENT CRON JOB
# Get current time: hour and minute for cron
# Round minute for crontab. We just create and check crontab at every 30 minutes.
# check if system date format is 24 hours

if [ ${c_minute} -ge 30 ]
then
	c_minute_round_pass=30
	c_minute_round_fu=00
else
	c_minute_round_pass=00
	c_minute_round_fu=30
fi
if [ ${success} = 1 ]
then
	if grep -q "auto_crontab_download" /etc/crontab
	then
		#remove auto genarate crontab. we will re-gen later if download failed.
		#backup crontab file also
		OUTPUT=${OUTPUT}"===========================================%0A"
	        cp /etc/crontab /etc/crontab.${c_hour}${c_minute}.bk
		OUTPUT=${OUTPUT}$(date +%T)": Attempt to run auto_crontab: ${c_hour}:${c_minute_round_pass}%0A"
		awk '!/auto_crontab_download/' /etc/crontab > ~/auto_cron_temp && mv ~/auto_cron_temp /etc/crontab
	fi
fi


### CHECK CONNECTION
# Check connection by telnet ssh port 22
if [ ${success} = 1 ]
then
	nc -z -w5 ${ip1} 22
	if [ $? = 0 ]
	then
		OUTPUT=${OUTPUT}$(date +%T)": Connected to HSX IP 15.%0A"
		ip=${ip1}
		success=1
	else
		OUTPUT=${OUTPUT}$(date +%T)": Connect to HSX IP 15 failed. Try to connect HSX IP 16.%0A"
		nc -z -w5 ${ip2} 22
		if [ $? = 0 ]
		then
			OUTPUT=${OUTPUT}$(date +%T)": Connected to HSX IP 16.%0A"
			ip=${ip2}
			success=1
		else
			OUTPUT=${OUTPUT}$(date +%T)": Connect to HSX failed. Try to reconnect after 30 minutes.%0A"
			success=0
		fi
	fi
fi
OUTPUT=${OUTPUT}"%0A"


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
	OUTPUT=${OUTPUT}$(date +%T)": Start download file from ${ip}....%0A"
	export SSHPASS=${sftp_password}

	folder=${sftp_path}/${date}

	OUTPUT=${OUTPUT}"%0A"
	OUTPUT=${OUTPUT}"==== Download sftp file day ${date} ====%0A"
	OUTPUT=${OUTPUT}"%0A"

	if [ ! -d ${folder} ]
	then
		mkdir ${folder} -p
		OUTPUT=${OUTPUT}$(date +%T)": Mkdir :${folder}%0A"
	fi

	OUTPUT=${OUTPUT}$(date +%T)": Start download file:%0A"
	sshpass -e sftp -oStrictHostKeyChecking=accept-new -oBatchMode=no -b - ${sftp_username}@${ip} <<-EOF
		cd download
		mget *${date}.TXT ${folder}/
		mget ${date}/*.TXT ${folder}/
		bye
	EOF

	chown -R vgaia.vgaia ${folder}
	OUTPUT=${OUTPUT}"%0A"
	OUTPUT=${OUTPUT}$(date +%T)": Done%0A"
fi
OUTPUT=${OUTPUT}"%0A"

### CHECK FILES EXIST
# If files are not exist, add crontab to redownload later.
# We also check if total files after download are less then ${total_files_download}
# If you dont want to redownload, just add comment out these lines by adding # at every first line.
if [ ${success} = 1 ]
then
	numfile=$(ls ${folder} | wc -l)
	OUTPUT=${OUTPUT}$(date +%T)": Number of file after download: ${numfile}%0A"
	if [ ${numfile} -lt ${total_files_download} ]
	then
		OUTPUT=${OUTPUT}$(date +%T)": Missing file in SFTP folder. Try to redownload later...%0A"
		success=0
	fi
fi

### GENERATE NEW CRONTAB
# Create new crontab if all above checks are failed
# Last cron job will be created at 7h30 AM everydat. After that, this loop will be stopped even files are downloaded or not.

if [ ${success} = 0 ]
then
	if [ ${c_hour} -ge 7 ] && [ ${c_hour} -lt 18 ]
	then
		OUTPUT=${OUTPUT}$(date +%T)": Cannot download file SFTP. Check log file for more detail...%0A"
	else
		OUTPUT=${OUTPUT}$(date +%T)": Adding new crontab....%0A"
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
		echo "${c_minute_round_fu} ${c_hour_new} * * 1-6 root sh ${script_path}/sftp_krx.sh #auto_crontab_download" | tee -a /etc/crontab
	fi
elif [ ${success} = 1 ]
then
	listfile=$(ls -l ${folder}/*)
        OUTPUT=${OUTPUT}$(date +%T)": Download file complete.....%0A"
        OUTPUT=${OUTPUT}"%0A"
        OUTPUT=${OUTPUT}$(date +%T)": Exiting.....%0A"
        OUTPUT=${OUTPUT}"%0A"
else
	OUTPUT=${OUTPUT}"%0A"
	OUTPUT=${OUTPUT}$(date +%T)": Exiting.....%0A"
	OUTPUT=${OUTPUT}"%0A"
fi
OUTPUT=${OUTPUT}"%0A"
OUTPUT=${OUTPUT}"%0A"


### OUTPUT SETTING
# Defaul is output to log file
# Optional is send message to telegram or email.
# Create logs folder if not exist
#
if [ ! -d ${logs_path} ]
then
	mkdir ${logs_path} -p
fi

echo ${OUTPUT} | sed -r 's/%0A/\n/g' | tee -a ${logs_path}/krx.sftp.log

# Telegram
CHAT_TOKEN=""
CHAT_ID=""
curl -s -X POST https://api.telegram.org/bot$CHAT_TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$OUTPUT" > /dev/null

# Email
