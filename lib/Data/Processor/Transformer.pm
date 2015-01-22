use 5.10.1;
use strict;
use warnings;
package Data::Processor::Transformer;
use Data::Processor::Error::Collection;

use Carp;

# XXX document this with pod. (if standalone)

sub new {
    my $class  = shift;
    my %p      = @_;

    my $self = {

    };
    bless ($self, $class);
    return $self;
}

sub transform{
    my $self           = shift;
    my $schema_section = shift;
    my $data_section   = shift;
    my $key            = shift;

    if (exists $schema_section->{$key}
        and exists $schema_section->{$key}->{transformer}){

        my $return_value;
        eval {
            local $SIG{__DIE__};
            $return_value =
                $schema_section->{$key}->{transformer}
                ->($data_section->{$key},$data_section);

        };
        if (my $err = $@) {
            if (ref $err eq 'HASH' and $err->{msg}){
                $err = $err->{msg};
            }
            return "error transforming '$key': $err";
        }
        else {
            $data_section->{$key} = $return_value;
        }
    }
}

1
