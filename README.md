1. Script will run on both HNX and HSX server.
2. If sever cannot connect to both SFTP server (ip 15 and 16), or connected but folder is empty, or number of files after download is not enough as expected:  
        - Auto create cron job and reconnect/redownload after every 30 minutes. These cron job will be remove if download complete.  
        - Script will run from start (18h30 as we specify) to 8h30 next day. After that, this will stop create cron job at last run.
3. Requires:    
	- Tested on Ubuntu 20    
	- Script must run as root    
	- Server hostname should contains "hnx" or "hsx" for detecting working server  
    
4. Specific these values in SET PARAM block:    
	- hnx ($ip1, $ip2)    
	- hsx ($ip1, $ip2)    
	- sftp $username    
	- sftp $password    
	- $sftp_path  
	- $script_path  
    
5. To use just adding directly to /etc/crontab file (change the path if needed):    
 _30 18 * * 1-6 root sh /opt/apps/script/sftp_krx.sh | tee -a /opt/apps/script/logs/sftp_krx.log_

  
