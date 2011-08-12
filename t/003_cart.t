#! perl -T
#
# Tests for Nitesi::Cart.

use strict;
use warnings;

use Test::More tests => 11;

use Nitesi::Cart;

my ($cart, $item, $name, $ret);

# Get / set cart name
$cart = Nitesi::Cart->new();

$name = $cart->name;
ok($name eq 'main', $name);

$name = $cart->name('discount');
ok($name eq 'discount');

# Items
$cart = Nitesi::Cart->new();

$item = {};
$ret = $cart->add($item);
ok(! defined($ret));

$item->{sku} = 'ABC';
$ret = $cart->add($item);
ok(! defined($ret));

$item->{name} = 'Foobar';
$ret = $cart->add($item);
ok(! defined($ret));

$item->{price} = '42';
$ret = $cart->add($item);
ok(ref($ret) eq 'HASH', $cart->error);

$ret = $cart->items();
ok($ret == 1, "Items: $ret");

# Combine items
$item = {sku => 'ABC', name => 'Foobar', price => 5};
$ret = $cart->add($item);
ok(ref($ret) eq 'HASH', $cart->error);

$ret = $cart->items;
ok($ret == 1, "Items: $ret");

$item = {sku => 'DEF', name => 'Foobar', price => 5};
$ret = $cart->add($item);
ok(ref($ret) eq 'HASH', $cart->error);

$ret = $cart->items;
ok($ret == 2, "Items: $ret");



