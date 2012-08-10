package Nitesi::Transaction;

use Moo;
use Sub::Quote;

=head1 NAME

Nitesi::Transaction - Transaction class for Nitesi Shop Machine

=cut

has code => (
    is => 'rw',
);

has subtotal => (
    is => 'rw',
);

has shipping => (
    is => 'rw',
);

has salestax => (
    is => 'rw',
);

has total_cost => (
    is => 'rw',
);

has weight => (
    is => 'rw',
);

has uid => (
    is => 'rw',
);

has email => (
    is => 'rw',
);

has lname => (
    is => 'rw',
);

has fname => (
    is => 'rw',
);

has order_date => (
    is => 'rw',
);

has update_date => (
    is => 'rw',
);

has status => (
    is => 'rw',
);

has shipping_method => (
    is => 'rw',
);

has shipping_description => (
    is => 'rw',
);

has aid_shipping => (
    is => 'rw',
);

has aid_billing => (
    is => 'rw',
);

sub api_info {
    return {table => 'transactions',
            key => 'code',
    };
};

1;
