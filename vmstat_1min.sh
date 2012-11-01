#!/bin/ksh93
# Version 1.1
rm=/usr/bin/rm
awk=/usr/bin/awk
sed=/usr/bin/sed
date=/usr/bin/date
grep=/usr/bin/grep
tail=/usr/bin/tail
vmstat=/usr/bin/vmstat
TIMESTAMP=$($date +"%Y-%m-%d %H:%M:%S")
VMSTATRES=$($vmstat 1 59|$sed -e 's/^ *//'|$awk '
BEGIN { max_nf = 0; max_nr = 0; }
$2 ~ /[0-9]+/ && $3 ~ /[0-9]+/ {
  if (max_nf < NF)
    max_nf = NF;
  max_nr++;
  for (i = 1; i <= NF; i++) {
    a[max_nr,i] = $i;
    b[i] = 0;
  }
}
END {
  for (x = 1; x <= max_nr; x++)
    for (y = 1; y <= max_nf; y++)
          b[y] = b[y] + a[x, y];
  for (y = 1; y <= max_nf; y++)
    b[y] = b[y] / max_nr;
  for (y = 1; y <= (max_nf-2); y++)
        printf("%d ", b[y]);
  for (z = y; z <= max_nf; z++)
        printf("%3.2f ", b[z]);
  printf("\n");
}')
D=$($date +"%d")
HOUR=$($date +"%H")
MINUTE=$($date +"%M")
DATE=$($date +"%Y-%m-%d")
if [ "x"${HOUR}${MINUTE} = "x0000" -o "x"${HOUR}${MINUTE} = "x0001" ]
then
  $tail -1 /var/adm/sa/vmstat$D | $grep -v ^$DATE > /dev/null \
  && $rm -f /var/adm/sa/vmstat$D
fi
printf "%s %s\n" "$TIMESTAMP" "$VMSTATRES" \
>> /var/adm/sa/vmstat$D
