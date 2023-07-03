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
# my $logname = "log_$today";
# my $log_file;
# open($log_file, ">>/l/prep/aim/dfulmer/oclcacqexclude/$logname") or die "can't open $logname for output: $!";
# print $log_file "Script: $0 ran $datestring\n";

my $json = new JSON;
$json->pretty([1]);

#binmode STDOUT,":utf8";
#set timeout to 10 mins
my $ua = LWP::UserAgent->new(keep_alive => 10, timeout => (60 * 10)) or die "can't set up ua: $!\n";
$ua->default_header('Authorization' => "apikey $api_key");
$ua->default_header('Accept' => 'application/json'); 
$ua->default_header('Accept-Charset' => 'UTF-8'); 

my $year = substr($today, 0, 4);
my $month = substr($today, 4, 2);
my $day = substr($today, 6, 2);

# First get the Set ID and Name of the Set to run the job with...
# This is the old set name pattern
# my $unaddset_name_pattern = "OCLC_all_physical_titles_v2 - Combined - $month/$day/$year";
# This is the new set name pattern
my $unaddset_name_pattern = "OCLC_every_physical_title_with_acquisition_v2 - Combined - $month/$day/$year";

my $url_base = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/sets?set_type=ITEMIZED&q=name~$unaddset_name_pattern&limit=1&offset=0";
my $res = $ua->get($url_base);

# Check the outcome of the response
$res->is_success or do {
  my $error_json = $json->decode($res->decoded_content);
  my $errors = $error_json->{'errorList'}->{'error'};
  #print Dumper $error_json;
  foreach my $error (@$errors) {
    print STDERR join("\t", $error->{'errorCode'}, $error->{'errorMessage'}), "\n";
  }
die "error getting set id\n";
};

my $res_json = $json->decode($res->decoded_content);
my $unaddset_id = $res_json->{set}->[0]->{"id"};
my $unaddset_name = $res_json->{set}->[0]->{"name"};
#print "unaddset_id: $unaddset_id\n";

print "Starting the Set Mgmt Tags job...\n";

my $flag_action = "NONE";
my $job_name = 'Synchronize Bib records with OCLC - do not publish';

my $set_id = "$unaddset_id";
my $set_name = "$unaddset_name";
#
# json payload
#
my $job_info = {
  "parameter" => [
    {
        "name" => { "value" => "task_MmsTaggingParams_boolean"},
        "value" => $flag_action,
    },
    {
        "name" => { "value" => "set_id" },
        "value" => $set_id,
    },
    {
        "name" => { "value" => "job_name" },
        "value" => "$job_name - $set_name",
    },
  ],
};
my $job_json = $json->encode($job_info) or die "Error encoding job_info\n";

# Create a request
my $job_url = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/jobs/M12889770000231?op=run";
my $req = HTTP::Request->new(POST => $job_url);
$req->content_type('application/json');
$req->content($job_json);
#$req->content_type('application/xml');
#$req->content($job_xml);

my $res2 = $ua->request($req);
$res2 or do {
  print Dumper $res;
  die "error in http response\n";
};
# Check the outcome of the response
$res2->is_success or do {
  my $error_json = $json->decode($res2->decoded_content);
  my $errors = $error_json->{'errorList'}->{'error'};
  #print Dumper $error_json;
  foreach my $error (@$errors) {
    print STDERR join("\t", $error->{'errorCode'}, $error->{'errorMessage'}), "\n";
  }
  return 0;
};
my $res_json = $json->decode($res2->decoded_content);
print "Set Mgmt Tags job submitted.\n";

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
