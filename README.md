1. Script will run on both HNX and HSX server.   
2. Requires:    
	- Tested on Ubuntu 20    
	- Script must run as root    
	- This script must place in: /opt/apps/script/ so this path must be valid: /opt/apps/script/sftp_krx.sh
	- Server hostname should contains "hnx" or "hsx" for detecting working server  
    
3. Adding directly to /etc/crontab file:    
 _30 18 * * 1-6 root sh /opt/apps/script/sftp_krx.sh | tee -a /opt/apps/script/logs/sftp_krx.log_
    
4. Specific these values in SET PARAM block:    
	- hnx ($ip1, $ip2)    
	- hsx ($ip1, $ip2)    
	- sftp $username    
	- sftp $password    
	- $sftp_path    

  
