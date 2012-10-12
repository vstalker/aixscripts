#!/usr/bin/perl
## -----------------------------------------------------------------------
##
##   Copyright 2012 Victor Skurikhin - All Rights Reserved
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
## -----------------------------------------------------------------------
use Getopt::Std;
getopts('d:ov');

# if debug > 0 then generates debug messages on STDERR
my $debug = 0;
my $verbose = 0;

if ($opt_d) {
  $debug = $opt_d if ($opt_d =~ /^[0-9]{1,2}$/);
  $debug = 1 if ($opt_d =~ /^$/);
}
$oracle = 1 if ($opt_o);
$verbose = 1 if ($opt_v);

printf("debug: %d verbose: %d\n", $debug, $verbose) if ($verbose);

my $k = 0;
my $kernel_inuse_size = 0;
my $kernel_pgsp_size = 0;
my $kernel_virt_size = 0;
my @kernel_sids = ();
my %kernel_inuse_sidsize = {};
my %kernel_virt_sidsize = {};
my $sid = 0;
my $svmon_kern_segs = "svmon -S -O filtercat=kernel,unit=KB";

printf("Exec(\"%s\")\r", $svmon_kern_segs) if ($verbose);
# 
open(SVMON_KERNEL, sprintf("%s |", $svmon_kern_segs))
  or die "perl cant run svmon";
while(<SVMON_KERNEL>) { 
  print STDERR if ($debug > 1);
  chomp;
  my @tmp1 = split / +/;
  if ($tmp1[1] =~ /^[0-9a-f]+$/) {
	$sid = $tmp1[1];
	for my $i ( 2 .. $#tmp1 ) {
	  if ($tmp1[$i] =~ /^(s|m|sm|L)$/ && $tmp1[$i+1] =~ /^[0-9]+$/) {
		my $inuse_sidsize = $tmp1[$i+1];
		my $pgsp_sidsize = $tmp1[$i+3];
		my $virt_sidsize = $tmp1[$i+4];
		printf STDERR "SVMON_KERNEL::kernel_sids[%d] %s %d\n", $k, $sid, $sidsize 
		if ($debug > 0);
		$kernel_sids[$k] = $sid; $k++;
		# creates a "kernel_inuse_sidsize" hash for each segment for the preservation of its size
		$kernel_inuse_sidsize{$sid} = $inuse_sidsize;
		$kernel_inuse_size += $inuse_sidsize;
		$kernel_pgsp_size += $pgsp_sidsize;
		$kernel_virt_size += $virt_sidsize;
		printf("Found %d numbers the kernel segments %20s\r", $k, '')
		if ($verbose);
	  }
	}
  }
}
close(SVMON_KERNEL);
printf("\n") if ($verbose);

my $s = 0;
my $shared_inuse_size = 0;
my $shared_pgsp_size = 0;
my $shared_virt_size = 0;
my @shared_sids = ();
my %shared_inuse_sidsize = {};
my $svmon_shared_segs = "svmon -S -O filtercat=shared,pidlist=on,unit=KB";

printf("Exec(\"%s\")\r", $svmon_shared_segs) if ($verbose);
open(SVMON_SHARED, sprintf("%s |", $svmon_shared_segs))
  or die "perl cant run svmon";
while(<SVMON_SHARED>) { 
  print STDERR if ($debug > 0);
  chomp;
  my @tmp1 = split / +/;
  if ($tmp1[1] =~ /^[0-9a-f]+$/) {
	$sid = $tmp1[1];
	for my $i ( 2 .. $#tmp1 ) {
	  if ($tmp1[$i] =~ /^(s|m|sm|L)$/ && $tmp1[$i+1] =~ /^[0-9]+$/) {
		my $inuse_sidsize = $tmp1[$i+1];
		my $pgsp_sidsize = $tmp1[$i+3];
		my $virt_sidsize = $tmp1[$i+4];
		printf STDERR "SVMON_SHARED::shared_sids[%d] %s %d\n", $s, $sid, $sidsize 
		if ($debug > 0);
		$shared_sids[$s] = $tmp1[1]; $s++;
		# creates a "shared_inuse_sidsize" hash for each segment for the preservation of its size
		$shared_inuse_sidsize{$sid} = $inuse_sidsize;
		$shared_inuse_size += $inuse_sidsize;
		$shared_pgsp_size += $pgsp_sidsize;
		$shared_virt_size += $virt_sidsize;
		printf("Found %d numbers the shared segments %20s\r", $s, '') 
		if ($verbose);
	  }
	}
  }
}
close(SVMON_SHARED);
printf("\n") if ($verbose);

my $pe = 0;
my @procsexcl_sids = ();
my %procsexcl_inuse_sidsize = {};
my $procsexcl_inuse_size = 0;
my $procsexcl_pgsp_size = 0;
my $procsexcl_virt_size = 0;
my $ora_procsexcl_real_size = 0;
my $ora_procsexcl_pgsp_size = 0;
my $ora_procsexcl_virt_size = 0;
my $nora_procsexcl_real_size = 0;
my $nora_procsexcl_pgsp_size = 0;
my $nora_procsexcl_virt_size = 0;
my $svmon_procsexcl_segs = "svmon -P -O filtercat=exclusive,pidlist=on,unit=KB";
my $ps_ew = "ps ew ";
my $sort_by_virt = "sort -r -n +5";

printf("Exec(\"%s\")\n", $svmon_procsexcl_segs) if ($verbose);
open(SVMON_EXCLUSIVE, sprintf("%s|%s|", $svmon_procsexcl_segs, $sort_by_virt))
  or die "perl cant run svmon";
print <<EOH
Exec("svmon -P -O filtercat=exclusive,pidlist=on,unit=KB")
-------------------------------------------------------------------------------
          Pid Command          Inuse      Pin     Pgsp  Virtual
EOH
  if ($verbose);
while(<SVMON_EXCLUSIVE>) { 
  chomp;
  # printf("%s\n",$_) if (/^\s*\d+\s+\w+\s+\d+\s+\d+\s+\d+\s+\d+$/ && $verbose);
 
  if (/^\s*(\d+)\s+(\w+)\s+(\d+)\s+\d+\s+(\d+)\s+(\d+)$/ && $oracle) {
	my $oraclep = 0;
	my $ppid = $1;
    printf("PPid: %s\n", $ppid) if ($debug > 3);
	my $command = $2;
	my $inuse = $3;
    my $pgsp = $4;
	my $virt = $5;
	if ($command =~ /ora/) {
	  $oraclep = 1;	 
    } else {
      open(PS_EW, sprintf("%s %d|", $ps_ew, $ppid))
        or die "perl cant run $ps_ew $ppid";
      foreach $tmpline (<PS_EW>) {
        if ($tmpline =~ /(ora|grid)/) { 
          $oraclep = 1; printf("Found!", $tmpline) if ($debug > 2); 
		}
	  }
      close(PS_EW);
    }
    if ($oraclep) {
      $ora_procsexcl_real_size = $ora_procsexcl_real_size + $inuse;
	  $ora_procsexcl_pgsp_size = $ora_procsexcl_pgsp_size + $pgsp;
	  $ora_procsexcl_virt_size = $ora_procsexcl_virt_size + $virt;
      printf("ORAC:%s %8d %8d %8d\n", $_, $inuse, $pgsp, $virt) if($verbose);
    } else {
      $nora_procsexcl_real_size = $nora_procsexcl_real_size + $inuse;
	  $nora_procsexcl_pgsp_size = $nora_procsexcl_pgsp_size + $pgsp;
	  $nora_procsexcl_virt_size = $nora_procsexcl_virt_size + $virt;
      printf("NORA:%s %8d %8d %8d\n", $_, $inuse, $pgsp, $virt) if($verbose);
	}
  }
  s/^\s*(.*)$/\1/;
  my @tmp1 = split /\s+/;
  printf STDERR "SVMON_EXCLUSIVE::tmp1[0]: %s\n", $tmp1[0] if ($debug > 2);
  if ($tmp1[0] =~ /^[0-9a-f]+$/) {
	$sid = $tmp1[0];
	for my $i ( 1 .. $#tmp1 ) {
	  if ($tmp1[$i] =~ /^(s|m|sm|L)$/ && $tmp1[$i+1] =~ /^[0-9]+$/) {
		my $inuse_sidsize = $tmp1[$i+1];
		my $pgsp_sidsize = $tmp1[$i+3];
		my $virt_sidsize = $tmp1[$i+4];
		printf STDERR "SVMON_EXCLUSIVE::procsexcl_sids[%d] %s %d\n", $pe, $sid, $sidsize
		if ($debug > 2);
		$procsexcl_sids[$pe] = $sid; $pe++;
		# creates a "procsexcl_inuse_sidsize" hash for each segment for the preservation of its size
		$procsexcl_inuse_sidsize{$sid} = $inuse_sidsize;
		$procsexcl_inuse_size += $inuse_sidsize;
		$procsexcl_pgsp_size += $pgsp_sidsize;
		$procsexcl_virt_size += $virt_sidsize;
	  }
	}
  }
}
close(SVMON_EXCLUSIVE);
print <<EOH
-------------------------------------------------------------------------------
EOH
  if ($verbose);
printf("Found %d numbers the process exclusive segments\n", $pe, '')
  if ($verbose);

my $po = 0;
my @procsothers_sids = ();
my %procsothers_inuse_sidsize = {};
my %procsothers_pgps_sidsize = {};
my %procsothers_virt_sidsize = {};
my $svmon_procsoths_segs = "svmon -P -O pidlist=on,unit=KB";
my $sort_by_virt = "sort -r -n +5";

printf("Exec(\"%s\")\r", $svmon_procsoths_segs) if ($verbose);

open(SVMON_OTHERS, sprintf("%s |", $svmon_procsoths_segs))
  or die "perl cant run svmon";
while(<SVMON_OTHERS>) { 
  print STDERR if ($debug > 3);
  chomp;
  my @tmp1 = split / +/;
  if ($tmp1[1] =~ /^[0-9a-f]+$/) {
    $sid = $tmp1[1];
	for my $i ( 2 .. $#tmp1 ) {
	  if ($tmp1[$i] =~ /^(s|m|sm|L)$/ && $tmp1[$i+1] =~ /^[0-9]+$/) {
		my $sidsize = $tmp1[$i+1];
		my $inuse_sidsize = $tmp1[$i+1];
		my $pgsp_sidsize = $tmp1[$i+3];
		my $virt_sidsize = $tmp1[$i+4];
		if ($kernel_sidsize{$sid}) {
          printf STDERR "The array kernel_sidsize contains $sid\n" if ($debug > 0);
		} elsif ($shared_inuse_sidsize{$sid}) {
		  printf STDERR "The array shared_inuse_sidsize contains $sid\n" if ($debug > 0);
        } elsif ($procsexcl_inuse_sidsize{$sid}) {
		  printf STDERR "The array procsexcl_inuse_sidsize contains $sid\n" if ($debug > 0);
        } else {
		  printf STDERR "SVMON_OTHERS::procsothers_sids[%d] %s %d\n", $po, $sid, $sidsize
		  if ($debug > 2);
		  $procsothers_sids[$po] = $sid; $po++;
		  # creates a "procsothers_inuse_sidsize" hash for each segment for the preservation of its size
		  $procsothers_inuse_sidsize{$sid} = $inuse_sidsize;
		  $procsothers_pgps_sidsize{$sid} = $pgsp_sidsize;
		  $procsothers_virt_sidsize{$sid} = $virt_sidsize;
          printf("Found %d numbers the process segments %20s\r", $po, '') 
          if ($verbose);
        }
	  }
	}
  }
}
printf("\n") if ($verbose);
close(SVMON_OTHERS);

my $procsothers_inuse_size = 0;
foreach my $sid ( keys %procsothers_inuse_sidsize ) {
  $procsothers_inuse_size	+= $procsothers_inuse_sidsize{$sid} 
}
my $procsothers_pgps_size = 0;
foreach my $sid ( keys %procsothers_pgps_sidsize ) {
  $procsothers_pgps_size	+= $procsothers_pgps_sidsize{$sid} 
}
my $procsothers_virt_size = 0;
foreach my $sid ( keys %procsothers_virt_sidsize ) {
  $procsothers_virt_size	+= $procsothers_virt_sidsize{$sid} 
}
if ($oracle) {
  printf("SUM(Oracle process excl. real  segm.)  = %d KB \n", $ora_procsexcl_real_size);
  printf("SUM(Oracle process excl. pgsp  segm.)  = %d KB \n", $ora_procsexcl_pgsp_size);
  printf("SUM(Oracle process excl. virt. segm.)  = %d KB \n", $ora_procsexcl_virt_size);
  printf("SUM(Not Orac. procs. excl. real segm.) = %d KB \n", $nora_procsexcl_real_size);
  printf("SUM(Not Orac. procs. excl. pgsp.segm.) = %d KB \n", $nora_procsexcl_pgsp_size);
  printf("SUM(Not Orac. procs. excl. virt.segm.) = %d KB \n", $nora_procsexcl_virt_size);
}
printf("SUM(process exclusive segments) = Inuse: %8d KB; Pgsp: %8d KB; Virtual: %8d KB\n", 
       $procsexcl_inuse_size, $procsexcl_pgsp_size, $procsexcl_virt_size);
printf("SUM(process  others   segments) = Inuse: %8d KB; Pgsp: %8d KB; Virtual: %8d KB\n", 
       $procsothers_inuse_size, $procsothers_pgps_size, $procsothers_virt_size);
printf("SUM(kernel segments)            = Inuse: %8d KB; Pgsp: %8d KB; Virtual: %8d KB\n", 
       $kernel_inuse_size, $kernel_pgsp_size, $kernel_virt_size);
printf("SUM(shared segments)            = Inuse: %8d KB; Pgsp: %8d KB; Virtual: %8d KB\n",
       $shared_inuse_size, $shared_pgsp_size, $shared_virt_size);
my $file_pages = 0;
open VMSTAT_V, "vmstat -v|",
  or die "perl cant run svmon";
while(<VMSTAT_V>) {
  if (/file pages/) {
    my @tmp1 = split / +/;
    $file_pages = $tmp1[1] * 4;
  }
  if (/free pages/) {
    my @tmp1 = split / +/;
    $free_pages = $tmp1[1] * 4;
  }
}
close(VMSTAT_V);
printf("free memory = %d KB\n",$free_pages);
printf("file cache = %d KB\n",$file_pages);
exit(0);
__END__
