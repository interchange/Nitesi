# Nitesi::Cart - Nitesi cart class

package Nitesi::Cart;

use strict;
use warnings;

use constant CART_DEFAULT => 'main';

=head1 NAME 

Nitesi::Cart

=head1 VERSION

=head1 CONSTRUCTOR

=head2 new

=cut

sub new {
    my ($class, $self, %args);

    $class = shift;
    %args = @_;

    $self = {error => '', items => [], modifiers => []};

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

=head2 total

Returns total of the cart.

=cut

sub total {
    my ($self) = shift;
    my $total = 0;

    for my $item (@{$self->{items}}) {
	$total += $item->{price} * $item->{quantity};
    }

    return $total;
}
 
=head2 add $item

Add item to the cart. Returns item in case of success.

The item is a hash reference which is subject to the following
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
    my ($self, $item_ref) = @_;
    my (%item, $ret);

    # copy item
    %item = %{$item_ref};

    # run hooks before adding item to cart
    $self->_run_hook('before_cart_add', $self, \%item);

    if (exists $item{error}) {
	# one of the hooks denied the item
	$self->{error} = $item{error};
	return;
    }

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

    unless ($ret = $self->_combine(\%item)) {
	push @{$self->{items}}, \%item;
    }

    # run hooks after adding item to cart
    $ret = $self->_run_hook('after_cart_add', $self, \%item);

    return \%item;
}

=head2 remove $sku

Remove item from the cart. Takes SKU of item to identify the item.

=cut

sub remove {
    my ($self, $arg) = @_;
    my ($pos, $found, $item);

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

	# removing item from our array
	splice(@{$self->{items}}, $pos, 1);

	$self->_run_hook('after_cart_remove', $self, $item);
	return 1;
    }

    # item missing
    $self->{error} = "Missing item $arg.";

    return;
}

=head2 clear

Removes all items from the cart.

=cut

sub clear {
    my ($self) = @_;

    $self->{items} = [];
}

=head2 name

Get or set the name of the cart.

=cut

sub name {
    my $self = shift;

    if (@_ > 0) {
	$self->{name} = $_[0];
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

    return $self->{items};
}

sub _combine {
    my ($self, $item) = @_;

    ITEMS: for my $cartitem (@{$self->{items}}) {
	if ($item->{sku} eq $cartitem->{sku}) {
	    for my $mod (@{$self->{modifiers}}) {
		next ITEMS unless($item->{$mod} eq $cartitem->{$mod});
	    }					
	    			
	    $cartitem->{'quantity'} += $item->{'quantity'};
	    return $item;
	}
    }

    return;
}

sub _run_hook {
    my ($self, $name, @args) = @_;
    my $ret;

    if ($self->{run_hooks}) {
	$ret = $self->{run_hooks}->($name, @args);
    }

    return $ret;
}

1;
