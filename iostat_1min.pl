#!/usr/bin/perl
# Version 1.1
use POSIX qw(strftime);
my @a = localtime();
my $currdate = printf("%s-%02s-%02s %02s:%02s:%02s",
                      1900 + $a[5], 1 + $a[4], $a[3], $a[2], $a[1], $a[0]);
printf("%s ", $currdate);
my $debug = 0;
my $iostatcmd = '/usr/bin/iostat';
my $iostatargs = ' -T 1 58';
open IOSTAT, sprintf("%s |", $iostatcmd.$iostatargs)
  or die "perl cant run iostat";
my $i = -1;
my %hdisks;
my @tm_act = ();
my @tps = ();
my @Kb_read = ();
my @Kb_wrtn = ();
while(<IOSTAT>) {
  chomp();
  $i++ if (/^Disks:/);
  printf(" \$i: %d", $i) if ($debug > 0);
  if (/^(hdisk\d+) /) {
    my ($hdisk, @tmp1, $time) = split /\s+/;
    push @tpid, @tmp1;
    $hdisks{$hdisk} = [ @tmp1 ];
    printf STDERR (" %s", $1) if ($debug > 0);
    for my $k ( 0 .. $#tmp1 ) {
      printf STDERR (" %d:%s", $k, $hdisks{$hdisk}[$k]) if ($debug > 0);
    }
      $tm_act[$i]{$hdisk} = $hdisks{$hdisk}[0];
      $tps[$i]{$hdisk} = $hdisks{$hdisk}[2];
      $Kb_read[$i]{$hdisk} = $hdisks{$hdisk}[3];
      $Kb_wrtn[$i]{$hdisk} = $hdisks{$hdisk}[4];
  }
  printf("\n") if ($debug > 0);
}
foreach my $hdisk ( sort keys %hdisks ) {
  print "$hdisk".'{';
  my $k = 0;
  printf(" tm_act[%d]:%s ", $k, $tm_act[$k]{$hdisk}) if ($debug > 0);
  printf("tps[%d]:%s ", $k, $tps[$k]{$hdisk}) if ($debug > 0);
  printf("Kb_read[%d]:%s ", $k, $Kb_read[$k]{$hdisk}) if ($debug > 0);
  printf("Kb_wrtn[%d]:%s ", $k, $Kb_wrtn[$k]{$hdisk}) if ($debug > 0);
  for $k ( 1 .. $#tm_act ) {
    printf("tm_act[%d]:%s ", $k, $tm_act[$k]{$hdisk}) if ($debug > 0);
    printf("tps[%d]:%s ", $k, $tps[$k]{$hdisk}) if ($debug > 0);
    printf("Kb_read[%d]:%s ", $k, $Kb_read[$k]{$hdisk}) if ($debug > 0);
    printf("Kb_wrtn[%d]:%s ", $k, $Kb_wrtn[$k]{$hdisk}) if ($debug > 0);
        $tm_act[0]{$hdisk} += $tm_act[$k]{$hdisk};
        $tps[0]{$hdisk} += $tps[$k]{$hdisk};
        $Kb_read[0]{$hdisk} += $Kb_read[$k]{$hdisk};
        $Kb_wrtn[0]{$hdisk} += $Kb_wrtn[$k]{$hdisk};
  }
  $tm_act[0]{$hdisk} /= ($i + 1);
  $tps[0]{$hdisk} /= ($i + 1);
  $Kb_read[0]{$hdisk} /= ($i + 1);
  $Kb_wrtn[0]{$hdisk} /= ($i + 1);
  if ($debug > 0) {
    printf("tm_act:%s ", $tm_act[0]{$hdisk});
    printf("tps:%s ", $tps[0]{$hdisk});
    printf("Kb_read:%s ", $Kb_read[0]{$hdisk});
    printf("Kb_wrtn:%s ", $Kb_wrtn[0]{$hdisk});
  } else {
    printf("%0.2f ", $tm_act[0]{$hdisk});
    printf("%0.2f ", $tps[0]{$hdisk});
    printf("%0.2f ", $Kb_read[0]{$hdisk});
    printf("%0.2f", $Kb_wrtn[0]{$hdisk});

  }
  print "} ";
}
print "\n";
exit(0);
__END__
Disks:        % tm_act     Kbps      tps    Kb_read   Kb_wrtn  time
