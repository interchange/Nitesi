package Dancer::Plugin::Nitesi;

use 5.0006;
use strict;
use warnings;

use Nitesi::Account::Manager;
use Nitesi::Cart;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Plugin::Database;

=head1 NAME

Dancer::Plugin::Nitesi - Nitesi Shop Machine plugin for Dancer

=head1 VERSION

Version 0.0001

=cut

our $VERSION = '0.0001';

=head1 SYNOPSIS

    use Dancer::Plugin::Nitesi;

    cart->add({sku => 'ABC', name => 'Foobar', quantity => 1, price => 42});
    cart->items();

    account->login(username => 'frank@nitesi.com', password => 'nevairbe');
    account->acl(check => 'view_prices');
    account->logout();

=head1 CONFIGURATION

The default configuration is as follows:

    plugins:
      Nitesi:
        Account:
          Session:
          Key: account
        Provider: DBI
      Cart:
        Backend: Session

=cut

Dancer::Factory::Hook->instance->install_hooks(qw/before_cart_add after_cart_add/);

my $settings = undef;

my %acct_providers;
my %carts;

before sub {
    # find out which backend we are using
    my ($backend, $backend_class, $backend_obj);

    _load_settings() unless $settings;

    if (exists $settings->{Cart}->{Backend}) {
	$backend = $settings->{Cart}->{Backend};
    }
    else {
	$backend = 'Session';
    }

    # load backend class
    if ($backend =~ /::/) {
	$backend_class = $backend;
    }
    else {
	$backend_class = __PACKAGE__ . "::Cart::$backend";
    }

    eval "require $backend_class";

    if ($@) {
	die "Failed to load $backend_class: $@\n";
    }

    # instantiate backend object
    eval {
	$backend_obj = $backend_class->new(name => '',
					   run_hooks => sub {Dancer::Factory::Hook->instance->execute_hooks(@_)});
    };

    if ($@) {
	die "Failed to instantiate $backend_class: $@\n";
    }

    $backend_obj->load();

    var nitesi_cart_backend => $backend_obj;
};

after sub {
    my $backend_obj;

    $backend_obj = vars->{'nitesi_cart_backend'};

    $backend_obj->save();

    var nitesi_cart_backend => undef;
};

register account => sub {
    my $acct;

    unless (vars->{'nitesi_account'}) {
	# not yet used in this request
	$acct = Nitesi::Account::Manager->instance(provider_sub => \&_load_account_providers, 
						   session_sub => \&_update_session);
	$acct->init_from_session;

	var nitesi_account => $acct;
    }

    return vars->{'nitesi_account'};
};

register cart => sub {
    return vars->{'nitesi_cart_backend'};
};

register_plugin;

sub _load_settings {
    $settings = plugin_setting;
}

sub _load_account_providers {
    # setup account providers
    if (exists $settings->{Account}->{Provider}) {
	if ($settings->{Account}->{Provider} eq 'DBI') {
	    # we need to pass $dbh
	    return [['Nitesi::Account::Provider::DBI',
		     dbh => database()]];
	}
    }
}

sub _update_session {
    my ($function, $acct) = @_;
    my ($key, $sref);

    # determine session key
    $key = $settings->{Account}->{Session}->{Key} || 'user';

    if ($function eq 'init') {
	# initialize user related information
	session $key => $acct;
    }
    elsif ($function eq 'update') {
	# update user related information (retrieve current state first)
	$sref = session $key;

	for my $name (keys %$acct) {
	    $sref->{$name} = $acct->{$name};
	}

	session $key => $sref;

	return $sref;
    }
    elsif ($function eq 'destroy') {
	# destroy user related information
	session $key => undef;
    }
    else {
	# return user related information
	return session $key;
    }
}

1;
