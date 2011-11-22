#!/usr/bin/perl

use XML::Twig;
use Modern::Perl;
use Getopt::Long;
use Data::Dumper;

my $usage = <<EOF;
transform solr xml search results into solr meter file to process (records.out can)
    -h|--help           Print this help and exit;
    -f|--file           File to process (xml solr export from search)
EOF
my $help      = 0;
my $file      = 0;

GetOptions( "help" => \$help,
            "file=s" => \$file,
) or die $usage;

my $FichierResulat = 'records.out';
open( my $fh, '>', $FichierResulat ) or die("Impossible d'ouvrir le fichier $FichierResulat\n$!");

my $twig=XML::Twig->new(
    pretty_print => 'indented'
);
$twig->parsefile($file);

my $root = $twig->root;
my @keyvalue;

# foreach <doc>
foreach my $doc ($root->children('result')) {
  foreach my $result ($doc->children) {
    # for each <arr> get values
    foreach my $arr ($result->children) {
      my $indexname = $arr->att('name');
      my @values = $arr->children;
      if (scalar (@values) ne 0) {
        my $firstvalue = $values[0]->text if scalar(@values);
        $firstvalue =~ s/\n//g;
        push @keyvalue,$indexname.":".$firstvalue;
      }
    }
    # print a line like "index1:value1;index2:value2"
    my $line = join ";", @keyvalue;
    print {$fh} $line ,"\n";
    @keyvalue = ();
  }
}
