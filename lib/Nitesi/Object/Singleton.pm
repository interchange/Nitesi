package Nitesi::Object::Singleton;

# This class is a root class for singleton objects in Nitesi.
# It provides basic OO singleton tools for Perl5 without being... MooseX::Singleton ;-)

use strict;
use warnings;
use Carp;

use base qw(Nitesi::Object);

# pool of instances (only one per package name)
my %instances;

# constructor
sub new {
    my ($class) = @_;
    croak "you can't call 'new' on $class, as it's a singleton. Try to call 'instance'";
}

sub instance {
    my ($class, @args) = @_;
    my $instance = $instances{$class};

    # if exists already
    defined $instance
      and return $instance;

    # create the instance
    $instance = bless {}, $class;
    $class->init($instance, @args);

    # save and return it
    $instances{$class} = $instance;
    return $instance;
}

# accessor code for singleton objects
# (overloaded from Nitesi::Object)
sub _setter_code {
    my ($class, $attr) = @_;
    sub {
        my ($class_or_instance, $value) = @_;
        my $instance = ref $class_or_instance ?
          $class_or_instance : $class_or_instance->instance;
        if (@_ == 1) {
            return $instance->{$attr};
        }
        else {
            return $instance->{$attr} = $value;
        }
    };
}

1;

__END__

=head1 NAME

Nitesi::Object::Singleton - Singleton base class for Nitesi

=head1 SYNOPSIS

    package My::Nitesi::Extension;

    use strict;
    use warnings;
    use base 'Nitesi::Object::Singleton';

    __PACKAGE__->attributes( qw/name value this that/ );

    sub init {
        my ($class, $instance) = @_;
        # our initialization code, if we need one
    }

    # .. later on ..

    # returns the unique instance
    my $singleton_intance = My::Nitesi::Extension->instance();

=head1 DESCRIPTION

Nitesi::Object::Singleton is meant to be used instead of Nitesi::Object, if you
want your object to be a singleton, that is, a class that has only one instance
in the application.

It is derived from L<Dancer::Object::Singleton>, which the exception that
instance allows parameters.

It provides you with attributes and an initializer.

=head1 METHODS

=head2 instance

Returns the instance of the singleton. The instance is created only when
needed. The creation will call the C<init()> method, which you should implement.

=head2 init

Exists but does nothing. This is so you won't have to write an initializer if
you don't want to. init receives the instance as argument.

=head2 get_attributes

Get the attributes of the specific class.

=head2 attributes

Generates attributes for whatever object is extending Nitesi::Object and saves
them in an internal hashref so they can be later fetched using
C<get_attributes>.

=head2 new

Calling the constructor will fail as this is a singleton, please use instance
instead.

=head1 AUTHOR

Damien Krotkine

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Damien Krotkine.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

