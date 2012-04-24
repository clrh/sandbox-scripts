#!/bin/perl

use Modern::Perl;
use Getopt::Long;
use Data::Dumper;
use List::Util qw(sum);  

sub avg {     return sum(@_)/@_; }

my $usage = <<EOF;
accesslogsanalysis.pl - analyse apache acces logs to extract metrics.
    -h|--help           Print this help and exit;
    -f|--file           File to process
    -n|--nb             Nb top queries
    -v|--verbose        Print some debug informations

    Analyses log type: 10.1.1.7 - - [01/Dec/2011:20:30:27 +0100] "GET /intranet-tmpl/prog/en/lib/jquery/plugins/ui.tabs.css HTTP/1.1" 304 - "http://koha.bm-limoges.fr:8200/cgi-bin/koha/catalogue/search.pl?q=test+apache" time=281
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" time=%D"
EOF
my $help      = 0;
my $file      = 0;
my $verbose   = 0;
my $nb        = 10;
my $static    = 0;

GetOptions( "help" => \$help,
            "verbose" => \$verbose,
            "file=s" => \$file,
            "nb=s" => \$nb,
            "static" => \$static,
) or die $usage;

die $usage if $help;

open FH, "<$file" or die "Can't open file $file: $!";

my @calledget;
my @calledpost;
my @getTime;
my @postTime;

# Matches collection

my $q;
my $d;
my $t;

while (my $logline = <FH>) {
  if ($logline =~ /- - \[(.*) \+\d{4}\] "GET (.+) HTTP.*time=([0-9]+).*$/) {
    $d = $1; $q = $2; $t = $3;
    if ($static eq 0)  {next if ($q !~ /\.pl/)};
    push @calledget, $q;
    push @getTime, {d=> $d,q =>$q,t=>$t};
  }
  if ($logline =~ /- - \[(.*) \+\d{4}\] "POST (.+) HTTP.*time=([0-9]+).*$/) {
    $d = $1; $q = $2; $t = $3;
    if ($static eq 0)  {next if ($q !~ /\.pl/)};
    push @calledpost, $q;
    push @postTime, {d=>$d,q =>$q,t=>$t};
  }
}

@getTime = sort { $b->{t} <=> $a->{t} } @getTime;
@postTime = sort { $b->{t} <=> $a->{t} } @postTime;

my $avggettime;
my $avgposttime;

if (scalar (@getTime) ne 0 || scalar (@postTime) ne 0) {
    $avggettime = avg (map {$_->{t}} @getTime);
    $avgposttime = avg (map {$_->{t}} @postTime);
} else {
    die("[ERROR] getTime size:".scalar (@getTime). " postTime size:".scalar (@postTime));
}


# Find top called scripts

my %topqueries; 
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

my $divise = 1000000;
say "\nTop $nb time Get apache calls - nb ".scalar @getTime;
say "Get average(sec): ". $avggettime/$divise;
for (0..$nb-1) {
  say $getTime[$_]{'d'} . "\t" . $getTime[$_]{'t'}/$divise . "\t". $getTime[$_]{'q'};
}

say "\nTop $nb time Post apache calls - nb ".scalar @postTime;
say "Post average (sec): ". $avgposttime/$divise ;
for (0..$nb-1) {
  say $postTime[$_]{'d'}. "\t" .  $postTime[$_]{'t'}/$divise . "\t". $postTime[$_]{'q'};
}

close FH;
