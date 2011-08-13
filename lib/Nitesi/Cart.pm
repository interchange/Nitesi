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

    bless $self, $class;

    return $self;
}

=head2 items

Returns items in the cart.

=cut

sub items {
    my ($self) = shift;

    wantarray ? @{$self->{items}} : scalar @{$self->{items}};
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
    my (%item);

    # copy item
    %item = %{$item_ref};

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
	    && $item{price} =~ /^(\d+)$/ && $item{price} > 0) {
	$self->{error} = "Item $item{sku} added with invalid price.";
	return;
    }
    my $ret = '';
    unless ($ret = $self->_combine(\%item)) {
	push @{$self->{items}}, \%item;
    }

    return \%item;
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

1;
