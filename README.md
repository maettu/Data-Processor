# NAME

Data::Processor - Transform Perl Data Structures, Validate Data against a Schema, Produce Data from a Schema, or produce documentation directly from information in the Data

# SYNOPSIS

    use Data::Processor;

# DESCRIPTION

Data::Processor is a tool for transforming, verifying, and producing Perl data structures from / against a schema, defined as a Perl data structure.

# METHODS

## new

    my $processor = Data::Processor->new();

optional parameters:
\- schema: schema to validate against. Can also be specified later
\- indent: count of spaces to insert when printing in verbose mode

## validate
Validate the data against a schema. The schema either needs to be present
already or be passed as an argument.

    my @errors = $processor->validate(schema=>$schema, data=>$data, verbose=>0);

## transform\_data
Transform the data according to rules specified as callbacks that the
module calls for you.
 my ($data\_transformed, @errors) = $processor->transform\_data(data=>$data);

## transform\_schema
 my ($schema\_transformed, @errors) = $processor->transform\_schema(schema=>$schema);

## make\_data
 my ($data, @errors) = $processor->make\_data(data=>$data);

## make\_pod
 my ($pod, @errors) = $processor->make\_pod(data=>$data);

# AUTHOR

Matthias Bloch <matthias.bloch@puffin.ch>

# COPYRIGHT

Copyright 2015- Matthias Bloch

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
