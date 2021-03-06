package Freelex;

use strict;
use warnings;

#
# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
# Static::Simple: will serve static files from the application's root 
# directory
#
use Catalyst qw/-Debug StackTrace Static::Simple Redirect Unicode Session Session::Store::FastMmap Session::State::Cookie Authentication Authentication::Credential::Password/;

use Catalyst::Authentication::Store::DBI::ButMaintained;

our $VERSION = '0.01';

use FreelexDB::Globals;

	__PACKAGE__->config->{'authentication'} = {
		default_realm => 'default'
		, realms => {
			default => {
				credential => {
					class                 => 'Password'
					, password_field      => 'password'
					, password_type       => 'clear'
				},
				store => {
					class                => 'DBI::ButMaintained'
					, user_table         => 'matapunauser'
					, user_key           => 'matapunauserid'
					, user_name          => 'matapunauser'
				},
			},
		},
	};


__PACKAGE__->config->{static}->{ignore_extensions} 
        = [ qw/tmpl tt tt2 xhtml/ ]; # don't ignore html for FCKeditor

__PACKAGE__->config->{static}->{mime_types} = {
        jpg => 'image/jpg',
        png => 'image/png',
    };

__PACKAGE__->config->{static}->{include_path} = [
            FreelexDB::Globals->template_dir,
          __PACKAGE__->path_to( 'root' ) 
    ];

__PACKAGE__->config->{cookie_expires} = 0; # make cookies session-only

__PACKAGE__->config->{session} = { expires=> 60*60*24*7, 
        cookie_name => FreelexDB::Globals->db_name . '_session',
        storage => '/tmp/session-freelex-' . FreelexDB::Globals->db_name . '-' . $>,
        verify_address => 0 }; # sessions can go a week if the browser can

__PACKAGE__->config('View::TT' => {
     INCLUDE_PATH => [ 
                         FreelexDB::Globals->template_dir,
                         __PACKAGE__->path_to( 'root' ) ,
                     ]
     });
#
# Start the application
#
__PACKAGE__->setup;

=head1 NAME

Freelex - Catalyst based application

=head1 SYNOPSIS

    script/freelex_server.pl

=head1 DESCRIPTION

Catalyst based application.

=head1 METHODS

=cut

=head2 default

=cut

=head1 AUTHOR

Dave Moskovitz

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
