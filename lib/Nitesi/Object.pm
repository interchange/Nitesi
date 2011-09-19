package Nitesi::Object;

# This class is a root class for each object in Nitesi.
# It provides basic OO tools for Perl5 without being... Moose ;-)

use strict;
use warnings;
use Carp;

# constructor
sub new {
    my ($class, %args) = @_;
    my $self = \%args;
    bless $self, $class;
    $self->init(%args);
    return $self;
}

# initializer
sub init {1}

# meta information about classes
my $_attrs_per_class = {};
sub get_attributes {
    my ($class, $visited_parents) = @_;
    # $visited_parents keeps track of parent classes we already handled, to
    # avoid infinite recursion (in case of dependancies loop). It's not stored as class singleton, otherwise
    # get_attributes wouldn't be re-entrant.
    $visited_parents ||= {};
    my @attributes = @{$_attrs_per_class->{$class} || [] };
    my @parents;
    { no strict 'refs';
      @parents = @{"$class\::ISA"}; }
    foreach my $parent (@parents) {
        # cleanup $parent
        $parent =~ s/'/::/g;
        $parent =~ /^::/
          and $parent = 'main' . $parent;

        # check we didn't visited it already
        $visited_parents->{$parent}++
          and next;

        # check it's a Nitesi::Object
        $parent->isa(__PACKAGE__)
          or next;

        # merge parents attributes
        push @attributes, @{$parent->get_attributes($visited_parents)};
    }
    return \@attributes;
}

# accessor code for normal objects
# (overloaded in Nitesi::Object::Singleton for instance)
sub _setter_code {
    my ($class, $attr) = @_;
    sub {
        my ($self, $value) = @_;
        if (@_ == 1) {
            return $self->{$attr};
        }
        else {
            return $self->{$attr} = $value;
        }
    };
}

# accessors builder
sub attributes {
    my ($class, @attributes) = @_;

    # save meta information
    $_attrs_per_class->{$class} = \@attributes;

    # define setters and getters for each attribute
    foreach my $attr (@attributes) {
        my $code = $class->_setter_code($attr);
        my $method = "${class}::${attr}";
        { no strict 'refs'; *$method = $code; }
    }
}

sub attributes_defaults {
    my ($self, %defaults) = @_;
    while (my ($k, $v) = each %defaults) {
        exists $self->{$k} or $self->{$k} = $v;
    }
}

1;

__END__

=head1 NAME

Nitesi::Object - Objects base class for Nitesi

=head1 SYNOPSIS

    package My::Nitesi::Extension;

    use strict;
    use warnings;
    use base 'Nitesi::Object';

    __PACKAGE__->attributes( qw/name value this that/ );

    sub init {
        # our initialization code, if we need one
    }

=head1 DESCRIPTION

While we B<love> L<Moose>, we can't use it for Nitesi and still keep Nitesi
minimal, so we copied Dancer::Object to Nitesi::Object instead (and leaving
clone method out).

It provides you with attributes and an initializer.

=head1 METHODS

=head2 new

Creates a new object of whatever is based off Nitesi::Object. This is a generic
C<new> method so you don't have to write one yourself when extending
C<Nitesi::Object>.

It accepts arguments in a hash and runs an additional C<init> method (described
below) which you should implement.

=head2 init

Exists but does nothing. This is so you won't have to write an initializer if
you don't want to.

=head2 get_attributes

Get the attributes of the specific class.

=head2 attributes

Generates attributes for whatever object is extending Nitesi::Object and saves
them in an internal hashref so they can be later fetched using
C<get_attributes>.

For each defined attribute you can access its value using:

  $self->your_attribute_name;

To set a value use

  $self->your_attribute_name($value);

Nevertheless, you can continue to use these attributes as hash keys,
as usual with blessed hash references:

  $self->{your_attribute_name} = $value;

Although this is possible we defend you should use the method
approach, as it maintains compatibility in case C<Nitesi::Object>
structure changes in the future.

=head2 attributes_defaults

  $self->attributes_defaults(length => 2);

given a hash (not a hashref), makes sure an object has the given attributes
default values. Usually called from within an C<init> function.

=head1 AUTHOR

Alexis Sukrieh

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2010 Alexis Sukrieh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

