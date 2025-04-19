#!/usr/bin/perl
# admin.cgi - Handles viewing, adding, editing, deleting courses
use strict;
use warnings;
use CGI;
use MySystem::DB qw(get_dbh);

my $q = CGI->new;
print $q->header;

# --- Authentication Check (Crucial!) ---
# Implement proper admin login/session check here.
# For now, assume user is admin.

my $action = $q->param('action') || 'list'; # Default action

my $dbh = get_dbh();

print "<html><head><title>Admin - Manage Courses</title></head><body>";
print "<h1>Admin - Manage Courses</h1>";

if ($action eq 'list') {
    # Display list of courses with Edit/Delete links (similar to course_search.cgi)
    # Include an "Add New Course" button linking to admin.cgi?action=add_form
    print "<p><a href='admin.cgi?action=add_form'>Add New Course</a></p>";
    # ... code to list courses ...
     my $sql = "SELECT c.*, d.dept_name FROM Courses c JOIN Departments d ON c.dept_id = d.dept_id ORDER BY c.course_code";
     my $sth = $dbh->prepare($sql);
     $sth->execute();
     print "<table border='1'><tr><th>ID</th><th>Code</th><th>Title</th><th>Dept</th><th>Semester</th><th>Seats (Avail/Total)</th><th>Actions</th></tr>";
     while (my $row = $sth->fetchrow_hashref) {
        print "<tr>";
        print "<td>$row->{course_id}</td>";
        print "<td>$row->{course_code}</td>";
        print "<td>$row->{title}</td>";
        print "<td>$row->{dept_name}</td>";
        print "<td>$row->{semester}</td>";
        print "<td>$row->{available_seats} / $row->{total_seats}</td>";
        print "<td>";
        print "<a href='admin.cgi?action=edit_form&course_id=$row->{course_id}'>Edit</a> ";
        # Add check before allowing delete if students are enrolled
        my $sth_check = $dbh->prepare("SELECT COUNT(*) FROM Registrations WHERE course_id = ?");
        $sth_check->execute($row->{course_id});
        my ($count) = $sth_check->fetchrow_array();
        $sth_check->finish();
        if ($count == 0) {
             print "<a href='admin.cgi?action=delete&course_id=$row->{course_id}' onclick='return confirm(\"Are you sure?\")'>Delete</a>";
        } else {
             print "[Delete Disabled - Enrolled]";
        }
        print "</td>";
        print "</tr>";
     }
     print "</table>";
     $sth->finish();

} elsif ($action eq 'add_form' || $action eq 'edit_form') {
    my $course = {};
    my $form_action = 'save_new';
    if ($action eq 'edit_form') {
        my $course_id = $q->param('course_id');
        die "Missing course_id for edit" unless $course_id;
        my $sth = $dbh->prepare("SELECT * FROM Courses WHERE course_id = ?");
        $sth->execute($course_id);
        $course = $sth->fetchrow_hashref;
        $sth->finish();
        die "Course not found" unless $course;
        $form_action = 'save_edit';
    }
    # Display HTML form for adding/editing course details
    # Pre-fill form if $course has data (editing)
    # Populate department dropdown from Departments table
    # Submit form to admin.cgi with action=save_new or action=save_edit
    print "<form action='admin.cgi' method='post'>";
    print "<input type='hidden' name='action' value='$form_action'>";
    if ($action eq 'edit_form') {
        print "<input type='hidden' name='course_id' value='", $q->param('course_id'), "'>";
    }
    print "Course Code: <input type='text' name='course_code' value='", ($course->{course_code} // ''), "'><br>";
    print "Title: <input type='text' name='title' size='50' value='", ($course->{title} // ''), "'><br>";
    # ... other fields: description, department dropdown, semester, total_seats ...
    print "Total Seats: <input type='number' name='total_seats' value='", ($course->{total_seats} // ''), "'><br>";
    print "<button type='submit'>Save Course</button>";
    print "</form>";


} elsif ($action eq 'save_new' || $action eq 'save_edit') {
    # Get form parameters
    my $course_code = $q->param('course_code');
    my $title = $q->param('title');
    my $total_seats = $q->param('total_seats');
    # ... get other params (dept_id, semester, description) ...

    # --- Input Validation ---
    my $message = "";
    if (!$course_code || !$title || !$total_seats) { # Add other required fields
        $message = "Error: Missing required fields.";
    } else {
        eval {
            if ($action eq 'save_new') {
                # INSERT new course. Set available_seats = total_seats initially.
                 my $sql = "INSERT INTO Courses (course_code, title, total_seats, available_seats, dept_id, semester, description) VALUES (?, ?, ?, ?, ?, ?, ?)";
                 my $sth = $dbh->prepare($sql);
                 # Assume dept_id=1, semester='Fall 2024', desc='' for brevity
                 $sth->execute($course_code, $title, $total_seats, $total_seats, 1, 'Fall 2024', '');
                 $message = "Course added successfully.";
            } else { # save_edit
                my $course_id = $q->param('course_id');
                die "Missing course_id for update" unless $course_id;
                # UPDATE existing course. Be careful updating available_seats if it's derived.
                # Maybe only allow total_seats update, recalculate available based on registrations?
                # Simpler: Update total_seats, maybe adjust available? Needs careful thought.
                # Safest: Update descriptive fields, maybe total_seats (if no one is enrolled beyond new limit).
                my $sql = "UPDATE Courses SET course_code = ?, title = ?, total_seats = ? WHERE course_id = ?";
                my $sth = $dbh->prepare($sql);
                 # Need logic here if total_seats is reduced below current enrollment! Prevent or handle.
                 # For now, just update:
                $sth->execute($course_code, $title, $total_seats, $course_id);
                $message = "Course updated successfully.";
            }
        };
        if ($@) {
             $message = "Database error: $@";
        }
    }
     print "<p>$message</p>";
     print "<p><a href='admin.cgi?action=list'>Back to Course List</a></p>";


} elsif ($action eq 'delete') {
    my $course_id = $q->param('course_id');
    my $message = "";
    if (!$course_id) {
        $message = "Error: Missing course ID for deletion.";
    } else {
         eval {
             # Double-check no students are enrolled before deleting
             my $sth_check = $dbh->prepare("SELECT COUNT(*) FROM Registrations WHERE course_id = ?");
             $sth_check->execute($course_id);
             my ($count) = $sth_check->fetchrow_array();
             $sth_check->finish();

             if ($count > 0) {
                 die "Cannot delete course: Students are currently enrolled.";
             }

             my $sth = $dbh->prepare("DELETE FROM Courses WHERE course_id = ?");
             my $rows = $sth->execute($course_id);
             if ($rows > 0) {
                 $message = "Course deleted successfully.";
             } else {
                 $message = "Error: Course not found or could not be deleted.";
             }
         };
         if ($@) {
             $message = "Error: $@";
             $message =~ s/ at .* line \d+\.//;
         }
    }
    print "<p>$message</p>";
    print "<p><a href='admin.cgi?action=list'>Back to Course List</a></p>";
}

$dbh->disconnect();
print "</body></html>";