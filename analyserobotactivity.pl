#!/bin/perl

use Modern::Perl;
use Getopt::Long;
use Data::Dumper;

my $usage = <<EOF;
analyserobotactivity.pl - analyse apache access logs and finds how many pages are requested by bots or webcrawlers.
    -h|--help           Print this help and exit;
    -f|--file           File to process
    -d|--date           Specify a date day like 13\/Jan
EOF
my $help      = 0;
my $file      = 0;
my $date      = 0; 

GetOptions( "help" => \$help,
            "file=s" => \$file,
            "d=s" => \$date,
) or die $usage;

open FH, "<$file" or die "Can't open file $file: $!";

my @bots =
( 'Googlebot'
, 'slurp'
, 'exabot'
, 'yandex'
, 'ezooms'
, 'archive.org'
, 'bingbot'
, 'Jyxobot'
, 'MJ12bot'
, 'voilabot'
, 'alexa'
, 'sitebot'
, 'Baiduspider'
);
my @counts;

while (my $logline = <FH>) {
    for my $bot (@bots) {
        if ($logline =~ /$date.*$bot/) {      
           push @counts, $bot; 
        }
    }
}
my %topbots;
foreach my $b (@counts) { $topbots{$b}++; }

say "Bots calls the $date in $file file";
warn Data::Dumper::Dumper (%topbots);
