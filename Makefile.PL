use Inline::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteInlineMakefile(
    'NAME'		=> 'Text::Scan',
    'VERSION_FROM'	=> 'Scan.pm', # finds $VERSION
    'PREREQ_PM'		=> {Inline => 0.42}, # e.g., Module::Name => 1.1
);
