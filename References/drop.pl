#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use MySystem::DB qw(get_dbh);

my $q = CGI->new;
print $q->header;

my $student_id = $q->param('student_id');
my $reg_id = $q->param('reg_id'); # Use registration ID to drop
my $message = "";

if (!$student_id || !$reg_id) {
    $message = "Error: Missing student ID or registration ID.";
} else {
    my $dbh = get_dbh();
    $dbh->{AutoCommit} = 0; # Start transaction

    eval {
        # Optional: Get course_id before deleting for the trigger (if trigger needs it explicitly)
        # Or just let the DELETE trigger handle it based on reg_id.

        # Delete the registration. Trigger should handle incrementing seats.
        # Crucially, verify the registration belongs to the student making the request!
        my $sth = $dbh->prepare("DELETE FROM Registrations WHERE reg_id = ? AND student_id = ?");
        my $rows_affected = $sth->execute($reg_id, $student_id);
        $sth->finish();

        if ($rows_affected == 0) {
             die "Error: Registration not found or you do not have permission to drop this course.";
        }

        $dbh->commit();
        $message = "Successfully dropped course registration ID $reg_id.";

    }; # End eval

    if ($@) {
        my $error = $@;
        $dbh->rollback();
        $message = "Failed to drop course: $error";
        $message =~ s/ at .* line \d+\.//;
    }

    $dbh->{AutoCommit} = 1; # Restore default
    $dbh->disconnect();
}

# --- Display Result ---
print "<html><head><title>Drop Status</title></head><body>";
print "<h1>Drop Status</h1>";
print "<p>$message</p>";
print "<p><a href='my_enrollments.cgi?student_id=$student_id'>Back to My Enrollments</a></p>";
print "<p><a href='courses.cgi?student_id=$student_id'>Back to Course Catalog</a></p>";
print "</body></html>";