package DNS::SerialNumber::Check;

use 5.006;
use warnings;
use strict;
use Net::DNS;
use Carp qw/croak/;

use vars qw/$VERSION/;
$VERSION = '0.01';

sub new {
    my $class = shift;
    bless {},$class;
}

sub check {
    my $self = shift;
    my $zone = shift || croak "no zone provided";
    my $nameservers = shift;
    my %serial;

    if (defined $nameservers ) {
        if (ref $nameservers ne "ARRAY") {
            croak "nameservers must be an array reference";
        }
        for (@$nameservers) {
            my $re = $self->_qrsoa($zone,$_);
            $serial{$_} = $re;
        }
    } else {
        my $res = Net::DNS::Resolver->new;
        my $answer = $res->query($zone, 'NS');
        if (defined $answer) {
            my @rr= $answer->answer;
            for (@rr) {
                my $ns = $_->rdatastr;
                my $re = $self->_qrsoa($zone,$ns);
                $serial{$ns} = $re;
            }
        }
    }

    my %result;
    $result{info} = \%serial;
    my %rev = reverse %serial;
    my @keys = keys %rev;
    $result{status} = ($keys[0] && @keys == 1) ? 1 : 0;
        
    DNS::SerialNumber::Check::Result->new(\%result);
}

sub _qrsoa {
    my $self = shift;
    my $zone = shift;
    my $host = shift;
    my $res   = Net::DNS::Resolver->new(nameservers => [$host]);
    my $query = $res->query($zone, "SOA");
    defined $query ? ($query->answer)[0]->serial : '';
}


package DNS::SerialNumber::Check::Result;

sub new {
    my $class = shift;
    my $result = shift;
    
    bless $result,$class;
}

sub status {
    my $self = shift;
    $self->{status};
}

sub info {
    my $self = shift;
    $self->{info};
}

1;


=head1 NAME

DNS::SerialNumber::Check - check the consistency of serial number from zone's nameservers

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

    use DNS::SerialNumber::Check;

    my $sn = DNS::SerialNumber::Check->new;
    my $re = $sn->check("dnsbed.com");  # or,
    my $re = $sn->check("dnsbed.com",['ns1.dnsbed.com','ns2.dnsbed.com']);

    print $re->status;
    use Data::Dumper;
    print Dumper $re->info;


=head1 METHODS

=head2 new()

Initialize the object.

    my $sn = DNS::SerialNumber::Check->new;

=head2 check(zonename,[nameservers])

Check if the zone serial number in each nameserver for the given zonename is consistent.

    my $re = $sn->check("dnsbed.com"); 
    my $re = $sn->check("dnsbed.com",['ns1.dnsbed.com','ns2.dnsbed.com']);

The first will check from the zone's default nameservers from the public NS records.
The second will check from the specified nameservers you provided.

=head2 status()

Shows the status code within the result, 1 for OK, 0 for BAD.

    print $re->status;

=head2 info()

A hashref, shows each nameserver of the zone with the serial number.

    use Data::Dumper;
    print Dumper $re->info;


=head1 SEE ALSO

Net::DNS


=head1 AUTHOR

Ken Peng <shorttag@gmail.com>


=head1 BUGS/LIMITATIONS

If you have found bugs, please send email to <shorttag@gmail.com>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DNS::SerialNumber::Check


=head1 COPYRIGHT & LICENSE

Copyright 2011 Ken Peng, all rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.
