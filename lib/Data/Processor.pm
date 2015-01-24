package Data::Processor;

use strict;
use 5.010_001;
our $VERSION = '0.2.0';

use Carp;
use Data::Processor::Error::Collection;
use Data::Processor::Validator;
use Data::Processor::Transformer;
use Data::Processor::Generator;
use Data::Processor::PodWriter;
use Data::Processor::ValidatorFactory;

=head1 NAME

Data::Processor - Transform Perl Data Structures, Validate Data against a Schema, Produce Data from a Schema, or produce documentation directly from information in the Schema.

=head1 SYNOPSIS

  use Data::Processor;
  my $schema = {
    section => {
        description => 'a section with a few members',
        error_msg   => 'cannot find "section" in config',
        members => {
            foo => {
                # value restriction either with a regex..
                value => qr{f.*},
                description => 'a string beginning with "f"'
            },
            bar => {
                # ..or with a validator callback.
                validator => sub {
                    my $self   = shift;
                    my $parent = shift;
                    # undef is "no-error" -> success.
                    no strict 'refs';
                    return undef
                        if $self->{value} == 42;
                }
            },
            wuu => {
                optional => 1
            }
        }
    }
  };

  my $p = Data::Processor->new($schema);

  my $data = {
    section => {
        foo => 'frobnicate',
        bar => 42,
        # "wuu" being optional, can be omitted..
    }
  };

  my $error_collection = $p->validate($data, verbose=>0);
  # no errors :-)

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
        schema      => $schema // {},
        errors      => Data::Processor::Error::Collection->new(),
        depth       => $p{depth}  // 0,
        indent      => $p{indent} // 4,
        parent_keys => ['root'],
        verbose     => $p{verbose} // undef,
    };
    bless ($self, $class);
    my $e = $self->validate_schema;
    if ($e->count > 0){
        croak "There is a problem with your schema:".join "\n", $e->as_array;
    }
    return $self;
}

=head2 validate
Validate the data against a schema. The schema either needs to be present
already or be passed as an argument.

 my $error_collection = $processor->validate($data, verbose=>0);
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

=head2 validate_schema

check that the schema is valid.
This method gets called upon creation of a new Data::Processor object.

 my $error_collection = $processor->validate_schema();

=cut

sub validate_schema {
    my $self = shift;
    my $vf = Data::Processor::ValidatorFactory->new;
    my $bool = $vf->rx(qr(^[01]$),'Expected 0 or 1');
    my $schemaSchema;
    $schemaSchema = {
        '.+' => {
            regex => 1,
            optional => 1,
            description => 'content description for the key',
            members => {
                description => {
                    description => 'the description of this content of this key',
                    optional => 1,
                    validator => $vf->rx(qr(.+),'expected a description string'),
                },
                example => {
                    description => 'an example value for this key',
                    optional => 1,
                    validator => $vf->rx(qr(.+),'expected an example string'),
                },
                regex => {
                    description => 'should this key be treated as a regular expression?',
                    optional => 1,
                    default => 0,
                    validator => $bool
                },
                value => {
                    description => 'a regular expression describing the expected value',
                    optional => 1,
                    validator => sub {
                        ref shift eq 'Regexp' ? undef : 'expected a regular expression value (qr/.../)'
                    }
                },
                error_msg => {
                    description => 'an error message for the case that the value regexp does not match',
                    optional => 1,
                    validator => $vf->rx(qr(.+),'expected an error message string'),
                },
                optional => {
                    description => 'is this key optional ?',
                    optional => 1,
                    default => 0,
                    validator => $bool,
                },
                default => {
                    description => 'the default value for this key',
                    optional => 1
                },
                array => {
                    description => 'is the value of this key expected to be an array? In array mode, value and validator will be applied to each element of the array.',
                    optional => 1,
                    default => 0,
                    validator => $bool
                },
                members => {
                    description => 'what keys do I expect in a hash hanging off this key',
                    optional => 1,
                    validator => sub {
                        my $value = shift;
                        if (ref $value ne 'HASH'){
                            return "expected a hash"
                        }
                        my $subVal=Data::Processor::Validator->new($schemaSchema,%$self);
                        my $e = $subVal->validate($value);
                        return ( $e->count > 0 ? join("\n", $e->as_array) : undef);
                    }
                },
                validator => {
                    description => 'a callback which gets called with (value,section) to validate the value. If it returns anything, this is treated as an error message',
                    optional => 1,
                    validator => sub {
                        ref shift eq 'CODE' ? undef : 'expected a callback'
                    },
                    example => 'sub { my ($value,$section) = @_; return $value <= 1 ? "value must be > 1" : undef}'
                },
                transformer => {
                    description => 'a callback which gets called on the value with (value,section) to validate the value. If it returns anything, this is treated as an error message',
                    optional => 1,
                    validator => sub {
                        ref shift eq 'CODE' ? undef : 'expected a callback'
                    }
                }
            }
        }
    };
    return Data::Processor::Validator->new($schemaSchema,%$self)->validate($self->{schema});
}

=head2 transform_data

Transform one key in the data according to rules specified
as callbacks that themodule calls for you.
Transforms the data in-place.

 my $validator = Data::Processor::Validator->new($schema, data => $data)
 my $error_string = $processor->transform($key, $validator);

This is not tremendously useful at the moment, especially because validate()
transforms during validation.

=cut
# XXX make this traverse a data tree and transform everything
# XXX across.
# XXX Before hacking something here, think about factoring traversal out of
# XXX D::P::Validator
sub transform_data{
    my $self = shift;
    my $key  = shift;
    my $val  = shift;

    return Data::Processor::Transformer->new()->transform($key, $val);
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

Write descriptive pod from the schema.

 my $pod_string = $processor->make_pod();

=cut
sub pod_write{
    my $self = shift;
    return Data::Processor::PodWriter::pod_write(
        $self->{schema},
        "=head1 Schema Description\n\n"
    );
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

