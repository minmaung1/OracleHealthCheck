##################### THIS SCRIPT IS TO PERFORM AUTOMATED HEALTH CHECK ON STANDBY ###########################
# # Modification History
# ====================
# Who                 Ver.  When      What
# ===                 ====  ====      ====
# MinMaung      1.0   04-May-21  Creation
#
#######################################################################################################################

dt=$(date +%Y.%m.%d-%H.%M.%S)
SCRIPT_LOC=/backup/scripts/HC_scripts
LOG=/backup/scripts/HC_scripts/Healthcheck/healthcheck_mail_`date +\%d\%b\%y`.html

echo "<h3 ALIGN=CENTER > DR HEALTHCHECK REPORT ON `date`    </h3>" >>$LOG

########################################################################################################


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

echo "<h2 ALIGN=LEFT >  `df -Ph /u01 /fra /data /backup /acfs | column -t | sed 's/</\&lt;/g; s/>/\&gt;/g' | awk 'BEGIN{print("<table>")}{print("<tr><td>",$1,"</td><td>",$2,"</td><td>",$3,"</td><td>",$4,"</td><td>",$5,"</td><td>",$6,$7,"</td></tr>")}END{print("</table>")}'` </h2>"  >> $LOG

############################################## DR - Siebel STATUS ####################################################################################
export ORACLE_HOME=/u01/app/oracle/product/19.0/dbhome_1
export ORACLE_SID=SPROD
export PATH=$ORACLE_HOME/bin:$PATH
echo "<h3 ALIGN=LEFT >   DR - Siebel Database Status   </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
@/backup/scripts/HC_scripts/standby_status.sql
exit
EOF

############################### DR - Siebel Gap Status  ###########################################################
echo "<h3 ALIGN=LEFT > DR - Siebel Gap Status </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
@/backup/scripts/HC_scripts/gap.sql
exit
EOF

############################### DR - Siebel LAG Check  ###########################################################
echo "<h3 ALIGN=LEFT > DR - Siebel LAG Check </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
@/backup/scripts/HC_scripts/lag_check.sql
exit
EOF

############################################# DR - Siebel MRP STATUS  ####################################################################################
echo "<h3 ALIGN=LEFT > DR - Siebel MRP Status</h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
column group# format a10
select process, thread#, sequence#, status from v\$managed_standby where process in ('MRP0');
exit
EOF


############################################## DR - Siebel FRA utilization  ####################################################################################
echo "<h3 ALIGN=LEFT >   DR - Siebel FRA utilization   </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
@/backup/scripts/HC_scripts/fra_check.sql
exit
EOF


########################################## DR - EBS Database Status ################################################################################
export ORACLE_SID=EPROD
export ORACLE_HOME=/u01/app/oracle/EPROD/db/tech_st/19c
export PATH=$ORACLE_HOME/bin:$PATH

echo "<h3 ALIGN=LEFT >   DR - EBS Database Status   </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
@/backup/scripts/HC_scripts/standby_status.sql
exit
EOF

############################### DR - EBS Gap Status  ###########################################################
echo "<h3 ALIGN=LEFT > DR - EBS Gap Status </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
@/backup/scripts/HC_scripts/gap.sql
exit
EOF

############################### DR - EBS Standby Redo Log Status  ###########################################################
#echo "<h3 ALIGN=LEFT > DR - EBS Standby Redo log STATUS </h3>" >> $LOG
#sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
#SELECT thread#, group#, sequence#, bytes, archived, status FROM v\$standby_log order by thread#, group#;
#exit
#EOF

############################### DR - EBS LAG Check  ###########################################################
echo "<h3 ALIGN=LEFT > DR - EBS LAG Check </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
@/backup/scripts/HC_scripts/lag_check.sql
exit
EOF


############################################# DR - EBS MRP STATUS  ####################################################################################
echo "<h3 ALIGN=LEFT > DR - EBS MRP Status</h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
column group# format a10
--select process,status,group#,thread#,sequence# from v\$managed_standby;
select process, thread#, sequence#, status from v\$managed_standby where process in ('MRP0');
exit
EOF

############################################## EBS RMAN BACKUP STATUS  ####################################################################################
#echo "<h3 ALIGN=LEFT > EBS RMAN BACKUP STATUS for last 5 DAYS   </h3>" >> $LOG
#sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
#@/backup/scripts/HC_scripts/rman_backup_status.sql
#exit
#EOF

############################################## EBS FRA utilization  ####################################################################################
echo "<h3 ALIGN=LEFT >   DR - EBS FRA utilization   </h3>" >> $LOG
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" / as sysdba << EOF  >>$LOG
@/backup/scripts/HC_scripts/fra_check.sql
exit
EOF

chmod 777 /backup/scripts/HC_scripts/Healthcheck/healthcheck_mail_*

export MAILTO="email@domain email2@domain"
export CONTENT="/backup/scripts/HC_scripts/Healthcheck/healthcheck_mail_`date +\%d\%b\%y`.html"
export SUBJECT="DR HEALTHCHECK REPORT ON `date`  "
#(
# echo "Subject: $SUBJECT"
# echo "MIME-Version: 1.0"
# echo "Content-Type: text/html"
# echo "Content-Disposition: inline"
# echo "To: $MAILTO"
# cat $CONTENT
#) | /usr/sbin/sendmail -t $MAILTO


mailx -a $CONTENT -s "$SUBJECT" $MAILTO < /dev/null
mv $LOG /backup/scripts/HC_scripts/Healthcheck/archive_reports/healthcheck_mail_${dt}.html
