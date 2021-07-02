#! /usr/bin/perl 
#==============================================================#
#                                                              #
#                       Davide Galletti                        #
#                                                              #
#                        powered by Perl                       #
#                                                              #
# davide.galletti.75@gmail.com                 copyright 2013  #
#==============================================================#
#                                                              #
# You may use and modify this software freely.                 #
# You may not profit from it in any way, nor remove the        #
# copyright information.  Please document changes clearly and  #
# preserve the header if you redistribute it.                  #
#                                                              #
#==============================================================#

use strict;
use Switch;
use Date::Parse;
use POSIX;
use POSIX qw(strftime);
use File::Copy qw(move);
use Time::HiRes qw/ time sleep /;
use Getopt::Long qw(:config no_ignore_case);

my $version = "0.1";
my $prg = "check_conns.pl";

my %ERRORS = (OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3);

my $start_plugin = time;

my $STATE = "OK";
my $CREASON = "";

my $default_conn_type = "tcp";

my %Conns = ();
my %Limits = ();

my %ConnTypes = (
	"LISTEN"	=>	"Server is ready to accept connection",
	"CLOSED"	=>	"Server received ACK from client and connection is closed",
	"SYN_SEND"	=>	"Indicates active open",
	"LAST_ACK"	=>	"Server is in this state when it sends its own FIN",
	"FIN_WAIT_1"	=>	"Indicates active close",
	"FIN_WAIT_2"	=>	"Client just received acknowledgment of its first FIN from the server",
	"TIMED_WAIT"	=>	"Client enters this state after active close",
	"CLOSE_WAIT"	=>	"Indicates passive close. Server just received first FIN from a client",
	"ESTABLISHED"	=>	"Client received server's SYN and session is established",
	"SYN_RECEIVED"	=>	"Server just received, SYN from the client",
);

foreach (keys (%ConnTypes)) { $Conns{$_} = 0 if (!defined($Conns{$_})); }

sub Usage
{
print "

$prg $version

Usage: $prg 

	[-I <IP Address>]	IP Address to check connections for
				Mandatory
				Note: possible IP forms are ip / ip:port / :port

	[-R <Remote>]		Check if Remote <IP>

	[-t <type>]		Connections type, tcp, udp, unix
				Default: $default_conn_type

	[-L <Limits>]		Connections Limits
				max - min :: CONNECTION TYPE=number

	Example:

		> check_ct.pl -I 127.0.0.1:80 -L minLISTEN=1,maxESTABLISHED=100

	Connection Types Supported:

";
foreach (keys (%ConnTypes)) { printf "\t\t* $_ ($ConnTypes{$_})\n"; }
printf "\n";
exit($ERRORS{'UNKNOWN'});
}

my ( $opt_I, $opt_R, $opt_L, $opt_h, $opt_x );
my $opt_res = GetOptions(
        "I=s"           => \$opt_I,
        "R=s"           => \$opt_R,
        "L=s"           => \$opt_L,
        "h"             => \$opt_h,
        "x"             => \$opt_x,
);

if ($opt_h)  { Usage; }
if (!$opt_I) { Usage; }
my $MSG = "";
if ($opt_L)
{
	$MSG = "All Limits Respected";
	my @limits = split(",",$opt_L);
	foreach (@limits)
	{
		my ($lname, $lvalue) = split("=");
		if (!defined($Limits{$lname}))
		{
			$Limits{$lname} = $lvalue;
			if ($opt_x) { printf "debug> set Limit: $lname=$lvalue\n"; }
		}
	}
}
else
{
	$MSG = "No Limits Specified";	
}

if ($opt_x) { printf "debug> opt_I=$opt_I   opt_R=$opt_R\n"; }

my @netout = `netstat -an`;

NET_LINE: foreach (@netout)
{
	chomp;
	next NET_LINE if (!/^$default_conn_type/);
	next NET_LINE if (!/$opt_I/);

	my ($c_type, $u1, $u2, $local, $remote, $c_state) = split;

	$_ = $remote;
	if (defined($opt_R) && !/$opt_R/) { next NET_LINE; }

	if ($opt_x) { printf "debug> $local -> $remote :: $c_state\n"; }

	$Conns{$c_state}++;
}

foreach (sort(keys(%Conns)))
{
	if ($opt_x) { printf "debug> Connection Type: $_=$Conns{$_}\n"; }
	if (defined($Limits{"min$_"}) && $Conns{$_} < $Limits{"min$_"})
	{
		$STATE="CRITICAL"; 
		$MSG = "Threshold Limit Exceeded";
		if ($CREASON eq "") { $CREASON="min$_: $Conns{$_} < $Limits{\"min$_\"}"; }
		else { $CREASON = $CREASON . "," . "min$_: $Conns{$_} < $Limits{\"min$_\"}"; }
	}
	if (defined($Limits{"max$_"}) && $Conns{$_} > $Limits{"max$_"})
	{
		$STATE="CRITICAL"; 
		$MSG = "Threshold Limit Exceeded";
		if ($CREASON eq "") { $CREASON="max$_: $Conns{$_} > $Limits{\"max$_\"}"; }
		else { $CREASON = $CREASON . "," . "max$_: $Conns{$_} > $Limits{\"max$_\"}"; }
	}
}

if ($CREASON ne "") { $CREASON = "(" . $CREASON . ")"; }

printf "$STATE - $MSG $CREASON | ";
foreach (sort(keys(%Conns))) { printf "$_=$Conns{$_} "; }
printf "\n";
exit($ERRORS{$STATE});
