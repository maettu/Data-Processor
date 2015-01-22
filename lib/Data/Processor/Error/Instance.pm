use 5.10.1;
use strict;
use warnings;
package Data::Processor::Error::Instance;

=head1 NAME
Data::Processor::Error::Instance - An Error

=head1 METHODS
=head2 new

  my $error = Data::Processor::Error::Instance->new(
                message => 'This is an error.',
                path    => 'root->key->another->key',
                caller  => "got called by " . caller();
            );
=cut
use overload ('""' => \&stringify);

sub new {
    my $class = shift;
    my $self = { @_ };
    my %keys  = ( map { $_ => 1 } keys %$self );
    for (qw (message path caller)){
        delete $keys{$_};
        $self->{$_} // die "$_ missing";
    }
    die "Unknown keys ". join (",",keys %keys) if keys %keys;

    # keeping the array and store the message at its location
    $self->{path_array} = $self->{path};
    $self->{path} = join '->', @{$self->{path}};

    bless ($self, $class);
    return $self;
}

=head2 stringify
We 'use overload ('""' => \&stringify)' to call this routine when you
print an error.
Does not take arguments other than $self.
=cut

sub stringify {
    my $self = shift;
    return $self->{path}. ": " . $self->{message};
}

1;
