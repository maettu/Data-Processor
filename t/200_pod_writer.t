use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
    level_1 => {

        members => {
            level_2 => {
                members => {
                    level_3 => {

                    }
                }
            }
        }
    }
};

my $p = Data::Processor->new($schema);
my $pod = $p->pod_write();

done_testing;
