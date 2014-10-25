package Test::Version;
use 5.006;
use strict;
use warnings;
BEGIN {
	our $VERSION = 'v1.1.0'; # VERSION
}
use parent 'Exporter';
use Env qw(TEST_VERSION_STRICTNESS);
use Test::Builder;
use version 0.86 qw( is_lax is_strict );
use File::Find::Rule::Perl;
use Module::Extract::VERSION;
use Test::More;

our @EXPORT = qw( version_all_ok ); ## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT_OK = qw( version_ok );

our $STRICTNESS = $TEST_VERSION_STRICTNESS ? $TEST_VERSION_STRICTNESS : 0;

my $test = Test::Builder->new;

sub _get_version {
	my $pm = shift;
	return my $version
		= Module::Extract::VERSION->parse_version_safely( $pm );
}

sub version_ok {
	my ( $file, $name ) = @_;
	$file ||= '';
	$name ||= "check version in '$file'";

	unless ( $file ) {
		$test->ok( 0, $name );
		$test->diag( "No file passed to version_ok()." );
		return 0;
	}

	unless ( -e $file ) {
		$test->ok( 0, $name );
		$test->diag( "'$file' doesn't exist." );
		return 0;
	}

	my $version = _get_version( $file );


	unless ( $version ) {
		$test->ok( 0 , $name );
		$test->diag( "No version was found in '$file'." );
		return 0;
	}

	unless ( is_lax( $version ) ) {
		$test->ok( 0, $name );
		$test->diag( "The version '$version' found in '$file' is invalid." );
		return 0;
	}

	unless ( is_strict( $version ) ) {
		if    ( $STRICTNESS == 0 ) {
			$test->ok( 1, $name );
		}
		elsif ( $STRICTNESS == 1 ) {
			$test->ok( 1, $name );
			$test->diag( "The version '$version' found in '$file' is not strict." );
		}
		elsif ( $STRICTNESS == 2 ) {
			$test->ok( 0, $name );
			$test->diag( "The version '$version' found in '$file' is not strict." );
		}
		return 1;
	}

	$test->ok( 1, $name );
	return 1;
}

sub version_all_ok {
	my ( $dir, $name ) = @_;

	$dir
		= defined $dir ? $dir
		: -d 'blib'    ? 'blib'
		:                'lib'
		;

	# Report failure location correctly - GH #1
	local $Test::Builder::Level = $Test::Builder::Level + 1; ## no critic (Variables::ProhibitPackageVars)

	$name ||= "all modules in $dir have valid versions";

	unless ( -d $dir ) {
		$test->ok( 0, $name );
		$test->diag( "$dir does not exist, or is not a directory" );
		return;
	}
	my @files = File::Find::Rule->perl_module->in( $dir );

	foreach my $file ( @files ) {
		version_ok( $file );
	}
	return;
}
1;

# ABSTRACT: Check to see that version's in modules are sane


__END__
=pod

=head1 NAME

Test::Version - Check to see that version's in modules are sane

=head1 VERSION

version v1.1.0

=head1 SYNOPSIS

	use Test::More;
	use Test::Version 0.04;

	# test blib or lib by default
	version_all_ok();

	done_testing;

=head1 DESCRIPTION

This module's goal is to be a one stop shop for checking to see that your
versions across your dist are sane. Please ensure that you use version C<0.04>
or later only, as earlier versions are old code and may not work correctly.
Current feature list:

=over

=item module has a version

Tests to insure that all modules checked have a VERSION defined, Can replace
L<Test::HasVersion>

=item module has a valid version

Tests to insure that all versions are valid, according to the rules of
L<version> method C<is_lax>. To quote:

I<The lax criteria corresponds to what is currently allowed by the version
parser. All of the following formats are acceptable for dotted-decimal formats
strings:>

	v1.2
	1.2345.6
	v1.23_4
	1.2345
	1.2345_01

I<If you want to limit yourself to a much more narrow definition of what a
version string constitutes, is_strict() is limited to version strings like the
following list:>

	v1.234.5
	2.3456

you can cause your tests to fail if not strict by setting L<STRICTNESS> to
C<2>

=back

=head1 METHODS

=over

=item C<version_ok( $filename, [ $name ] );>

Test a single C<.pm> file by passing a path to the function. Checks if the
module has a version, and that it is valid with C<is_lax>.

=item C<version_all_ok( [ $directory, [ $name ]] );>

Test all modules in a directory with C<version_ok>. By default it will check
C<blib> or C<lib> if you haven't passed it a directory.

=back

=head1 CONFIGURATION AND ENVIRONMENT

=head2 C<STRICTNESS>

this allows you to set how strict you want the version validity checking to
be. you can set either the package variable C<$Test::Version::STRICTNESS;>
or the environment variable C<TEST_VERSION_STRICTNESS>.

=over

=item * C<$Test::Version::STRICTNESS = 0; # default>

This will not disable strict checking, but will simply result in a
passing test even if the C<is_strict> fails.

=item * C<$Test::Version::STRICTNESS = 1;>

This will cause a diagnostic to print if your C<VERSION> is not
strict. The test will still continue to pass. I<This will be the default in
1.4.0.>

=item * C<$Test::Version::STRICTNESS = 2;>

This will cause the test to fail if your C<VERSION> is not C<is_strict>.

=back

=head1 LIMITATIONS

Will not test Perl 5.12 C<package> version declarations because
L<Module::Extract::VERSION> can't extract them yet.

=head1 SEE ALSO

The goal is to have the functionality of all of these.

=over

=item L<Test::HasVersion>

=item L<Test::ConsistentVersion>

=item L<Test::GreaterVersion>

=back

=head1 ACKNOWLEDGEMENTS

Special thanks to particle C<<particle at cpan dot org>> for the original
C<Test::Version> and letting me maintain it further. Thanks to Mike Doherty
C<<doherty at cs dot dal dot ca>>, and Michael G. Schwern C<<schwern at pobox dot
com>> for their patches.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/xenoterracide/Test-Version/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

