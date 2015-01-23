use 5.10.1;
use strict;
use warnings;
package Data::Processor::Validator;
use Data::Processor::Error::Collection;
use Data::Processor::Transformer;

use Carp;

# XXX document this with pod. (if standalone)

# Data::Processor::Validator - Validate Data Against a Schema

sub new {
    my $class = shift;
    my %p     = @_;
    my $self = {
        schema => $p{schema}  // croak ('cannot validate without "schema"'),
        data   => $p{data}    // croak ('cannot validate without "data"'),
        verbose=> $p{verbose} // undef,
        errors => $p{errors}  // Data::Processor::Error::Collection->new(),
        depth       => $p{depth} // 0,
        indent      => $p{indent} // 4,
        parent_keys => $p{parent_keys} // ['root'],
        transformer => Data::Processor::Transformer->new(),

    };
    bless ($self, $class);
    return $self;
}

sub validate {
    my $self = shift;
    $self->{errors} = Data::Processor::Error::Collection->new();
    $self->_validate({data => $self->{data}, schema => $self->{schema}});

    return $self->{errors};
}

#################
# internal methods
#################
sub _validate {
    my $self = shift;
    # current sections of data and schema
    my $section = shift;
#~     use Data::Dumper;say Dumper $section;
    my %section = %{$section};
    die unless ($section{data} and $section{schema});

    $self->_add_defaults(%section);

    for my $key (keys %{$section{data}}){
        $self->explain (">>'$key'");

        # checks
        my $schema_key =
            $self->_schema_twin_key($key, %section) or next;
        # from here we know to have a "twin" key $schema_key in the schema

        $self->__value_is_valid( $key, %section );

        $self->__validator_returns_undef($key, $schema_key, %section);

        # transformer
        my $e = $self->{transformer}->transform($key, %section);
        $self->error($e) if $e;

        # skip if explicitly asked for
        if ($section{schema}->{$schema_key}->{no_descend_into}){
            $self->explain (
                "skipping '$key' because schema explicitly says so.\n");
            next;
        }
        # skip data branch if schema key is empty.
        if (! %{$section{schema}->{$schema_key}}){
            $self->explain ("skipping '$key' because schema key is empty'");
            next;
        }
        if (! $section{schema}->{$schema_key}->{members}){
            $self->explain (
                "not descending into '$key'. No members specified\n"
            );
            next;
        }

        # recursion if we reach this point.
        $self->explain (">>descending into '$key'\n");

        if (ref $section{data}->{$key} eq ref {} ){
            $self->explain
                (">>'$key' is not a leaf and we descend into it\n");
            push @{$self->{parent_keys}}, $key;
            $self->{depth}++;
            $self->_validate(
                {data => $section{data}->{$key},
                schema => $section{schema}->{$schema_key}->{members}}
            );
            pop @{$self->{parent_keys}};
            $self->{depth}--;

#~             my @pk = @{$self->{parent_keys}};
#~             push @pk, $key;
#~             my $e = Data::Processor::Validator->new(
#~                 $section{schema}->{$schema_key}->{members}
#~             )
#~                 ->_validate($section{data}->{$key},
#~                     parent_keys => \@pk,
#~                     depth => $self->{depth}+1,
#~                     verbose => $self->{verbose}
#~                 );
        }
        elsif ((ref $section{data}->{$key} eq ref [])
            && $section{schema}->{$schema_key}->{array}){

            $self->explain(
            ">>'$key' is an array reference so we check all elements\n");
            push @{$self->{parent_keys}}, $key;
            $self->{depth}++;
            for my $member (@{$section{data}->{$key}}){
                $self->_validate(
                    {data => $member,
                    schema => $section{schema}->{$schema_key}->{members}}
                );
            }
            pop @{$self->{parent_keys}};
            $self->{depth}--;
        }
        # Make sure that key in data is a leaf in schema.
        # We cannot descend into a non-existing branch in data
        # but it might be required by the schema.
        else {
            $self->explain(">>checking data key '$key' which is a leaf..");
            if ($section{schema}->{$schema_key}->{members}){
                $self->explain("but schema requires members.\n");
                $self->error("'$key' should have members");
            }
            else {
                $self->explain("schema key is also a leaf. ok.\n");
            }
        }
    }
    # look for missing non-optional keys in schema
    # this is only done on this level.
    # Otherwise "mandatory" inherited "upwards".
    $self->_check_mandatory_keys( %section );
}

# add an error
sub error {
    my $self = shift;
    my $string = shift;
    $self->{errors}->add(
        message => $string,
        path => $self->{parent_keys},
    );
}

# explains what we are doing.
sub explain {
    my $self = shift;
    my $string = shift;
    my $indent = ' ' x ($self->{depth}*$self->{indent});
    $string =~ s/>>/$indent/;
    print $string if $self->{verbose};
}


# add defaults. Go over all keys *on that level* and if there is not
# a value (or, most oftenly, a key) in data, add the key and the
# default value.

sub _add_defaults{
    my $self           = shift;
    my %section = @_;

    for my $key (keys %{$section{schema}}){
        next unless $section{schema}->{$key}->{default};
        $section{data}->{$key} = $section{schema}->{$key}->{default}
            unless $section{data}->{$key};
    }
}

# check mandatory: look for mandatory fields in all hashes 1 level
# below current level (in schema)
# for each check if $data has a key.
sub _check_mandatory_keys{
    my $self    = shift;
    my %section = @_;

    for my $key (keys %{$section{schema}}){
        $self->explain(">>Checking if '$key' is mandatory: ");
        unless ($section{schema}->{$key}->{optional}
                   and $section{schema}->{$key}->{optional}){

            $self->explain("true\n");
            next if $section{data}->{$key};

            # regex-keys never directly occur.
            if ($section{schema}->{$key}->{regex}){
                $self->explain(">>regex enabled key found. ");
                $self->explain("Checking data keys.. ");
                my $c = 0;
                # look which keys match the regex
                for my $c_key (keys %{$section{data}}){
                    $c++ if $c_key =~ /$key/;
                }
                $self->explain("$c matching occurencies found\n");
                next if $c > 0;
            }
            next if $section{schema}->{$key}->{array};


            # should only get here in case of error.

            my $error_msg = '';
            $error_msg = $section{schema}->{$key}->{error_msg}
                if $section{schema}->{$key}->{error_msg};
            $self->error("mandatory key '$key' missing. Error msg: '$error_msg'");
        }
        else{
            $self->explain("false\n");
        }
    }
}

# called by _validate to check if a given key is defined in schema
sub _schema_twin_key{
    my $self    = shift;
    my $key     = shift;
    my %section = @_;

    my $schema_key;

    # direct match: exact declaration
    if ($section{schema}->{$key}){
        $self->explain(" ok\n");
        $schema_key = $key;
    }
    # match against a pattern
    else {
        my $match;
        for my $match_key (keys %{$section{schema}}){

            # only try to match a key if it has the property
            # _regex_ set
            next unless exists $section{schema}->{$match_key}
                           and $section{schema}->{$match_key}->{regex};

            if ($key =~ /$match_key/){
                $self->explain("'$key' matches $match_key\n");
                $schema_key = $match_key;
            }
        }
    }

    # if $schema_key is still undef we were unable to
    # match it against a key in the schema.
    unless ($schema_key){
        $self->explain(">>$key not in schema, keys available: ");
        $self->explain(join (", ", (keys %{$section{schema}})));
        $self->explain("\n");
        $self->error("key '$key' not found in schema\n");
    }
    return $schema_key
}

# 'validator' specified gets this called to call the callback :-)
sub __validator_returns_undef {
    my $self       = shift;
    my $key        = shift;
    my $schema_key = shift;
    my %section    = @_;
    return unless $section{schema}->{$schema_key}->{validator};
    $self->explain("running validator for '$key': $section{data}->{$key}\n");

    if (ref $section{data}->{$key} eq ref []
        && $section{schema}->{$key}->{array}){

        my $counter = 0;
        for my $elem (@{$section{data}->{$key}}){
            my $return_value = $section{schema}->{$key}->{validator}->($elem, $section{data});
            if ($return_value){
                $self->explain("validator error: $return_value (element $counter)\n");
                $self->error("Execution of validator for '$key' element $counter returns with error: $return_value");
            }
            else {
                $self->explain("successful validation for key '$key' element $counter\n");
            }
            $counter++;
        }
    }
    else {
        my $return_value = $section{schema}->{$key}->{validator}->($section{data}->{$key}, $section{data});
        if ($return_value){
            $self->explain("validator error: $return_value\n");
            $self->error("Execution of validator for '$key' returns with error: $return_value");
        }
        else {
            $self->explain("successful validation for key '$key'\n");
        }
    }
}

# called by _validate to check if a value is in line with definitions
# in the schema.
sub __value_is_valid{
    my $self    = shift;
    my $key     = shift;
    my %section = @_;

    if (exists  $section{schema}->{$key}
            and $section{schema}->{$key}->{value}){
        $self->explain('>>'.ref($section{schema}->{$key}->{value})."\n");

        # currently, 2 type of restrictions are supported:
        # (callback) code and regex
        if (ref($section{schema}->{$key}->{value}) eq 'CODE'){
            # possibly never implement this because of new "validator"
        }
        elsif (ref($section{schema}->{$key}->{value}) eq 'Regexp'){
            if (ref $section{data}->{$key} eq ref []
                && $section{schema}->{$key}->{array}){

                for my $elem (@{$section{data}->{$key}}){
                    $self->explain(">>match '$elem' against '$section{schema}->{$key}->{value}'");

                    if ($elem =~ m/^$section{schema}->{$key}->{value}$/){
                        $self->explain(" ok.\n");
                    }
                    else{
                        # XXX never reach this?
                        $self->explain(" no.\n");
                        $self->error("$elem does not match ^$section{schema}->{$key}->{value}\$");
                    }
                }
            }
            # XXX this was introduced to support arrays.
            else {
               $self->explain(">>match '$section{data}->{$key}' against '$section{schema}->{$key}->{value}'");

                if ($section{data}->{$key} =~ m/^$section{schema}->{$key}->{value}$/){
                    $self->explain(" ok.\n");
                }
                else{
                    # XXX never reach this?
                    $self->explain(" no.\n");
                    $self->error("$section{data}->{$key} does not match ^$section{schema}->{$key}->{value}\$");
                }
            }
        }
        else{
            # XXX match literally? How much sense does this make?!
            # also, this is not tested

            $self->explain("neither CODE nor Regexp\n");
            $self->error("'$key' not CODE nor Regexp");
        }

    }
}

1;

