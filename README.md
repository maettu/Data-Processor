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

## validate\_schema

check that the schema is valid

## transform\_data

Transform one key in the data according to rules specified
as callbacks that themodule calls for you.
Transforms the data in-place.

    my $validator = Data::Processor::Validator->new($schema, data => $data)
    my $error_string = $processor->transform($key, $validator);

This is not tremendously useful at the moment, especially because validate()
transforms during validation.

## make\_data

UNIMPLEMENTED

    my ($data, @errors) = $processor->make_data(data=>$data);

## make\_pod

Write descriptive pod from the schema.

    my $pod_string = $processor->make_pod();

# AUTHOR

Matthias Bloch <matthias.bloch@puffin.ch>

# COPYRIGHT

Copyright 2015- Matthias Bloch

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
