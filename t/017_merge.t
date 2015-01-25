use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
    merge => {
        members => {
            number => {
                validator => sub {
                    my $value = shift;
                    return $value =~ /^[0-5]$/ ? undef : 'number from 0-5 expected';
                },
            },
        },
    },
};

my $schema_2 = {
    merge => {
        members => {
            number => {
                validator => sub {
                    my $value = shift;
                    return $value =~ /^\d$/ ? undef : 'number from 0-9 expected';
                },
            },
        },
    },
};

my $data = {
    merge => {
        number => 8,
    }
};

my $p = Data::Processor->new( { %$schema, %$schema_2 } );

my $error_collection = $p->validate($data, verbose=>0);

# wrong array element will give 3 errors: 1 wrong key and 2 missing mandatory keys
ok ($error_collection->count == 1, '1 error detected');

done_testing;

