#!/usr/bin/perl

=for comment
Things to think about:
Pull the IP addresses and then geo-locate them.
Use locations for latency
For Jitter, use Utkarsh's TCP Attack from several PlanetLab computers to obtain mean Jitter
github netlab db ip and raw socket
For proxies, use the IP above and trace route 5 times to get mean additive latency. 

Monitoring tools suggested:
http://www.tecmint.com/command-line-tools-to-monitor-linux-performance/
https://www.torproject.org/docs/tor-manual.html.en
=cut

use strict;
use warnings;
use diagnostics;
use Math::Round;
use List::MoreUtils qw(first_index);
#use Data::Dumper;
#use Math::Trig;
#use Math::Complex;
#use POSIX;

my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
my $monthnum = $month + 1;
my $download;
if ($monthnum < 10){
    $download = "exit-list-2015-0$monthnum";
} else {
    $download = "exit-list-2015-$monthnum";
}
system("wget collector.torproject.org/archive/exit-lists/$download.tar.xz");
system("tar -xJf $download.tar.xz");
system("rm -f $download.tar.xz");

my @fin = process_files ("$download");
#my @fin = process_files ("working");

my $counter = 0;
my $size = 0;
my %distance;
my @addresses;

local $| = 1;

print "Reading Files: ";

$size = @fin;
my $filesString;
foreach my $file (@fin) {

    $counter++;
    print "\b" x length($filesString) if defined $filesString;
    $filesString = "$counter / $size ";
    print $filesString;

    if (-f $file) {
        open(INFILE, $file) or die "Cannot open $_!.\n";

        # This loops through each line of the file
        while(my $line = <INFILE>) {
            if ($line =~ m/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/){
                my %seen;
                $seen{$_}++ for @addresses;
                unless ($seen{$1}){
                    push @addresses, $1;
                }
            }
        }
    }
}

print "\n\nGeolocating Nodes: ";

# Use distance_estimate to estimate the distance from every IP to every other IP
# Lots of loops! I don't know what is happening now. 
$size = @addresses;
if ($size > 10000){ die "Too many addresses for freegeoip.net\n";}
$counter = 0;

my %geodata;
my $progressString;

foreach my $addr_locate (@addresses){
    $geodata{$addr_locate} = geolocateip ($addr_locate);
    $counter++;
    print "\b" x length($progressString) if defined $progressString;
    $progressString = "$counter / $size ";
    print $progressString;
}

print "\n\nWriting to output file...\n";

open(my $output, '>', 'output') or die "Cannot open out file.\n";

my $decision = 0;

my @currentIP;

for (my $i=0; $i < scalar @addresses; $i++){
    for (my $j=0; $j < scalar @addresses; $j++){
        unless ($i == $j){
            my $source = $addresses[$i];
            my $destination = $addresses[$j];
            my $miles = get_distance($geodata{$source}[0], $geodata{$source}[1], $geodata{$destination}[0], $geodata{$destination}[1]);
            unless ($miles <= 100){

                my $sourceStepper = 0;
                my $destinationStepper = 0;

                unless (grep {$_ eq $source} @currentIP){
                    push @currentIP, $source;
                }
                unless (grep {$_ eq $destination} @currentIP){
                    push @currentIP, $destination;
                }

                my $sourceLoc = first_index{$_ eq $source} @currentIP;
                my $destinationLoc = first_index{$_ eq $destination} @currentIP;

                while ($sourceLoc > 255){
                    $sourceStepper = $sourceStepper + 1;
                    $sourceLoc = $sourceLoc - 255;
                }
                while ($destinationLoc > 255){
                    $destinationStepper = $destinationStepper + 1;
                    $destinationLoc = $destinationLoc - 255;
                }

                my $newSource = "10.0." . $sourceStepper . "." . $sourceLoc;
                my $newDestination = "10.0." . $destinationStepper . "." . $destinationLoc;

                my $latency = nearest(0.01, $miles * 0.0656804886736);
                print $output "$newSource,$newDestination,$latency"."ms\n";
                $distance{$newSource}{$newDestination} = $latency;
                # Need to multiply by 0.0656804886736 for a millisecond per mile estimation. 
                # Obtained from Sam's research
                # He tested multiple physical devices for latency and averaged 
                # May need to calculate country latencies?
            }
        }
    }
}

#print $output Dumper(\%distance);

close $output;

system("rm -rf $download");
system("rm -rf _Inline");

# Sam's Python Code for calculating distances based on lat and lon. haha!
use Inline Python => <<'END_OF_PYTHON_CODE';
import math
def get_distance(lat1, lon1, lat2, lon2):
    R = 3963.1676 #radius of the earth in miles
    lat1RAD = math.radians(float(lat1))
    lat2RAD = math.radians(float(lat2))
    lat2Tolat1RAD = math.radians((float(lat2)-float(lat1)))
    lon2Tolon1RAD = math.radians((float(lon2)-float(lon1)))

    a = math.sin(lat2Tolat1RAD/2) * math.sin(lat2Tolat1RAD/2) + math.cos(lat1RAD) * math.cos(lat2RAD) * math.sin(lon2Tolon1RAD/2) * math.sin(lon2Tolon1RAD/2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a)) 

    distance_estimate = R * c

    return distance_estimate
END_OF_PYTHON_CODE

sub geolocateip {
    my $addr = shift;
    open my $geoip, "curl -s freegeoip.net/csv/$addr |";
    my @locate = split(',', <$geoip>);
    return [$locate[8], $locate[9]];
    # return [$locate[1], $locate[5]];
}

# Takes one argument: the path to a directory (local or full).
# Returns: A list of files that reside in that path.
sub process_files {    
    my $path = shift;
    opendir (DIR, $path) or die "Unable to open $path: $!";
    my @files =
        map { $path . '/' . $_ }
        grep { !/^\.{1,2}$/ }
        grep { !/^\.DS_Store/ }
        readdir (DIR);

    closedir (DIR);

    for (@files) {
        if (-d $_) {
            push @files, process_files ($_);
        }
    }
    return @files;
}

