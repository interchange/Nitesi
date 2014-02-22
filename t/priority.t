#! perl
#
# Tests for Nitesi::Cart priority

use strict;
use warnings;

use Test::More tests => 6;
use Nitesi::Cart;
use Data::Dumper;

my $cart = Nitesi::Cart->new();
my $ret = $cart->add({ sku => "123",
                       name => 'test',
                       price => '15',
                       quantity => 1 });

# print Dumper($cart->items);

ok(exists $cart->items->[0]->{priority}, "priority found"),
is($cart->items->[0]->{priority}, 0, "default priority == 0");

$ret = $cart->add({ sku => "123x",
                    name => 'testx',
                    price => '15.2',
                    quantity => 2,
                    priority => 3,
                  });

is($cart->items->[0]->{priority}, 0);
is($cart->items->[1]->{priority}, 3, "Priority added with 3");

$ret = $cart->add({ sku => "123x",
                    name => 'testx',
                    price => '15.2',
                    quantity => 2,
                    priority => 'abc',
                  });
ok(!$ret);
ok($cart->error);
