#! perl -T
#
# Tests for Nitesi::Cart costs.

use strict;
use warnings;

use Test::More tests => 2;

use Nitesi::Cart;

my ($cart, $ret);

$cart = Nitesi::Cart->new;

# fixed amount to empty cart
$cart->apply_cost(amount => 5);

$ret = $cart->total;
ok($ret == 5, "Total: $ret");

$cart->clear_cost();

# relative amount to empty cart
$cart->apply_cost(amount => 0.5, relative => 1);

$ret = $cart->total;
ok($ret == 0, "Total: $ret");
