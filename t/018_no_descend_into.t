use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
    key_with_unchecked_content => {
        members => {
            noo => {value => qr{1}},
            foo => {value => qr{2}},
            bluu=> {value => qr{42}},
        }
    }
};

my $data = {
    key_with_unchecked_content => {
        whatever => 'may be here',
        it       => "won't be checked",
    }

};
my $p = Data::Processor->new($schema);

my $error_collection = $p->validate($data, verbose=>0);
my $error_count = scalar(@{$error_collection->{errors}});
ok (
    $error_count == 5,
    'Should have 5 errors because of not matching content, found '.
    $error_count
);

$schema = {
    key_with_unchecked_content => {
        no_descend_into => 1,
        members => {
            noo => {value => qr{1}},
            foo => {value => qr{2}},
            bluu=> {value => qr{42}},
        }
    }
};

$p = Data::Processor->new($schema);
my $error_collection = $p->validate($data, verbose=>0);
my $error_count = scalar(@{$error_collection->{errors}});
ok (
    $error_count == 0,
    'No more errors because of "no_descend_into", found '.
    $error_count
);



done_testing;
