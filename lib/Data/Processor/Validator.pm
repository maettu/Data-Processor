use 5.10.1;
use strict;
use warnings;
package Data::Processor::Validator;
use Data::Processor::Error::Collection;

use Carp;

# XXX document this with pod. (if standalone)

# Data::Processor::Validator - Validate Data Against a Schema

sub new {
    my $class = shift;
    my %p     = @_;
    my $self = {
                             # XXX or can we? Assume nothing about schema..
        schema => $p{schema}  // croak ('cannot validate without "schema"'),
        data   => $p{data}    // croak ('cannot validate without "data"'),
        verbose=> $p{verbose} // undef,
        errors => $p{errors}  // Data::Processor::Error::Collection->new(),
        depth       => $p{depth} // 0,
        indent      => $p{indent} // 4,
        parent_keys => $p{parent_keys} // ['root'],

    };
    bless ($self, $class);
    return $self;
}

sub validate {
    my $self = shift;
    $self->{errors} = Data::Processor::Error::Collection->new();
    $self->_validate($self->{data}, $self->{schema}, 'root');
    return $self->{errors};
}

#################
# internal methods
#################
sub _validate {
    my $self = shift;
    # $(word)_section are *not* the data fields but the sections of the
    # config / schema the recursive algorithm is currently working on.
    # (Only) in the first call, these are identical.
    my $config_section = shift;
    my $schema_section = shift;

    $self->_add_defaults($config_section, $schema_section);

    for my $key (keys %{$config_section}){
        $self->explain (">>'$key'");

         # checks
        my $key_schema_to_descend_into =
            $self->__key_present_in_schema(
                $key, $config_section, $schema_section
            );

        $self->__value_is_valid(
            $key, $config_section, $schema_section
        );

        $self->__validator_returns_undef(
            $key, $config_section, $schema_section
        ) if exists $schema_section->{$key}
             and exists $schema_section->{$key}->{validator};

        # transformer
        if (exists $schema_section->{$key}
            and exists $schema_section->{$key}->{transformer}){

            my $return_value;
            eval {
                local $SIG{__DIE__};
                $return_value =
                    $schema_section->{$key}->{transformer}
                    ->($config_section->{$key},$config_section);

            };
            if (my $err = $@) {
                if (ref $err eq 'HASH' and $err->{msg}){
                    $err = $err->{msg};
                }
                $self->error("error transforming '$key': $err");
            }
            else {
                $config_section->{$key} = $return_value;
            }
        }

        my $descend_into;
        if (exists  $schema_section->{$key}
                and $schema_section->{$key}->{no_descend_into}
                and $schema_section->{$key}->{no_descend_into}){
            $self->explain (
                "skipping '$key' because schema explicitly says so.\n");
        }
        # skip config branch if schema key is empty.
        elsif (exists $schema_section->{$key}
                and ! %{$schema_section->{$key}}){
            $self->explain (
                "skipping '$key' because schema key is empty'");
        }
        elsif (exists $schema_section->{$key}
                and ! exists $schema_section->{$key}->{members}){
            $self->explain (
                "not descending into '$key'. No members specified\n"
            );
        }
        else{
            $descend_into = 1;
            $self->explain (">>descending into '$key'\n");
        }

        # recursion
        if ((ref $config_section->{$key} eq ref {})
                and $descend_into){
            $self->explain (">>'$key' is not a leaf and we descend into it\n");
            push @{$self->{parent_keys}}, $key;
            $self->{depth}++;
            $self->_validate(
                $config_section->{$key},
                $schema_section->{$key_schema_to_descend_into}->{members}
            );
            # to undo push before entering recursion.
            pop @{$self->{parent_keys}};
            $self->{depth}--;
        }
        elsif ((ref $config_section->{$key} eq ref []) && $descend_into
            && exists $schema_section->{$key_schema_to_descend_into}->{array}
            && $schema_section->{$key_schema_to_descend_into}->{array}){

            $self->explain(">>'$key' is an array reference so we check all elements\n");
            push @{$self->{parent_keys}}, $key;
            $self->{depth}++;
            for my $member (@{$config_section->{$key}}){
                $self->_validate(
                    $member,
                    $schema_section->{$key_schema_to_descend_into}->{members}
                );
            }
            pop @{$self->{parent_keys}};
            $self->{depth}--;
        }
        # Make sure that key in config is a leaf in schema.
        # We cannot descend into a non-existing branch in config
        # but it might be required by the schema.
        else {
            $self->explain(">>checking config key '$key' which is a leaf..");
            if ( $key_schema_to_descend_into
                    and
                 $schema_section->{$key_schema_to_descend_into}
                    and
                ref $schema_section->{$key_schema_to_descend_into} eq ref {}
                    and
                exists $schema_section->{$key_schema_to_descend_into}->{members}
            ){
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
    $self->_check_mandatory_keys(
        $config_section, $schema_section
    );

}

# add an error
sub error {
    my $self = shift;
    my $string = shift;
    my $msg_parent_keys = join '->', @{$self->{parent_keys}};
    my (undef, undef, $line) = caller(0);
    my (undef, undef, undef, $sub) = caller(1);
    $self->{errors}->add(
        message => $string,
        path => $msg_parent_keys,
        caller => "$sub line $line"
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
# a value (or, most oftenly, a key) in config, add the key and the
# default value.

sub _add_defaults{
    my $self           = shift;
    my $config_section = shift;
    my $schema_section = shift;

    for my $key (keys %{$schema_section}){
        next unless exists $schema_section->{$key}->{default};
        $config_section->{$key} = $schema_section->{$key}->{default}
            unless $config_section->{$key};
    }
}

# check mandatory: look for mandatory fields in all hashes 1 level
# below current level (in schema)
# for each check if $config has a key.
sub _check_mandatory_keys{
    my $self = shift;
    my $config_section = shift;
    my $schema_section = shift;

    for my $key (keys %{$schema_section}){
        $self->explain(">>Checking if '$key' is mandatory: ");
        unless (exists $schema_section->{$key}->{optional}
                   and $schema_section->{$key}->{optional}){

            $self->explain("true\n");
            next if exists $config_section->{$key};

            # regex-keys never directly occur.
            if (exists $schema_section->{$key}->{regex}
                   and $schema_section->{$key}->{regex}){
                $self->explain(">>regex enabled key found. ");
                $self->explain("Checking config keys.. ");
                my $c = 0;
                # look which keys match the regex
                for my $c_key (keys %{$config_section}){
                    $c++ if $c_key =~ /$key/;
                }
                $self->explain("$c matching occurencies found\n");
                next if $c > 0;
            }
            next if exists $schema_section->{$key}->{array}
                && $schema_section->{$key}->{array};


            # should only get here in case of error.

            my $error_msg = '';
            $error_msg = $schema_section->{$key}->{error_msg}
                if exists $schema_section->{$key}->{error_msg};
            $self->error("mandatory key '$key' missing. Error msg: '$error_msg'");
        }
        else{
            $self->explain("false\n");
        }
    }
}

# called by _validate to check if a given key is defined in schema
sub __key_present_in_schema{
    my $self = shift;
    my $key            = shift;
    my $config_section = shift;
    my $schema_section = shift;

    my $key_schema_to_descend_into;

    # direct match: exact declaration
    if (exists $schema_section->{$key}){
        $self->explain(" ok\n");
        $key_schema_to_descend_into = $key;
    }
    # match against a pattern
    else {
        my $match;
        for my $match_key (keys %{$schema_section}){

            # only try to match a key if it has the property
            # _regex_ set
            next unless exists $schema_section->{$match_key}
                    and exists $schema_section->{$match_key}->{regex}
                           and $schema_section->{$match_key}->{regex};

            if ($key =~ /$match_key/){
                $self->explain("'$key' matches $match_key\n");
                $key_schema_to_descend_into = $match_key;
            }
        }
    }

    # if $key_schema_to_descend_into is still undef we were unable to
    # match it against a key in the schema.
    unless ($key_schema_to_descend_into){
        $self->explain(">>$key not in schema, keys available: ");
        $self->explain(join (", ", (keys %{$schema_section})));
        $self->explain("\n");
        $self->error("key '$key' not found in schema\n");
    }
    return $key_schema_to_descend_into
}

# 'validator' specified gets this called to call the callback :-)
sub __validator_returns_undef {
    my $self = shift;
    my $key    = shift;
    my $config_section = shift;
    my $schema_section = shift;
    $self->explain("running validator for '$key': $config_section->{$key}\n");
    my $return_value = $schema_section->{$key}->{validator}->($config_section->{$key}, $config_section);
    if ($return_value){
        $self->explain("validator error: $return_value\n");
        $self->error("Execution of validator for '$key' returns with error: $return_value");
    }
    else {
        $self->explain("successful validation for key '$key'\n");
    }
}

# called by _validate to check if a value is in line with definitions
# in the schema.
sub __value_is_valid{
    my $self = shift;
    my $key    = shift;
    my $config_section = shift;
    my $schema_section = shift;

    if (exists  $schema_section->{$key}
            and $schema_section->{$key}->{value}){
        $self->explain('>>'.ref($schema_section->{$key}->{value})."\n");

        # currently, 2 type of restrictions are supported:
        # (callback) code and regex
        if (ref($schema_section->{$key}->{value}) eq 'CODE'){
            # possibly never implement this because of new "validator"
        }
        elsif (ref($schema_section->{$key}->{value}) eq 'Regexp'){
            $self->explain(">>match '$config_section->{$key}' against '$schema_section->{$key}->{value}'");

            if ($config_section->{$key} =~ m/^$schema_section->{$key}->{value}$/){
                $self->explain(" ok.\n");
            }
            else{
                # XXX never reach this?
                $self->explain(" no.\n");
                $self->error("$config_section->{$key} does not match ^$schema_section->{$key}->{value}\$");
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

