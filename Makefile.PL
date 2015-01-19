use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Data::Structure::Validation',
  VERSION_FROM => 'lib/Data/Structure/Validation.pm',
  ABSTRACT     => 'validate a data structure against a schema',
  AUTHOR       => 'Matthias Bloch <matthias.bloch@puffin.ch>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/maettu/Data-Structure-Validation',
      bugtracker  => 'https://github.com/maettu/Data-Structure-Validation/issues'
    },
    no_index => {directory => ['t']}
  },
  test => {TESTS => 't/*.t'}
);
