#!/bin/perl

use Modern::Perl;
use Getopt::Long;
use Data::Dumper;

my $usage = <<EOF;
accesslogsanalysis.pl - analyse apache acces logs to extract metrics.
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

my @calledget;
my @calledpost;

# Matches collection

while (my $logline = <FH>) {
  if ($logline =~ /GET (.+) HTTP/) {                # find queries "... opac-search.pl: OpacSolrSimpleSearch:q=int_authid:136226: at /home/koha..."
    push @calledget, $1;
  }
  if ($logline =~ /POST (.+) HTTP/) {                # find queries "... opac-search.pl: OpacSolrSimpleSearch:q=int_authid:136226: at /home/koha..."
    push @calledpost, $1;
  }
}

# Find top called scripts

my %topqueries; 
my $q;
foreach my $q (@calledget) { $topqueries{$q}++; }
my @sortedqueries = sort { $topqueries{$b} <=> $topqueries{$a} } keys %topqueries;
say "Top $nb get called";
for (0..$nb-1) {
  $q = $sortedqueries[$_]; 
  say $_+1 . "\t" . $topqueries{$q} . "\t" . $q;
}

foreach my $q (@calledpost) { $topqueries{$q}++; }
@sortedqueries = sort { $topqueries{$b} <=> $topqueries{$a} } keys %topqueries;
say "\nTop $nb post called";
for (0..$nb-1) {
  $q = $sortedqueries[$_]; 
  say $_+1 . "\t" . $topqueries{$q} . "\t" . $q;
}

close FH;
