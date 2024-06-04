##################### THIS SCRIPT IS TO PERFORM AUTOMATED HEALTH CHECK  ###############################################
#                                                                                                                     #
#######################################################################################################################

export yesterday=`date --date="-1 day"`
export ORACLE_SID=PROD1
export ORACLE_HOME=/u01/PROD/oracle/db/tech_st/11.2.0.4/db_1
export PATH=$PATH:$ORACLE_HOME/bin
LOG=/home/oracle/scripts/Healthcheck/healthcheck_mail_`date +\%d\%b\%y`.html
echo "<html>" > $LOG
echo "<BODY LANG="en-US" DIR="LTR">" >> $LOG

rm $LOG

echo "<h3 ALIGN=CENTER > PROD HEALTHCHECK REPORT ON `date`    </h3>" >>$LOG


echo "<table WIDTH=100% BORDER=1 BORDERCOLOR="#000000" CELLPADDING=4 CELLSPACING=0>" >>$LOG
echo "<tr><td bgcolor=#ADD8E6><b>HEALTH CHECK ITEMS</b></td><td bgcolor=#ADD8E6><b>Check the corresponding output below</b></td><td bgcolor=#ADD8E6><b>COMMENTS</b></td></tr>" >> $LOG

############################################## CHECK DATABASE IS UP AND RUNNING #################################################################################
PROD_DB_STATUS=`ps -ef|grep pmon|grep "PROD1"|wc -l`
if [[ $PROD_DB_STATUS -eq 1 ]]; then
echo "<tr><td <b>EBS DATABASE</b></td><td><b>`ps -ef|grep pmon|grep "PROD1"|grep -v grep`</b></td><td>EBS Database is up and running</td></tr>" >> $LOG
else
echo "<tr><td <b>EBS DATABASE</b></td><td bgcolor=#FF0000><b>PROD database is not up and running on `hostname`</b></td><td>Bring up the EBS database</td></tr>" >> $LOG
fi

############################################## CHECK LISTENER IS UP AND RUNNING #################################################################################
PROD_LISTENER_STATUS=`ps -ef|grep tns|grep "LISTENER_DB01"|wc -l`
if [[ $PROD_LISTENER_STATUS -eq 1 ]]; then
echo "<tr><td <b>PROD LISTENER</b></td><td><b>`ps -ef|grep tns|grep "LISTENER_DB01"|grep -v grep`</b></td><td>Listener is up and running</td></tr>" >> $LOG
else
echo "<tr><td <b>PROD LISTENER</b></td><td bgcolor=#FF0000><b>PROD01 LISTENER is not up and running on `hostname`</b></td><td>Bring up the EBS LISTENER</td></tr>" >> $LOG
fi

echo "</table>" >> $LOG

##################################################################################################################################################################
echo "<h3 ALIGN=LEFT >  OS Load  on `hostname`     </h3>" >> $LOG

echo "<h2 ALIGN=LEFT >  `uptime`     </h2>" >> $LOG

echo "<h3 ALIGN=LEFT >  Free memory on `hostname`     </h3>" >> $LOG

echo "<h2 ALIGN=LEFT >  `egrep --color 'Mem|Cache|Swap' /proc/meminfo  | awk 'BEGIN{ print("<table border=1><tr>") }
{
for ( i = 1; i<=NF ; i++ ) {
printf "<td> %s </td> ", $i
}
print "</tr>"
}
END{
print("</table>")
}'` </h2>"  >> $LOG

echo "<h3 ALIGN=LEFT >  DISK USAGE on `hostname`     </h3>" >> $LOG

echo "<h2 ALIGN=LEFT >  `df -Ph | column -t | sed 's/</\&lt;/g; s/>/\&gt;/g' | awk 'BEGIN{print("<table>")}{print("<tr><td>",$1,"</td><td>",$2,"</td><td>",$3,"</td><td>",$4,"</td><td>",$5,"</td><td>",$6,$7,"</td></tr>")}END{print("</table>")}'` </h2>"  >> $LOG

############################################## DATABASE CONNECTIVITY CHECK ##################################################################################################

echo "<h3 ALIGN=LEFT >   DATABASE CONNECTIVITY CHECK   </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
select name,open_mode,log_mode,DATABASE_ROLE from v\$database;
exit
EOF


############################################## TABLESPCAE CHECK ##################################################################################################
echo "<h3 ALIGN=LEFT >   TABLESPACE CHECK   </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
@/home/oracle/scripts/Healthcheck/autofree.sql
exit
EOF

############################################# TEMP TABLESPACE ################################################################
echo "<h3 ALIGN=LEFT >   TEMP TABLESPACE CHECK   </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
@/home/oracle/scripts/Healthcheck/temp_tbs.sql
exit
EOF

############################################# INVALID OBJECTS  ################################################################
echo "<h3 ALIGN=LEFT >   INVALID OBJECT COUNT   </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
select count(*) from dba_objects where status ='INVALID';
exit
EOF

############################################# WORKFLOW STATUS  ################################################################
echo "<h3 ALIGN=LEFT >   WORKFLOW COMPONENT STATUS   </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
SELECT component_name, component_status, component_status_info
FROM apps.fnd_svc_components_v
WHERE component_name like 'Workflow%';
exit
EOF

############################################# CHECK CONCURRENT MANAGER STATUS  ################################################################
echo "<h3 ALIGN=LEFT >   CONCURRENT MANAGER STATUS   </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
@/home/oracle/scripts/Healthcheck/cm_status.sql
exit
EOF

############################################# CHECK Periodic Alert Scheduler Request Status  ################################################################
echo "<h3 ALIGN=LEFT >   Periodic Alert Scheduler Request last Run   </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
@/home/oracle/scripts/Healthcheck/Periodic_Alert_Check.sql
exit
EOF

############################################# CHECK CONCURRENT REQUEST STATUS  ################################################################
echo "<h3 ALIGN=LEFT >   CONCURRENT JOBS RUNNING NOW   </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
@/home/oracle/scripts/Healthcheck/cmrun.sql
exit
EOF


chmod 777 /home/oracle/scripts/Healthcheck/healthcheck_mail*

export MAILTO="emailaddress@domain"
export CONTENT="/home/oracle/scripts/Healthcheck/healthcheck_mail_`date +\%d\%b\%y`.html"
export SUBJECT="PROD HEALTHCHECK REPORT ON `date`  "
(
 echo "Subject: $SUBJECT"
 echo "MIME-Version: 1.0"
 echo "Content-Type: text/html"
 echo "Content-Disposition: inline"
 echo "To: $MAILTO"
 cat $CONTENT
) | /usr/sbin/sendmail -t $MAILTO