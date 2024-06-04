set lines 200
col source_db_unique_name format a20
col value format a20
SELECT name,value,time_computed
 FROM v$dataguard_stats
 WHERE name like '%lag';
