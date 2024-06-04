col name format a7
clear breaks
clear computes

select name
,      round(space_limit / 1024 / 1024) space_limit_mb
,      round(space_used  / 1024 / 1024) space_used_mb
,      percent_space_used
,      percent_space_reclaimable
,      percent_space_not_reclaimable
from v$recovery_file_dest
,    ( select sum(percent_space_reclaimable)                      percent_space_reclaimable
       ,      sum(percent_space_used)                             percent_space_used
       ,      sum(percent_space_used - percent_space_reclaimable) percent_space_not_reclaimable
       from  v$recovery_area_usage)
order by name
/
