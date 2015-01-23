use 5.10.1;
use strict;
use warnings;
package Data::Processor::Transformer;

# XXX document this with pod. (if standalone)

sub new {
    my $class  = shift;

    my $self = {};
    bless ($self, $class);
    return $self;
}

sub transform{
    my $self    = shift;
    my $key     = shift;
    my $section = shift;

    if (exists $section->{schema}->{$key}
        and exists $section->{schema}->{$key}->{transformer}){

        my $return_value;
        eval {
            local $SIG{__DIE__};
            $return_value =
                $section->{schema}->{$key}->{transformer}
                ->($section->{data}->{$key},$section->{data});

        };
        if (my $err = $@) {
            if (ref $err eq 'HASH' and $err->{msg}){
                $err = $err->{msg};
            }
            return "error transforming '$key': $err";
        }
        else {
            $section->{data}->{$key} = $return_value;
        }
    }
}

1
