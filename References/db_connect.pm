# db_connect.pm
package MySystem::DB;

use strict;
use warnings;
use DBI;
use Exporter 'import';

our @EXPORT_OK = qw(get_dbh);

# Ideally, load from a config file
my $dsn = "DBI:mysql:database=course_reg;host=localhost";
my $db_user = "reg_user";
my $db_pass = "your_password"; # Use secure methods in production

sub get_dbh {
    my $dbh = DBI->connect($dsn, $db_user, $db_pass, {
        RaiseError => 1, # Die on errors
        PrintError => 0, # Don't print errors twice
        AutoCommit => 1, # Default to auto-commit, manage transactions manually
    }) or die "Database connection error: $DBI::errstr";
    return $dbh;
}

1;