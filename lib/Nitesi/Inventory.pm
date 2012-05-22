package Nitesi::Inventory;

use strict;
use warnings;

use Moo::Role;
use Sub::Quote;

=head1 NAME

Nitesi::Inventory - Inventory for Nitesi Shop Machine

=cut

has quantity => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return 0;},
);

has in_stock => (
    is => 'rw',
);

sub api_info {
    return {table => 'inventory',
	    key => 'sku',
	    sparse => 1,
    };
}

1;
