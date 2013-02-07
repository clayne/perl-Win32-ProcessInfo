package main;

use strict;
use warnings;

use Test::More 0.88;

use Win32::Process::Info qw{ $MY_PID };

my $dad;
eval {
    $dad = getppid();
    $^O eq 'cygwin'
	and $dad = Cygwin::pid_to_winpid( $dad );
    1;
} or do {
    plan skip_all => 'getppid() not implemented, or failed';
    exit;
};

my $pi = eval {
    Win32::Process::Info->new(undef, 'WMI,PT')
} or do {
    plan skip_all => 'unable to instantiate Win32::Process::Info';
    exit;
};

note <<"EOD";

My process ID = $MY_PID
Parent process ID = $dad
EOD

{
    my %subs = $pi->Subprocesses($dad);
    ok $subs{$MY_PID},
	"Call Subprocesses() and see if $MY_PID is a subprocess of $dad";
}

{
    my ($pop) = $pi->SubProcInfo($dad);
    my @subs = @{$pop->{subProcesses}};
    my $bingo;
    while (@subs) {
	my $proc = shift @subs;
	$proc->{ProcessId} == $MY_PID and do {
	    $bingo++;
	    last;
	};
	push @subs, @{$proc->{subProcesses}};
    }
    ok $bingo,
	"Call SubProcInfo() and see if $MY_PID is a subprocess of $dad";
}

done_testing;

1;

__END__

# ex: set textwidth=72 :
