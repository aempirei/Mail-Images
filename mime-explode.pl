#!/usr/bin/env perl

use MIME::Explode;

if(@ARGV != 1) {
	print STDERR "\nusage: $0 directory < rfc822.txt\n\n";
	exit;
}

my ( $target_dir ) = @ARGV;

sub get_temp_fn {
	my $no = sprintf('%04d', int(rand(10000)));
	return "/tmp/mime-explode.$no.tmp";
}

my $temp_fn =  get_temp_fn();

my $explode = MIME::Explode->new(
  output_dir         => $target_dir,
  mkdir              => 0755,
  decode_subject     => 1,
  # check_content_type => 0,
  # content_types      => ["image/gif", "image/jpeg", "image/bmp", "image/png", "text/plain", "text/html" ],
  # types_action       => "include"
);

open(OUTPUT, ">$temp_fn") or die("Couldn't open file.tmp for writing: $!\n");

my $headers = $explode->parse(\*STDIN, \*OUTPUT);

close(OUTPUT);

unlink $temp_fn;

#
# create subject file
#

my $subject_fn = "$target_dir/subject.txt";

open(SUBJECT, ">$subject_fn") or die("Couldn't open $subject_fn for writing: $!\n");

my $subject = join("", @{$headers->{'0.0'}->{subject}->{value}});

print SUBJECT $subject."\n";

close(SUBJECT);
