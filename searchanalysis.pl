#!/bin/perl

use Modern::Perl;
use Getopt::Long;
use Data::Dumper;
use List::Util qw(sum);  

sub avg {     return sum(@_)/@_; }

my $usage = <<EOF;
searchanalysis.pl - analyse solr stdout logs to extract metrics.
    -h|--help           Print this help and exit;
    -f|--file           File to process
    -n|--nb             Nb top queries
    -v|--verbose        Print some debug informations
EOF
my $help      = 0;
my $file      = 0;
my $verbose   = 0;
my $nb        = 10;

GetOptions( "help" => \$help,
            "verbose" => \$verbose,
            "file=s" => \$file,
            "nb=s" => \$nb,
) or die $usage;

open FH, "<$file" or die "Can't open file $file: $!";

my @updatelist;
my @queries;
my @searchTime;
my @updateTime;
# Count "CountUsage"
my $countusage;

# Matches collection

while (my $logline = <FH>) {
  if ($logline =~ /:q=(.+): at/) {                # find queries "... opac-search.pl: OpacSolrSimpleSearch:q=int_authid:136226: at /home/koha..."
    push @queries, $1;
  } elsif ($logline =~ /add=\[(.*?)\]/) {         # update matches
    push @updatelist, $1;
  } elsif ($logline =~ /&q=(.*?)&facet.limit=/) { # query matches
    push @queries, $1;
    if ($logline =~ /rows=999999999/) {$countusage++;}
   }

  if ($logline =~ /path=\/select.*&q=(.*?)&.*QTime=(.+)$/) {         # count QTime for select
       push @searchTime, {q =>$1,t=>$2};
  } elsif ($logline =~ /path=\/update.*QTime=(.+)$/) {         # count QTime for update
       push @updateTime, {t=>$1};
  }
}

@searchTime = sort { $a->{t} < $b->{t} } @searchTime;
@updateTime = sort { $a->{t} < $b->{t} } @updateTime;

my $avgsearchqtime = avg (map {$_->{t}} @searchTime);
my $avgupdateqtime = avg (map {$_->{t}} @updateTime);

# Find 10 top queries

my %topqueries; 
my $q;
foreach my $q (@queries) { $topqueries{$q}++; }
my @sortedqueries = sort { $topqueries{$b} <=> $topqueries{$a} } keys %topqueries;
say "Top $nb queries";
for (0..$nb-1) {
  $q = $sortedqueries[$_]; 
  say $_+1 . "\t" . $topqueries{$q} . "\t" . $q;
}

say "\nTop $nb QTime update";
say "Average: $avgupdateqtime";
for (0..$nb-1) {
  say $_+1 . "\t" . $updateTime[$_]{'t'};
}

say "\nTop $nb QTime search";
say "Average: $avgsearchqtime";
for (0..$nb-1) {
  say $_+1 . "\t" . $searchTime[$_]{'q'}." ".$searchTime[$_]{'t'};
}

$verbose and warn Data::Dumper::Dumper (@updatelist);
$verbose and warn Data::Dumper::Dumper (@sortedqueries);
say "\nUpdates:\t".scalar (@updatelist);
say "Searches:\t".scalar (@queries);
say "CountUsageAuth:\t".$countusage;
say "PertinentSearch:\t".(scalar (@queries) - $countusage);

close FH;
