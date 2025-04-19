#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use MySystem::DB qw(get_dbh); # Use our helper

my $q = CGI->new;
print $q->header;

# --- Assume student_id is known (e.g., from session or passed param) ---
my $student_id = $q->param('student_id') || 1; # Example: Default to student 1

# --- HTML Header (Ideally from template) ---
print "<html><head><title>Course Catalog</title></head><body>";
print "<h1>Course Catalog</h1>";
# Add filter form here...

# --- Database Logic ---
my $dbh = get_dbh();
my $dept_filter = $q->param('dept_id');
my $avail_filter = $q->param('show_available');
my $semester_filter = $q->param('semester') || 'Fall 2024'; # Default semester

my $sql = "SELECT c.course_id, c.course_code, c.title, d.dept_name, c.semester, c.available_seats, c.total_seats
           FROM Courses c
           JOIN Departments d ON c.dept_id = d.dept_id
           WHERE c.semester = ?";
my @params = ($semester_filter);

if ($dept_filter && $dept_filter ne 'all') {
    $sql .= " AND c.dept_id = ?";
    push @params, $dept_filter;
}
if ($avail_filter) {
    $sql .= " AND c.available_seats > 0";
}
$sql .= " ORDER BY d.dept_name, c.course_code";

my $sth = $dbh->prepare($sql);
$sth->execute(@params);

# --- Display Results Table (Ideally from template) ---
print "<table border='1'><tr><th>Code</th><th>Title</th><th>Dept</th><th>Semester</th><th>Seats</th><th>Action</th></tr>";
while (my $row = $sth->fetchrow_hashref) {
    print "<tr>";
    print "<td>", $row->{course_code}, "</td>";
    print "<td>", $row->{title}, "</td>";
    print "<td>", $row->{dept_name}, "</td>";
    print "<td>", $row->{semester}, "</td>";
    print "<td>", $row->{available_seats}, " / ", $row->{total_seats}, "</td>";
    print "<td>";
    if ($row->{available_seats} > 0) {
        # Check if already enrolled (simple check, could be more efficient)
        my $sth_check = $dbh->prepare("SELECT COUNT(*) FROM Registrations WHERE student_id = ? AND course_id = ?");
        $sth_check->execute($student_id, $row->{course_id});
        my ($is_enrolled) = $sth_check->fetchrow_array();
        $sth_check->finish();

        if ($is_enrolled) {
             print "[Enrolled]";
        } else {
            print "<form action='enroll.cgi' method='post'>";
            print "<input type='hidden' name='course_id' value='", $row->{course_id}, "'>";
            print "<input type='hidden' name='student_id' value='$student_id'>"; # Insecure
            print "<button type='submit'>Enroll</button>";
            print "</form>";
        }
    } else {
        print "[Full]";
    }
    print "</td>";
    print "</tr>";
}
print "</table>";

$sth->finish();
$dbh->disconnect();

# --- HTML Footer ---
print "</body></html>";