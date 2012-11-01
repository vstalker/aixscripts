#!/bin/ksh93
# Version 1.1
rm=/usr/bin/rm
grep=/usr/bin/grep
date=/usr/bin/date
perl=/usr/bin/perl
tail=/usr/bin/tail
D=`$date +"%d"`
HOUR=$($date +"%H")
MINUTE=$($date +"%M")
DATE=$($date +"%Y-%m-%d")
if [ "x"${HOUR}${MINUTE} = "x0000" -o "x"${HOUR}${MINUTE} = "x0001" ]
then
  $tail -1 /var/adm/sa/iostat$D | $grep -v ^$DATE > /dev/null \
  && $rm -f /var/adm/sa/iostat$D
fi
/usr/local/sbin/iostat_1min.pl >> /var/adm/sa/iostat$D \
                             2>> /var/sys/log/iostat_1min.pl.log
