1. Script will run on both HNX and HSX server.   
2. Requires:    
	- Tested on Ubuntu 20    
	- Script must run as root    
	- Server hostname should contains "hnx" or "hsx" for detecting working server  
    
3. Specific these values in SET PARAM block:    
	- hnx ($ip1, $ip2)    
	- hsx ($ip1, $ip2)    
	- sftp $username    
	- sftp $password    
	- $sftp_path  
        - $script_path 
    
4. To use just adding directly to /etc/crontab file (change the path if needed):    
 _30 18 * * 1-6 root sh /opt/apps/script/sftp_krx.sh | tee -a /opt/apps/script/logs/sftp_krx.log_

  
