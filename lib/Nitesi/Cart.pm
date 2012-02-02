# Nitesi::Cart - Nitesi cart class

package Nitesi::Cart;

use strict;
use warnings;

use constant CART_DEFAULT => 'main';

=head1 NAME 

Nitesi::Cart - Cart class for Nitesi Shop Machine

=head1 DESCRIPTION

Generic cart class for L<Nitesi>.

=head2 CART ITEMS

Each item in the cart has at least the following attributes:

=over 4

=item sku

Unique item identifier.

=item name

Item name.

=item quantity

Item quantity.

=item price

Item price.

=back

=head1 CONSTRUCTOR

=head2 new

=cut

sub new {
    my ($class, $self, %args);

    $class = shift;
    %args = @_;

    $self = {error => '', items => [], modifiers => [],
	     costs => [], subtotal => 0, total => 0, 
	     cache_subtotal => 1, cache_total => 1,
    };

    if ($args{name}) {
	$self->{name} = $args{name};
    }
    else {
	$self->{name} = CART_DEFAULT;
    }

    if ($args{modifiers}) {
	$self->{modifiers} = $args{modifiers};
    }

    if ($args{run_hooks}) {
	$self->{run_hooks} = $args{run_hooks};
    }

    bless $self, $class;

    $self->init(%args);

    return $self;
}

=head2 init

Initializer which receives the constructor arguments, but does nothing.
May be overridden in a subclass.

=cut

sub init {
    return 1;
};

=head2 items

Returns items in the cart.

=cut

sub items {
    my ($self) = shift;

    return $self->{items};
}

=head2 subtotal

Returns subtotal of the cart.

=cut

sub subtotal {
    my ($self) = shift;

    if ($self->{cache_subtotal}) {
	return $self->{subtotal};
    }

    $self->{subtotal} = 0;

    for my $item (@{$self->{items}}) {
	$self->{subtotal} += $item->{price} * $item->{quantity};
    }

    $self->{cache_subtotal} = 1;

    return $self->{subtotal};
}

=head2 total

Returns total of the cart.

=cut

sub total {
    my ($self) = shift;
    my ($subtotal);

    if ($self->{cache_total}) {
	return $self->{total};
    }

    $self->{total} = $subtotal = $self->subtotal();

    # calculate costs
    $self->{total} += $self->_calculate($subtotal);

    $self->{cache_total} = 1;

    return $self->{total};
}
 
=head2 add $item

Add item to the cart. Returns item in case of success.

The item is a hash (reference) which is subject to the following
conditions:

=over 4

=item sku

Item identifier is required.

=item name

Item name is required.

=item quantity

Item quantity is optional and has to be a natural number greater
than zero. Default for quantity is 1.

=item price

Item price is required and a positive number.

=back

=cut

sub add {
    my $self = shift;
    my (%item, $ret);

    if (ref($_[0])) {
	# copy item
	%item = %{$_[0]};
    }
    else {
	%item = @_;
    }

    # run hooks before validating item
    $self->_run_hook('before_cart_add_validate', $self, \%item);

    # validate item
    unless (exists $item{sku} && defined $item{sku} && $item{sku} =~ /\S/) {
	$self->{error} = 'Item added without SKU.';
	return;
    }

    unless (exists $item{name} && defined $item{name} && $item{name} =~ /\S/) {
	$self->{error} = "Item $item{sku} added without a name.";
	return;
    }

    if (exists $item{quantity} && defined $item{quantity}) {
	unless ($item{quantity} =~ /^(\d+)$/ && $item{quantity} > 0) {
	    $self->{error} = "Item $item{sku} added with invalid quantity $item{quantity}.";
	    return;
	}
    }
    else {
	$item{quantity} = 1;
    }

    unless (exists $item{price} && defined $item{price}
	    && $item{price} =~ /^(\d+)(\.\d+)?$/ && $item{price} > 0) {
	$self->{error} = "Item $item{sku} added with invalid price.";
	return;
    }
  
    # run hooks before adding item to cart
    $self->_run_hook('before_cart_add', $self, \%item);

    if (exists $item{error}) {
	# one of the hooks denied the item
	$self->{error} = $item{error};
	return;
    }

    # clear cache flags
    $self->{cache_subtotal} = $self->{cache_total} = 0;

    unless ($ret = $self->_combine(\%item)) {
	push @{$self->{items}}, \%item;
    }

    # run hooks after adding item to cart
    $self->_run_hook('after_cart_add', $self, \%item, $ret);

    return \%item;
}

=head2 remove $sku

Remove item from the cart. Takes SKU of item to identify the item.

=cut

sub remove {
    my ($self, $arg) = @_;
    my ($pos, $found, $item);

    $pos = 0;
  
    # run hooks before locating item
    $self->_run_hook('before_cart_remove_validate', $self, $arg);

    for $item (@{$self->{items}}) {
	if ($item->{sku} eq $arg) {
	    $found = 1;
	    last;
	}
	$pos++;
    }

    if ($found) {
	# run hooks before adding item to cart
	$item = $self->{items}->[$pos];

	$self->_run_hook('before_cart_remove', $self, $item);

	if (exists $item->{error}) {
	    # one of the hooks denied removing the item
	    $self->{error} = $item->{error};
	    return;
	}

	# clear cache flags
	$self->{cache_subtotal} = $self->{cache_total} = 0;

	# removing item from our array
	splice(@{$self->{items}}, $pos, 1);

	$self->_run_hook('after_cart_remove', $self, $item);
	return 1;
    }

    # item missing
    $self->{error} = "Missing item $arg.";

    return;
}

=head2 update

Update items in the cart.

Parameters are pairs of SKUs and quantities, e.g.

    $cart->update(9780977920174 => 5,
                  9780596004927 => 3);

=cut

sub update {
    my ($self, @args) = @_;
    my ($ref, $sku, $qty, $item, $new_item);

    while (@args > 0) {
	$sku = shift @args;
	$qty = shift @args;

	unless ($item = $self->_find($sku)) {
	    die "Item for $sku not found in cart.\n";
	}

	# jump to next item if quantity stays the same
	next if $qty == $item->{quantity};

	# run hook before updating the cart
	$new_item = {quantity => $qty};

	$self->_run_hook('before_cart_update', $self, $item, $new_item);

	if (exists $new_item->{error}) {
	    # one of the hooks denied the item
	    $self->{error} = $new_item->{error};
	    return;
	}

	$self->_run_hook('after_cart_update', $self, $item, $new_item);

	$item->{quantity} = $qty;
    }
}

=head2 clear

Removes all items from the cart.

=cut

sub clear {
    my ($self) = @_;

    # run hook before clearing the cart
    $self->_run_hook('before_cart_clear', $self);
    
    $self->{items} = [];

    # run hook after clearing the cart
    $self->_run_hook('after_cart_clear', $self);

    # reset subtotal/total
    $self->{subtotal} = 0;
    $self->{total} = 0;
    $self->{cache_subtotal} = 1;
    $self->{cache_total} = 1;

    return;
}

=head2 quantity

Returns the sum of the quantity of all items in the shopping cart,
which is commonly used as number of items.

    print 'Items in your cart: ', $cart->quantity, "\n";

=cut

sub quantity {
    my $self = shift;
    my $qty = 0;

    for my $item (@{$self->{items}}) {
	$qty += $item->{quantity};
    }

    return $qty;
}

=head2 count

Returns the number of different items in the shopping cart.

=cut

sub count {
    my $self = shift;

    return scalar(@{$self->{items}});
}

=head2 apply_cost 

Apply cost to cart.

Absolute cost:

    $cart->apply_cost(amount => 5, name => 'shipping', label => 'Shipping');

Relative cost:

    $cart->apply_cost(amount => 0.19, name => 'tax', label => 'Sales Tax',
                      relative => 1);

Inclusive cost:

   $cart->apply_cost(amount => 0.19, name => 'tax', label => 'Sales Tax',
                      relative => 1, inclusive => 1);

=cut

sub apply_cost {
    my ($self, %args) = @_;

    push @{$self->{costs}}, \%args;

    unless ($args{inclusive}) {
	# clear cache for total
	$self->{cache_total} = 0;
    }
}

=head2 clear_cost

Clear costs.

=cut

sub clear_cost {
    my $self = shift;

    $self->{costs} = [];

    $self->{cache_total} = 0;
}

=head2 cost

Returns particular cost by position or by name.

=cut

sub cost {
    my ($self, $loc) = @_;
    my ($cost, $ret);

    if (defined $loc) {
	if ($loc =~ /^\d+/) {
	    # cost by position
	    $cost = $self->{costs}->[$loc];
	}
	elsif ($loc =~ /\S/) {
	    # cost by name
	    for my $c (@{$self->{costs}}) {
		if ($c->{name} eq $loc) {
		    $cost = $c;
		}
	    }
	}
    }

    if (defined $cost) {
	$ret = $self->_calculate($self->{subtotal}, $cost, 1);
    }

    return $ret;
}

=head2 id

Get or set id of the cart. This can be used for subclasses, 
e.g. primary key value for carts in the database.

=cut

sub id {
    my $self = shift;

    if (@_ > 0) {
	$self->{id} = $_[0];
    }

    return $self->{id};
}

=head2 name

Get or set the name of the cart.

=cut

sub name {
    my $self = shift;

    if (@_ > 0) {
	my $old_name = $self->{name};

	$self->_run_hook('before_cart_rename', $self, $old_name, $_[0]);

	$self->{name} = $_[0];

	$self->_run_hook('after_cart_rename', $self, $old_name, $_[0]);
    }

    return $self->{name};
}

=head2 error

Returns last error.

=cut

sub error {
    my $self = shift;

    return $self->{error};
}

=head2 seed $item_ref

Seeds items within the cart from $item_ref.

=cut

sub seed {
    my ($self, $item_ref) = @_;

    @{$self->{items}} = @{$item_ref || []};

    # clear cache flags
    $self->{cache_subtotal} = $self->{cache_total} = 0;

    return $self->{items};
}

sub _find {
    my ($self, $sku) = @_;

    for my $cartitem (@{$self->{items}}) {
	if ($sku eq $cartitem->{sku}) {
	    return $cartitem;
        }
    }

    return;
}

sub _combine {
    my ($self, $item) = @_;

    ITEMS: for my $cartitem (@{$self->{items}}) {
	if ($item->{sku} eq $cartitem->{sku}) {
	    for my $mod (@{$self->{modifiers}}) {
		next ITEMS unless($item->{$mod} eq $cartitem->{$mod});
	    }					
	    			
	    $cartitem->{'quantity'} += $item->{'quantity'};
	    $item->{'quantity'} = $cartitem->{'quantity'};

	    return 1;
	}
    }

    return 0;
}

sub _calculate {
    my ($self, $subtotal, $costs, $display) = @_;
    my ($cost_ref, $sum);

    if (ref $costs eq 'HASH') {
	$cost_ref = [$costs];
    }
    elsif (ref $costs eq 'ARRAY') {
	$cost_ref = $costs;
    }
    else {
	$cost_ref = $self->{costs};
    }

    $sum = 0;

    for my $calc (@$cost_ref) {
	if ($calc->{inclusive} && ! $display) {
	    next;
	}

	if ($calc->{relative}) {
	    $sum += $subtotal * $calc->{amount};
        }
	else {
	    $sum += $calc->{amount};
	}
    }

    return $sum;
}

sub _run_hook {
    my ($self, $name, @args) = @_;
    my $ret;

    if ($self->{run_hooks}) {
	$ret = $self->{run_hooks}->($name, @args);
    }

    return $ret;
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
