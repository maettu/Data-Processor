use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $processor_without_schema = Data::Processor->new();

eval{$processor_without_schema->validate()};
chomp $@;
ok ($@ =~ /^cannot validate without "schema"/, $@);

my $schema = schema();
eval{$processor_without_schema->validate(schema=>$schema)};
chomp $@;
ok ($@ =~ /^cannot validate without "data"/, $@);

my $processor = Data::Processor->new(schema => $schema);
eval{$processor->validate()};
chomp $@;
ok ($@ =~ /^cannot validate without "data"/, $@);

my $data = data();
my @errors = $processor->validate(data=>$data);
ok (scalar(@errors)==2, '2 errors found');


done_testing;

sub data {
    return {
        GENERAL => {
            logfile => '/tmp/n3k-poller.log',
            cachedb => '/tmp/n3k-cache.db',
            history => '3d',
            silos   => {
                'silo-a' => {
                    url => 'https://silo-a/api',
                    key => 'my-secret-shared-key',
                }
            }

        }
    }
}

sub schema {
    return {
        GENERAL => {
            description => 'general settings',
            error_msg   => 'Section GENERAL missing',
            members => {
                logfile => {
                    value       => qr{/.*},
                    # or a coderef: value => sub{return 1},
                    description => 'absolute path to logfile',
                },
                cachedb => {
                    value => qr{/.*},
                    description => 'absolute path to cache (sqlite) database file',
                },
                history => {
                },
                silos => {
                    description => 'silos store collected data',
                    # "members" stands for all "non-internal" fields
                    members => {
                        'silo-.+' => {
                            regex => 1,
                            members => {
                                url => {
                                    value       => qr{https.*},
                                    example     => 'https://silo-a/api',
                                    description => 'url of the silo server. Only https:// allowed',
                                },
                                key => {
                                    description => 'shared secret to identify node'
                                },
                                not_existing => {
                                }
                            }
                        }
                    }
                }
            }
        },
        NOT_THERE => {
            error_msg => 'We shall not proceed without a section that is NOT_THERE',
        }
    }
}

