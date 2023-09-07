#!/usr/bin/perl
use strict;
use open qw( :encoding(UTF-8) :std );

use Sys::Hostname;
use URI::Escape;
use Data::Dumper;
use File::Basename;
use Getopt::Std;

use Encode qw(decode encode);

use Class::Date qw(:errors date localdate gmdate now);
use JSON; # always uses JSON::PP
use LWP::UserAgent;
# use HTTP::Request 6.07;
use HTTP::Request;
use LWP::Protocol::https;

my ($name, $path, $suffix) = File::Basename::fileparse($0);
use Dotenv;
Dotenv->load("$path.env");

my $api_key = $ENV{ALMA_API_KEY};
my $prg_name = basename($0);
my $today = substr(getDate(), 0, 8);
my $datestring = localtime();
#my $logname = "log_version2_$today";
#my $log_file;
#open($log_file, ">>/l/prep/aim/dfulmer/oclcacqexclude/$logname") or die "can't open $logname for output: $!";
#print $log_file "Script: $0 ran $datestring\n";

my $json = new JSON;
$json->pretty([1]);

#binmode STDOUT,":utf8";
#set timeout to 10 mins
my $ua = LWP::UserAgent->new(keep_alive => 10, timeout => (60 * 10)) or die "can't set up ua: $!\n";
$ua->default_header('Authorization' => "apikey $api_key");
$ua->default_header('Accept' => 'application/json'); 
$ua->default_header('Accept-Charset' => 'UTF-8'); 

# Sets
# Sandbox - old way with a bigger set
# OCLC_all_physical_titles_v2 Set ID 22766873270006381
# OCLC_every_physical_title_except_acquisition_v2 Set ID 22766924310006381
# The old way of doing it is: OCLC_all_physical_titles_v2 NOT OCLC_every_physical_title_except_acquisition_v2
#
# my $set_operator = 'NOT';
# my $set1 = '22766873270006381';
# my $set2 = '22766924310006381';

# Sandbox - new way with a smaller set
# OCLC_every_physical_title_with_acquisition_v2 Set ID 34493393360006381
# OCLC_every_physical_title_except_acquisition_v2 Set ID 22766924310006381
# The new way of doing it is: OCLC_every_physical_title_with_acquisition_v2 NOT OCLC_every_physical_title_except_acquisition_v2
#
 my $set_operator = 'NOT';
 my $set1 = '34493393360006381';
 my $set2 = '22766924310006381';

# Production - this requires a different API key, and this is with the smaller set
# OCLC_every_physical_title_with_acquisition_v2 Set ID 34493393360006381
# OCLC_every_physical_title_except_acquisition_v2 Set ID 22766924310006381
# The way of doing it is: OCLC_every_physical_title_with_acquisition_v2 NOT OCLC_every_physical_title_except_acquisition_v2
#
# my $set_operator = 'NOT';
# my $set1 = '34493393360006381';
# my $set2 = '22766924310006381';

my $unadd_set = combine_sets($set1, $set2, $set_operator) or do {
  print "error combining sets\n";
#  print $log_file "error combining sets\n";
  exit -1;
};
print "Created the set.\n";
#print $log_file "Created the set.\n";

sub combine_sets {
  my $set1 = shift;
  my $set2 = shift;
  my $operator = shift;
  #
  # combine sets for sets  $set1 and $set2 
  # return combined set (structure)
  #
  my $set1_id = $set1;
  my $set2_id = $set2;
  my $res_json = <<EOF;
{
   "status" : {
      "desc" : "Active",
      "value" : "ACTIVE"
   },
   "description" : null,
   "origin" : {
      "desc" : "Institution only",
      "value" : "UI"
   },
   "note" : null,
   "query" : null,
   "members" : null,
   "link" : "",
   "private" : {
      "desc" : "No",
      "value" : "false"
   },
   "type" : {
      "desc" : "Itemized",
      "value" : "ITEMIZED"
   },
   "content" : {
      "value" : "IEP"
   },
   "created_by" : {
     "desc" : "API, Ex Libris",
     "value" : "exl_api"
   }
}
EOF
  #"members":{ "total_record_count":"", "member":[{"link":"","id":"99100045050001021"}]},
  #"origin":{"value":"UI"}

  # Create a request
  my $create_url = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/sets?combine=$operator&set1=$set1_id&set2=$set2_id";
  my $req = HTTP::Request->new(POST => $create_url);
  $req->content_type('application/json');
  $req->content($res_json);

  my $res = $ua->request($req);

  # Uncomment this line to see the response, it's basically "<errorCode>ROUTING_ERROR</errorCode>" every time.
  # print Dumper $res;

  # Don't check the outcome of the response
##  $res->is_success or do {
##    print Dumper $res;
##    my $error_json = $json->decode($res->decoded_content);
##    my $errors = $error_json->{'errorList'}->{'error'};
    #print Dumper $error_json;
##    foreach my $error (@$errors) {
##      print STDERR join("\t", $error->{'errorCode'}, $error->{'errorMessage'}), "\n";
##    }
##    return 0;
##  };
##  my $res_json = $json->decode($res->decoded_content);
##  my $new_set_id = $res_json->{id};
##  my $number_of_members =  $res_json->{number_of_members}->{value};
##  my $new_set_name =  $res_json->{name};
  #return ($new_set_id, $new_set_name, $number_of_members);
##  return $res_json;
}

sub getDate {
  my $inputDate = shift;
  if (!defined($inputDate)) { $inputDate = time; }
  my ($ss,$mm,$hh,$day,$mon,$yr,$wday,$yday,$isdst) = localtime($inputDate);
  my $year = $yr + 1900;
  $mon++;
  #my $fmtdate = sprintf("%4.4d%2.2d%2.2d:%2.2d:%2.2d:%2.2d",$year,$mon,$day,$hh,$mm,$ss);
  my $fmtdate = sprintf("%4.4d%2.2d%2.2d:%2.2d:%2.2d:%2.2d",$year,$mon,$day,$hh,$mm,$ss);
  return $fmtdate;
}
