#!/bin/perl

use Modern::Perl;
use Getopt::Long;
use Data::Dumper;

my $usage = <<EOF;
extractqueries.pl - extract queries from (perso) logs - find patters "q=XXXX: at"
    -h|--help           Print this help and exit;
    -f|--file           File to process
    -eq|--extract-queries Extract queries from file        
EOF
my $help      = 0;
my $file      = 0;
my $eq        = 0;

GetOptions( "help" => \$help,
            "file=s" => \$file,
            "eq" => \$eq,
) or die $usage;

open FH, "<$file" or die "Can't open file $file: $!";

my @queries;

while (my $logline = <FH>) {
  if ($logline =~ /:q=(.+): at/) {                # find queries "... opac-search.pl: OpacSolrSimpleSearch:q=int_authid:136226: at /home/koha..."
    push @queries, $1;
  }
}

if (defined $eq) {
  foreach my $q (@queries) {
    say $q;
  }
} 

close FH;
