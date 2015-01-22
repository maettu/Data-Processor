# NAME

THIS MODULE ONLY WORKS FOR A NARROW USE CASE RIGHT NOW. ALSO, INTERFACE CHANGES ARE LIKELY.

Data::Processor - Transform Perl Data Structures, Validate Data against a Schema, Produce Data from a Schema, or produce documentation directly from information in the Data

# SYNOPSIS

    use Data::Processor;
    # XXX

# DESCRIPTION

Data::Processor is a tool for transforming, verifying, and producing Perl data structures from / against a schema, defined as a Perl data structure.

# METHODS

## new

    my $processor = Data::Processor->new($schema);

optional parameters:
\- indent: count of spaces to insert when printing in verbose mode. Default 4
\- depth: level at which to start. Default is 0.
\- verbose: Set to a true value to print messages during processing.

## validate
Validate the data against a schema. The schema either needs to be present
already or be passed as an argument.

    my @errors = $processor->validate($data, verbose=>0);

## transform\_data

UNIMPLEMENTED

Transform the data according to rules specified as callbacks that the
module calls for you.

    my ($data_transformed, @errors) = $processor->transform_data(data=>$data);

## transform\_schema

UNIMPLEMENTED

    my ($schema_transformed, @errors) = $processor->transform_schema(schema=>$schema);

## make\_data

UNIMPLEMENTED

    my ($data, @errors) = $processor->make_data(data=>$data);

## make\_pod

UNIMPLEMENTED

    my ($pod, @errors) = $processor->make_pod(data=>$data);

# AUTHOR

Matthias Bloch <matthias.bloch@puffin.ch>

# COPYRIGHT

Copyright 2015- Matthias Bloch

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
