use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
    '\S' => {
        regex => 1,
        description => 'some magic stuff',
        validator => sub {
            my $value = shift;
            $value eq 'magic' ? undef : 'BAD';
        }
    }
};

my $data = {
    X => 'magix',
};


my $p = Data::Processor->new($schema);

like ( [$p->validate($data)->as_array]->[0]->{message}, qr'BAD', 'got an error as expected');

done_testing;
