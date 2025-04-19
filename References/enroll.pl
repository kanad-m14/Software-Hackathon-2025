#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use MySystem::DB qw(get_dbh);

my $q = CGI->new;
print $q->header;

my $student_id = $q->param('student_id');
my $course_id = $q->param('course_id');
my $message = "";

if (!$student_id || !$course_id) {
    $message = "Error: Missing student ID or course ID.";
} else {
    my $dbh = get_dbh();
    $dbh->{AutoCommit} = 0; # Start transaction

    eval {
        # 1. Check if already enrolled
        my $sth_check_reg = $dbh->prepare("SELECT COUNT(*) FROM Registrations WHERE student_id = ? AND course_id = ?");
        $sth_check_reg->execute($student_id, $course_id);
        my ($is_enrolled) = $sth_check_reg->fetchrow_array();
        $sth_check_reg->finish();

        if ($is_enrolled) {
            die "Error: You are already enrolled in this course.";
        }

        # 2. Check seat availability (lock the row for update)
        my $sth_check_seats = $dbh->prepare("SELECT available_seats FROM Courses WHERE course_id = ? FOR UPDATE");
        $sth_check_seats->execute($course_id);
        my ($available_seats) = $sth_check_seats->fetchrow_array();
        $sth_check_seats->finish();

        if (!defined $available_seats) {
             die "Error: Course not found.";
        }
        if ($available_seats <= 0) {
            die "Error: Course is full. No seats available.";
        }

        # 3. Enroll the student (Trigger will handle seat decrement)
        my $sth_insert = $dbh->prepare("INSERT INTO Registrations (student_id, course_id, date_registered) VALUES (?, ?, NOW())");
        $sth_insert->execute($student_id, $course_id);
        $sth_insert->finish();

        # If we reach here, all is well
        $dbh->commit();
        $message = "Successfully enrolled in course ID $course_id!";

        # Optional: Generate Confirmation Summary (See Sample Output section)
        # ... query current schedule ...
        # message .= generate_confirmation_summary($dbh, $student_id);


    }; # End eval

    if ($@) { # An error occurred
        my $error = $@;
        $dbh->rollback();
        $message = "Registration failed: $error";
        # Clean up error message if needed
        $message =~ s/ at .* line \d+\.//;
    }

    $dbh->{AutoCommit} = 1; # Restore default
    $dbh->disconnect();
}

# --- Display Result (Redirect or show message) ---
print "<html><head><title>Enrollment Status</title></head><body>";
print "<h1>Enrollment Status</h1>";
print "<p>$message</p>";
print "<p><a href='courses.cgi?student_id=$student_id'>Back to Course Catalog</a></p>"; # Pass ID back
print "<p><a href='my_enrollments.cgi?student_id=$student_id'>View My Enrollments</a></p>";
print "</body></html>";

# Optional sub to generate summary
# sub generate_confirmation_summary {
#    my ($dbh, $student_id) = @_;
#    # ... Query Registrations JOIN Courses for student_id ...
#    # ... Format as HTML list ...
#    return $html_summary;
# }