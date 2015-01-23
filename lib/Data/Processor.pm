package Data::Processor;

use strict;
use 5.010_001;
our $VERSION = '0.1.6';

use Carp;
use Data::Processor::Error::Collection;
use Data::Processor::Validator;
use Data::Processor::Transformer;
use Data::Processor::Generator;
use Data::Processor::PodWriter;

=head1 NAME

THIS MODULE ONLY WORKS FOR A NARROW USE CASE RIGHT NOW. ALSO, INTERFACE CHANGES ARE LIKELY.

Data::Processor - Transform Perl Data Structures, Validate Data against a Schema, Produce Data from a Schema, or produce documentation directly from information in the Data

=head1 SYNOPSIS

  use Data::Processor;
  # XXX

=head1 DESCRIPTION

Data::Processor is a tool for transforming, verifying, and producing Perl data structures from / against a schema, defined as a Perl data structure.

=head1 METHODS

=head2 new

 my $processor = Data::Processor->new($schema);

optional parameters:
- indent: count of spaces to insert when printing in verbose mode. Default 4
- depth: level at which to start. Default is 0.
- verbose: Set to a true value to print messages during processing.

=cut
sub new{
    my $class  = shift;
    my $schema = shift;
    my %p     = @_;
    my $self = {
        schema      => $schema,
        errors      => Data::Processor::Error::Collection->new(),
        depth       => $p{depth}  // 0,
        indent      => $p{indent} // 4,
        parent_keys => ['root'],
        verbose     => $p{verbose} // undef,
    };
    bless ($self, $class);
    return $self;
}

=head2 validate
Validate the data against a schema. The schema either needs to be present
already or be passed as an argument.

 my @errors = $processor->validate($data, verbose=>0);
=cut
sub validate{
    my $self = shift;
    my $data = shift;
    my %p    = @_;

    $self->{validator}=Data::Processor::Validator->new(
        $self->{schema} // $p{schema},
        verbose     => $p{verbose} // $self->{verbose} // undef,
        errors      => $self->{errors},
        depth       => $self->{depth},
        indent      => $self->{indent},
        parent_keys => $self->{parent_keys},
    );
    return $self->{validator}->validate($data);
}

=head2 transform_data

UNIMPLEMENTED

Transform the data according to rules specified as callbacks that the
module calls for you.

 my ($data_transformed, @errors) = $processor->transform_data(data=>$data);

=cut
sub transform_data{
    die 'unimplemented';
    #XXX
}

=head2 transform_schema

UNIMPLEMENTED

 my ($schema_transformed, @errors) = $processor->transform_schema(schema=>$schema);

=cut
sub transform_schema{
    die 'unimplemented';
    # XXX
}

=head2 make_data

UNIMPLEMENTED

 my ($data, @errors) = $processor->make_data(data=>$data);

=cut
sub make_data{
    die 'unimplemented';
    # XXX
}

=head2 make_pod

UNIMPLEMENTED

 my ($pod, @errors) = $processor->make_pod(data=>$data);

=cut
sub make_pod{
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

=cut
1;
__END__

