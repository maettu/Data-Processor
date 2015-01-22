use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $timespecfactor = {
    d => 24*3600,
    m => 60,
    s => 1,
    h => 3600
};

my $transformer = {
    timespec => sub {
        my $msg = shift;
        sub {
            if (shift =~ /^(\d+)([dmsh]?)$/){
                return ($1 * $timespecfactor->{($2 || 's')});
            }
            die {msg=>$msg};
        }
    }
};

my $schema = {
    history => {
        transformer => $transformer->{timespec}(
            'specify timeout in seconds or append d,m,h to the number'),
    },
};

my $data = {
    history => '1h',
};

my $validator = Data::Processor->new($schema);
my $error_collection = $validator->validate($data, verbose=>0);
ok ($data->{history} == 3600, 'transformed "1h" into "3600"');

$data = {
    history => 'regards, your error :-)',
};
$error_collection = $validator->validate($data);

ok ($data->{history} eq 'regards, your error :-)',
    'Could not transform "regards, your error :-)"');
ok ($error_collection->{errors}[0]->{message}
    =~ /^error transforming 'history': specify/,
    'error from failed transform starts with "error transforming \'history\': specify"');


done_testing;
