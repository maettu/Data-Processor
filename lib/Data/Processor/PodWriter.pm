use 5.10.1;
use strict;
use warnings;
package Data::Processor::PodWriter;

sub pod_write{
    my $schema = shift;
    use Data::Dumper; say Dumper $schema;

}

1
