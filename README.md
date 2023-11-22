Script will run on both hnx and hsx server, and hostname of these servers must contain "hnx" or "hsx"
Requires:
	- Tested on Ubuntu 20
	- Script must run as root
	- This script must place in: /opt/apps/script/ so this path must be valid: /opt/apps/script/sftp_krx.sh

Adding directly to /etc/crontab file:
 30 18 * * 1-6 root sh /opt/apps/script/sftp_krx.sh | tee -a /opt/apps/script/logs/sftp_krx.log
Specific these values in SET PARAM block:
	hnx (ip1, ip2)
	hsx (ip1, ip2)
	sftp username
	sftp password
	sftp_path

