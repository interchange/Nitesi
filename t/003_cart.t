#! perl -T
#
# Tests for Nitesi::Cart.

use strict;
use warnings;

use Test::More tests => 20;

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
ok(@$ret == 1, "Items: $ret");

# Combine items
$item = {sku => 'ABC', name => 'Foobar', price => 5};
$ret = $cart->add($item);
ok(ref($ret) eq 'HASH', $cart->error);

$ret = $cart->items;
ok(@$ret == 1, "Items: $ret");

$item = {sku => 'DEF', name => 'Foobar', price => 5};
$ret = $cart->add($item);
ok(ref($ret) eq 'HASH', $cart->error);

$ret = $cart->items;
ok(@$ret == 2, "Items: $ret");

# Calculating total
$cart->clear;
$ret = $cart->total;
ok($ret == 0, "Total: $ret");

$item = {sku => 'GHI', name => 'Foobar', price => 2.22, quantity => 3};
$ret = $cart->add($item);
ok(ref($ret) eq 'HASH', $cart->error);

$ret = $cart->total;
ok($ret == 6.66, "Total: $ret");

$item = {sku => 'KLM', name => 'Foobar', price => 3.34, quantity => 1};
$ret = $cart->add($item);
ok(ref($ret) eq 'HASH', $cart->error);

$ret = $cart->total;
ok($ret == 10, "Total: $ret");

# Hooks
$cart = Nitesi::Cart->new(run_hooks => sub {
    my ($hook, $cart, $item) = @_;

    if ($hook eq 'before_cart_add' && $item->{price} > 3) {
	$item->{error} = 'Test error';
    }
			  });

$item = {sku => 'KLM', name => 'Foobar', price => 3.34, quantity => 1};
$ret = $cart->add($item);

$ret = $cart->items;
ok(@$ret == 0, "Items: $ret");

ok($cart->error eq 'Test error', "Cart error: " . $cart->error);

# Seed
$cart = Nitesi::Cart->new();
$cart->seed([{sku => 'ABC', name => 'ABC', price => 2, quantity => 1},
	     {sku => 'ABCD', name => 'ABCD', price => 3, quantity => 2},
	    ]);

$ret = $cart->items;
ok(@$ret == 2, "Items: $ret");

$ret = $cart->total;
ok($ret == 8, "Total: $ret");

