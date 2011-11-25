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

my $addnb;
my @queries;
my @fq;
my @searchTime;
my @updateTime;
# Count "CountUsage"
my $countusage;

# Matches collection

while (my $logline = <FH>) {
  if ($logline =~ /:q=(.+): at/) {                # find queries "... opac-search.pl: OpacSolrSimpleSearch:q=int_authid:136226: at /home/koha..."
    push @queries, $1;
  } elsif ($logline =~ /&q=(.*?)&facet.limit=/) { # query matches
    push @queries, $1;
  if ($logline =~ /rows=999999999/) {$countusage++;}
  } elsif ($logline =~ /add=/) { # update matches
    $addnb += 1;
  }

  while ($logline =~ /fq=([^&]*)&/g) {
    push @fq, $1;
  } 


  if ($logline =~ /path=\/select.*&q=(.*?)&.*QTime=(.+)$/) {         # count QTime for select
    #if ($2 > 500) {
       push @searchTime, {q =>$1,t=>$2};
    #}
  } elsif ($logline =~ /path=\/update.*QTime=([0-9]+).*$/) {         # count QTime for update
    #if ($1 > 500) {
       push @updateTime, $1;
    #}
  }
}

@searchTime = sort { $b->{t} <=> $a->{t} } @searchTime;
@updateTime = sort {$b <=> $a} @updateTime;

my $avgsearchqtime = avg (map {$_->{t}} @searchTime);
my $avgupdateqtime = avg (@updateTime);

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

my %topfq; 
foreach my $q (@fq) { $topfq{$q}++; }
my @sortedfq = sort { $topfq{$b} <=> $topfq{$a} } keys %topfq;
say "Top $nb filters";
for (0..$nb-1) {
  $q = $sortedfq[$_]; 
  say $_+1 . "\t" . $topfq{$q} . "\t" . $q;
}

say "\nTop $nb QTime update - nb ".scalar @updateTime;
say "Update average(ms): $avgupdateqtime";
for (0..$nb-1) {
  say $updateTime[$_];
}

say "\nTop $nb QTime search - nb ".scalar @searchTime;
say "Search average (ms): $avgsearchqtime";
for (0..$nb-1) {
  say $searchTime[$_]{'t'}. "\t". $searchTime[$_]{'q'};
}

$verbose and warn Data::Dumper::Dumper (@sortedqueries);
say "\nUpdates \t".scalar (@updateTime);
say "Adds\t\t".scalar ($addnb);
say "Searches\t".scalar (@queries);
say "CountUsageAuth\t".$countusage;
say "PertinentSearch ".(scalar (@queries) - $countusage);

close FH;
