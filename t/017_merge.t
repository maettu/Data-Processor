use strict;
use FindBin; use lib "$FindBin::Bin/../lib";
#use lib 'lib';
use Test::More;
use Data::Processor;
use Data::Dumper;

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

my $p = Data::Processor->new($schema);

$p->merge_schema($schema_2);

print Dumper $p->{schema};

my $error_collection = $p->validate($data, verbose=>1);

# wrong array element will give 3 errors: 1 wrong key and 2 missing mandatory keys
ok ($error_collection->count == 1, '1 error detected');

done_testing;

