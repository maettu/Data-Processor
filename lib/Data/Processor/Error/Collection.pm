use 5.10.1;
use strict;
use warnings;
package Data::Processor::Error::Collection;
use Data::Processor::Error::Instance;

=head1 NAME
Data::Processor::Error::Collection - Collect errors for Data::Processor

=head1 METHODS
=head2 new

    my $errors = Data::Processor::Error::Collection->new();

=cut
sub new {
    my $class = shift;
    my $self = {
        errors => [] # the error instances are going into here
    };
    bless ($self, $class);
    return $self;
}

=head2 add
Adds an error.
=cut
sub add {
    my $self = shift;
    my %p    = @_;
    my $error = Data::Processor::Error::Instance->new(%p);
    push @{$self->{errors}}, $error;
}

=head2 as_array
    Return all collected errors as an array.
=cut
sub as_array {
    my $self = shift;
    return @{$self->{errors}};
}

=head2 count
    Return count of errors.
=cut
sub count {
    my $self = shift;
    return scalar @{$self->{errors}};
}
1;

