package Nitesi::Account::Manager;

use strict;
use warnings;

use base 'Nitesi::Object';

use Nitesi::Class;
use Nitesi::Account::Password;
use ACL::Lite; 

=head1 NAME

Nitesi::Account::Manager - Account Manager for Nitesi Shop Machine

=head1 SYNOPSIS

    $acct = Nitesi::Account::Manager->instance(provider_sub => \&account_providers, 
                                               session_sub => \&session);

    $acct->init_from_session;

    $acct->status(login_info => 'Please login before checkout',
                  login_continue => 'checkout');

    $acct->login(username => 'shopper@nitesi.biz', password => 'nevairbe');

    $acct->logout();

    if ($acct->exists('shopper@nitesi.biz')) {
        $acct->password(username => 'shopper@nitesi.biz', password => 'nevairbe');
    }

    $acct->create(email => 'shopper@nitesi.biz');

    # use this with caution!
    $acct->become('shopper@nitesi.biz');

=cut

=head1 METHODS

=head2 init

Initializer called by instance class method.

=cut

sub init {
    my ($self, %args) = @_;
    my ($ret, @list, $init);

    $self->{password} = Nitesi::Account::Password->instance;
    $self->{providers} = [];
    
    if ($args{provider_sub}) {
	# retrieve list of providers
	$ret = $args{provider_sub}->();
	
	if (ref($ret) eq 'HASH') {
	    # just one provider
	    @list = ($ret);
	}
	elsif (ref($ret) eq 'ARRAY') {
	    @list = @$ret;
	}

	# instantiate provider objects
	for $init (@list) {
	    push @{$self->{providers}}, Nitesi::Class->instantiate(@$init, crypt => $self->{password});
	}
    }

    if ($args{session_sub}) {
        $self->{session_sub} = $args{session_sub};
    }
    else {
        $self->{session_sub} = sub {return 1;};
    }
}

=head2 init_from_session

Reads user information through session routine.

=cut

sub init_from_session {
    my $self = shift;

    $self->{account} = $self->{session_sub}->() 
	|| {uid => 0, username => '', roles => [], permissions => ['anonymous']};

    $self->{acl} = ACL::Lite->new(permissions => $self->{account}->{permissions});

    return;
}

=head2 login

Perform login. 

Leading and trailing spaces will be removed from
username and password in advance.

=cut

sub login {
    my ($self, %args) = @_;
    my ($success, $acct);

    # remove leading/trailing spaces from username and password
    $args{username} =~ s/^\s+//;
    $args{username} =~ s/\s+$//;

    $args{password} =~ s/^\s+//;
    $args{password} =~ s/\s+$//;

    for my $p (@{$self->{providers}}) {
	if ($acct = $p->login(%args)) {
	    $self->{session_sub}->('init', $acct);
	    $self->{account} = $acct;
	    $success = 1;
	    last;
	}
    }

    return $success;
}

=head2 logout

Perform logout.

=cut

sub logout {
    my ($self, %args) = @_;

    $self->{session_sub}->('destroy');
}

=head2 create

Create account.

=cut

sub create {
    my ($self, %args) = @_;
    my ($password, $uid);
    
    # remove leading/trailing spaces from arguments
    for my $name (keys %args) {
        if (defined $args{$name}) {
            $args{$name} =~ s/^\s+//;
            $args{$name} =~ s/\s+$//;
        }
    }

    unless (exists $args{username} && $args{username} =~ /\S/) {
        $args{username} = lc($args{email});
    }

    # password is added after account creation
    unless ($password = delete $args{password}) {
        $password = $self->{password}->make_password;
    }

    for my $p (@{$self->{providers}}) {
        next unless $p->can('create');
	
        if ($uid = $p->create(%args)) {
            $self->password(username => $args{username},
                            password => $password);
            last;
        }
    }

    return $uid;
}

=head2 delete

Delete account.

=cut

sub delete {
    my ($self, $uid, $p);

    $self = shift;

    if (@_) {
        $uid = shift;
    }
    else {
        $uid = $self->uid;
    }

    for $p (@{$self->{providers}}) {
        if ($p->load($uid)) {
            return $p->delete($uid);
        }
    }

    return;
}

=head2 uid

Retrieve user identifier, returns 0 if current user
isn't authenticated.

=cut

sub uid {
    my $self = shift;

    return $self->{account}->{uid};
}

=head2 username

Retrieve username. Returns empty string if current user
isn't authenticated.

=cut

sub username {
    my $self = shift;

    return $self->{account}->{username};
}

=head2 roles

Retrieve roles of this user.

=cut

sub roles {
    my $self = shift;

    wantarray ? @{$self->{account}->{roles}} : $self->{account}->{roles};
}

=head2 has_role

Returns true if user is a member of the given role.

=cut

sub has_role {
    my ($self, $role) = @_;

    grep {$role eq $_} @{$self->{account}->{roles}};
}

=head2 status

Saves or retrieves status information.

=cut

sub status {
    my ($self, @args) = @_;

    if (@args > 1) {
	# update status information
	$self->{account} = $self->{session_sub}->('update', {@args});
    }
    elsif (@args == 1) {
	return $self->{account}->{$args[0]};
    }
}

=head2 exists

Check whether account exists.

    if ($acct->exists('shopper@nitesi.biz')) {
        print "Account exists\n";
    }

=cut

sub exists {
    my ($self, $username) = @_;

    return unless defined $username && $username =~ /\S/;

    for my $p (@{$self->{providers}}) {
	if ($p->exists($username)) {
	    return $p;
	}
    }
}

=head2 load

Loads account data for a given uid.

=cut

sub load {
    my ($self, $uid) = @_;
    my ($data);

    for my $p (@{$self->{providers}}) {
        if ($data = $p->load($uid)) {
            return $data;
        }
    }
}

=head2 password

Changes password for current account:

    $acct->password('nevairbe');

Changes password for other account:

    $acct->password(username => 'shopper@nitesi.biz',
                    password => 'nevairbe');

=cut

sub password {
    my $self = shift;
    my ($provider, %args);

    if (@_ == 1) {
	# new password only
	unless ($self->{account}->{username}) {
	    die "Cannot change password for anonymous user";
	}

	$args{username} = $self->{account}->{username};
	$args{password} = shift;
    }
    else {
	%args = @_;

	unless ($provider = $self->exists($args{username})) {
	    die "Cannot change password for user $args{username}.";
	}
    }

    $provider->password($self->{password}->password($args{password}),
			$args{username});
}

=head2 acl

ACL check, see L<ACL::Lite> for details.

=cut

sub acl {
    my ($self, $function, @args) = @_;

    if ($self->{acl}) {
	if ($function eq 'check') {
	    $self->{acl}->check(@args);
	}
    }
}

=head2 value

Retrieve account data.

=cut

sub value {
    my ($self, $name, $value) = @_;

    if (@_ == 3) {
	# update value
	my ($username, $provider);

	$username = $self->{account}->{username};

	unless ($provider = $self->exists($username)) {
	    die "Cannot change value $name for user $username.";
	}

	$provider->value($username, $name, $value);
	$self->{account} = $self->{session_sub}->('update', {$name => $value});

	return $value;
    }

    if (exists $self->{account}->{$name}) {
	return $self->{account}->{$name};
    }
}

=head2 become

Become an user:
    
    $acct->become('shopper@nitesi.biz');

Please use this method with caution.

Providers may choose not to support this method.

=cut

sub become {
    my ($self, $username) = @_;
    my ($p, $acct);
    
    for $p (@{$self->{providers}}) {
        if ($p->can('become')) {
            if ($acct = $p->become($username)) {
                $self->{session_sub}->('init', $acct);
                $self->{account} = $acct;
                return 1;
            }
        }
    }
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
