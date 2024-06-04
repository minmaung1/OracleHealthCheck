# Automated-Healthcheck
This is a sample script to perform automated health check for Oracle EBusiness Application &amp; Database

The output will be in readable HTML format. 

You can customize the script, add additional SQL scripts(to check temporary tablespace, active concurrent requests, concurrent manager status, tablespace check,etc)

You can schedule this in crond like below

################################### PROD HEALTHCHECK ############################
00 04,08,12,16,20,23  * * * sh /home/oracle/PROD_auto_Health_check.sh > /dev/null 2>&1
