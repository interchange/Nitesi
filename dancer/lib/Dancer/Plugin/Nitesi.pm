package Dancer::Plugin::Nitesi;

use 5.0006;
use strict;
use warnings;

use Nitesi::Cart;
use Dancer ':syntax';
use Dancer::Plugin;

=head1 NAME

Dancer::Plugin::Nitesi

=head1 VERSION

Version 0.0001

=cut

our $VERSION = '0.0001';

=head1 SYNOPSIS

    use Dancer::Plugin::Nitesi;

    cart->add({sku => 'ABC', name => 'Foobar', quantity => 1, price => 42});
    cart->items();

=head1 CONFIGURATION

=cut

Dancer::Factory::Hook->instance->install_hooks(qw/before_cart_add after_cart_add/);

my $settings = undef;
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

register cart => sub {
    return vars->{'nitesi_cart_backend'};
};

register_plugin;

sub _load_settings {
    $settings = plugin_setting;
}

1;
