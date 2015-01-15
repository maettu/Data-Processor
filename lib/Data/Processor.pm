package Data::Processor;

use strict;
use 5.010_001;
our $VERSION = '0.0.1';

use Data::Processor::Error::Collection;

=head1 NAME

Data::Processor - Transform Perl Data Structures, Validate Data against a Schema, Produce Data from a Schema, or produce documentation directly from information in the Data

=head1 SYNOPSIS

  use Data::Processor;

=head1 DESCRIPTION

Data::Processor is a tool for transforming, verifying, and producing Perl data structures from / against a schema, defined as a Perl data structure.

=head1 METHODS

=head2 new

 my $processor = Data::Processor->new();

optional parameters:
- schema: schema to validate against. Can also be specified later
- indent: count of spaces to insert when printing in verbose mode

=cut
sub new{
    my $class = shift;
    my %p     = @_;
    my $self = {
        schema => $p{schema} // undef,
        errors => Data::Processor::Error::Collection->new(),
        depth  => 0,
        indent => $p{indent} // 4,
        parent_keys => ['root']
    };
    bless ($self, $class);
    return $self;
}

=head2 validate
Validate the data against a schema. The schema either needs to be present
already or be passed as an argument.

 my @errors = $processor->validate(schema=>$schema, data=>$data, verbose=>0);
=cut
sub validate{
    require Data::Processor::Validator;
    my $self = shift;
    die 'unimplemented';
    # XXX
}

=pod
=head2 transform_data
Transform the data according to rules specified as callbacks that the
module calls for you.
 my ($data_transformed, @errors) = $processor->transform_data(data=>$data);
=cut
sub transform_data{
    require Data::Processor::Transformer;
    die 'unimplemented';
    #XXX
}

=pod
=head2 transform_schema
 my ($schema_transformed, @errors) = $processor->transform_schema(schema=>$schema);
=cut
sub transform_schema{
    require Data::Processor::Transformer;
    die 'unimplemented';
    # XXX
}

=pod
=head2 make_data
 my ($data, @errors) = $processor->make_data(data=>$data);
=cut
sub make_data{
    require Data::Processor::Generator;
    die 'unimplemented';
    # XXX
}

=pod
=head2 make_pod
 my ($pod, @errors) = $processor->make_pod(data=>$data);
=cut
sub make_pod{
    require Data::Processor::PodWriter;
    die 'unimplemented';
    # XXX
}

=head1 AUTHOR

Matthias Bloch E<lt>matthias.bloch@puffin.chE<gt>

=head1 COPYRIGHT

Copyright 2015- Matthias Bloch

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
1;
__END__

