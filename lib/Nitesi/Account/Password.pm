package Nitesi::Account::Password;

use strict;
use warnings;

use Crypt::Password ();

use base 'Nitesi::Object::Singleton';

=head1 NAME

Nitesi::Account::Password - Password class for Nitesi Shop Machine

=head1 METHODS

=head2 check

Checks password retrieved from user against the password hash.

    $crypt->check($hash_from_database, $user_input);

=cut

sub check {
    my ($self, $hash, $password) = @_;

    Crypt::Password::password($hash)->check($password);
}

=head2 password

Creates password hash from plain text password.

    $crypt->password('nevairbe');

Use specific algorithm (default is sha512):

    $crypt->password('nevairbe', 'md5');

=cut

sub password {
    my ($self, $password, $algorithm, $salt);

    $self = shift;
    $password = shift;

    if (@_) {
	# got algorithm
	$algorithm = shift;
    }
    else {
	$algorithm = 'sha512';
    }

    $password = Crypt::Password::password($password, undef, $algorithm);

    return $password;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


1;
