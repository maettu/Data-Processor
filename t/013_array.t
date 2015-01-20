use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
    array => {
        array => 1,
        members => {
            one => {
                value => qr{what.*}
            },
            two => {
                value => qr{something.*}
            }
        }
    },
    bar => {
        members => {
            bar_one => {
                value => qr{not_there}
            }
        }
    },
    simplearray => {
        array => 1,
        validator => sub {
            my $value = shift;
            return $value =~ /\d+/ ? undef : 'numeric element expected';
        }
    },
};

my $data = {
    'array' => [
        {
            one => 'whatever',
            two => 'something else'
        },
        {
            'error: members missing',
        },

    ],
    'foo'  => 'error: members missing',
    'fo'   => 'not in schema',

    bar => 'empty',

    simplearray => [0, 1, 'fail', 3, 4],
};

my $p = Data::Processor->new(schema => $schema);

my $error_collection = $p->validate(data => $data, verbose=>0);

# wrong array element will give 3 errors: 1 wrong key and 2 missing mandatory keys
ok ($error_collection->count == 7, '7 errors detected');

ok ($error_collection->any_error_contains(
        string => 'should have members',
        field  => 'message'
    ),
    'config leaf that should be branch detected'
);

done_testing;

