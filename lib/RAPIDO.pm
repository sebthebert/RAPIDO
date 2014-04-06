package RAPIDO;

=head1 NAME

RAPIDO - Restful API Daemon 

=cut

use strict;
use warnings;

use HTTP::Daemon;
use HTTP::Headers;
use HTTP::Response;
use HTTP::Status;
use JSON;
use URI;
use URI::QueryParam;

our $VERSION = 0.1;

my $API_ROOT = '/rapido';
my $DEFAULT_IP = '127.0.0.1';
my $DEFAULT_PORT = '1111';

my %api = (
    "$API_ROOT/api" => {
        method => 'GET',
        code => \&API_Listing,
        description => 'Returns RAPIDO api'
        },
    "$API_ROOT/config" => {
        method => 'GET',
        code => sub { my $self = shift; return ({ config => $self->{config} }); },
        description => 'Returns RAPIDO configuration'
        },
    "$API_ROOT/version" => {
        method => 'GET',
        code => sub { return ({ version => $VERSION }); },
        description => 'Returns RAPIDO version'
        }
    );

=head1 SUBROUTINES/METHODS

=head2 new()

=cut

sub new
{
    my ($class, $param) = @_;
    
    my $self = { 
        config => {
            ip => $param->{ip} || $DEFAULT_IP,
            port => $param->{port} || $DEFAULT_PORT
            },
        api => \%api
        };
        
    bless $self, $class;
    
    return ($self);
}

sub API_Listing
{
    my $self = shift;
    
    my %listing = ();
    foreach my $url (sort keys %{$self->{api}})
    {
        foreach my $k (keys %{$self->{api}->{$url}})
        {
            $listing{$url}->{$k} = $self->{api}->{$url}->{$k}
                if ($k ne 'code');    
        }
    }
    
    return ({ api => \%listing });
}

=head2 Run()

Runs RAPIDO Daemon

=cut

sub Run
{
    my $self = shift;

    my $daemon = HTTP::Daemon->new(
        ReuseAddr => 1,
        LocalAddr => $self->{config}->{ip},
        LocalPort => $self->{config}->{port}
    );

    my $json_header = HTTP::Headers->new('Content-Type' => 'application/json');
    printf("RAPIDO listening on %s...\n", $daemon->url);
    while (my $connection = $daemon->accept)
    {
        while (my $request = $connection->get_request)
        {
            my ($method, $path, $params, $content) = (
                $request->method, $request->uri->path, 
                $request->uri->query_form_hash, 
                $request->content
            );
            if (   (defined $self->{api}->{$path})
                && ($method eq $self->{api}->{$path}->{method}))
            {
                my $resp_content =
                    $self->{api}->{$path}->{code}($self, $params, $content);
                my $resp =
                    HTTP::Response->new(200, 'OK', $json_header, 
                        to_json($resp_content, { pretty => 1 }));
                $connection->send_response($resp);
            }
            else
            {
                $connection->send_error(RC_FORBIDDEN);
            }
        }
        $connection->close;
        undef($connection);
    }

    return (1);
}

1;

=head1 AUTHOR

Sebastien Thebert <contact@onetool.pm>

=cut