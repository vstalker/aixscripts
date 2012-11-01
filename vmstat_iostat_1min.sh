#!/bin/ksh93
for ((I=0;$I<1;I=$I+1));do 
  /usr/local/sbin/iostat_1min.sh >> /var/sys/log/iostat_1min.log \
                               2>> /var/sys/log/iostat_1min.stderr.log &
  /usr/local/sbin/vmstat_1min.sh
done >> /var/sys/log/vmstat_iostat_1min.log \
    2>> /var/sys/log/vmstat_iostat_1min.stderr.log
