use strict;
use warnings;
use lib 'lib';
use Test::More;
use Data::Processor;


my $data = {
    some_key => 1,
};

my $schema = schema(Broken::Validator->new());

sub schema{
    my $validator_obj = shift;
    return {
        some_key => {
            validator   => $validator_obj,
            description => 'An object that knows how to validate our input',
        }
    };
}

eval { my $processor = Data::Processor->new($schema) };
ok ($@ =~ /validator object must implement method "validate/, $@);

$schema = schema(Good::Validator->new());
my $processor;
eval { $processor = Data::Processor->new($schema) };
ok (! $@);

my $error_collection = $processor->validate({some_key => 0});
my @errors = $error_collection->as_array();
ok (scalar(@errors)==1, '1 error found');
ok ($errors[0] =~ /The supplied value '0' was not 'true'/);

$error_collection = $processor->validate({some_key => 42});
@errors = $error_collection->as_array();
ok (scalar(@errors)==0, '0 error found');


# nested data
$schema = {
    top => {
        members => {
            %$schema
        }
    }
};

eval { $processor = Data::Processor->new($schema) };
ok (! $@);

$error_collection = $processor->validate({top => {some_key => 42}});
@errors = $error_collection->as_array();
ok (scalar(@errors)==0, '0 error found');


# optional tests if Types::Standard installed
eval ("use Types::Standard -all");
SKIP : {
    skip "'Types::Standard' not installed" if $@;

    use Types::Standard -all;
    $schema = {
        foo => {
            validator => ArrayRef[Int],
            description => 'an arrayref of integers'
        }
    };
    eval { $processor = Data::Processor->new($schema) };
    ok (! $@);

    $error_collection = $processor->validate({foo => [42, 32, 99, 'bla']});
    @errors = $error_collection->as_array();
    ok (scalar(@errors)==1, '1 error found: "bla" is not an Int');
    ok ($errors[0] =~ /Reference \[42,32,99,"bla"\] did not pass type constraint "ArrayRef\[Int\]"/);

    $error_collection = $processor->validate({foo => [42, 32, 99, 99.9]});
    @errors = $error_collection->as_array();
    ok (scalar(@errors)==1, '1 error found: "99.9" is not an Int');
    ok ($errors[0] =~ /Reference \[42,32,99,"99.9"] did not pass type constraint "ArrayRef\[Int\]"/);

    $error_collection = $processor->validate({foo => [42, 32, 99, 9827456893475926589]});
    ok ($error_collection->as_array == 0);
}

done_testing;

package Broken::Validator;
sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

# This validator misses a "validate" method;


package Good::Validator;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub validate{
    my $self = shift;
    my $val = shift;

    # Do interesting stuff, here.

    # We need to return undef if we successfully validated.
    return $val ? undef: "The supplied value '$val' was not 'true'";
}

1
