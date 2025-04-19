use swhackathon25;
CREATE TABLE Student (
    studentId VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(50) NOT NULL,
    sem INT NOT NULL,
    coursesRegistered INT DEFAULT 0,
    password VARCHAR(255) NOT NULL
);
CREATE TABLE Admin (
    adminId VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    dept VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL
);

CREATE TABLE Courses (
    courseId VARCHAR(20) PRIMARY KEY,
    courseCode VARCHAR(10) NOT NULL,
    courseName VARCHAR(100) NOT NULL,
    dept VARCHAR(50) NOT NULL,
    sem INT NOT NULL,
    maxSeats INT NOT NULL,
    availableSeats INT NOT NULL,
    credits INT,
    adminId VARCHAR(20),
    FOREIGN KEY (adminId) REFERENCES Admin(adminId)
);

CREATE TABLE Registrations (
    studentId VARCHAR(20),
    courseId VARCHAR(20),
    registrationDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    isConfirmed BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (studentId, courseId),
    FOREIGN KEY (studentId) REFERENCES Student(studentId),
    FOREIGN KEY (courseId) REFERENCES Courses(courseId)
);

INSERT INTO Student (studentId, name, department, sem, coursesRegistered, password)
VALUES 
('BT23CSE024', 'Ananya Sharma', 'CSE', 4, 0, 'password123'),
('BT23EEE019', 'Rohan Mehra', 'EEE', 3, 0, 'securepass'),
('BT23ECE027', 'Neha Verma', 'ECE', 5, 0, 'myecepass'),
('BT24CME026', 'Aman Gupta', 'CME', 2, 0, 'passcme'),
('BT25MME046', 'Divya Nair', 'MME', 1, 0, 'mmepassword');

INSERT INTO Admin (adminId, name, dept, password)
VALUES 
('ADM001', 'Prof. Rakesh Kumar', 'CSE', 'adminpass1'),
('ADM002', 'Prof. Seema Yadav', 'EEE', 'adminpass2'),
('ADM003', 'Prof. Alok Mishra', 'ECE', 'adminpass3'),
('ADM004', 'Prof. Kavita Joshi', 'CME', 'adminpass4'),
('ADM005', 'Prof. Manish Gupta', 'MME', 'adminpass5');

select* from Student;
select* from Admin;

INSERT INTO Courses (courseId, courseCode, courseName, dept, sem, availableSeats, maxSeats, credits, adminId)
VALUES 
-- CSE Department
('CRS001', 'CS101', 'Introduction to Programming', 'CSE', 1, 60, 60, 4, 'ADM001'),
('CRS002', 'CS102', 'Data Structures', 'CSE', 1, 50, 50, 4, 'ADM001'),
('CRS003', 'CS201', 'Operating Systems', 'CSE', 4, 45, 45, 4, 'ADM001'),
('CRS004', 'CS202', 'Database Systems', 'CSE', 4, 40, 40, 4, 'ADM001'),

-- EEE Department
('CRS005', 'EE201', 'Electrical Machines', 'EEE', 3, 45, 45, 3, 'ADM002'),
('CRS006', 'EE202', 'Power Electronics', 'EEE', 3, 40, 40, 4, 'ADM002'),

-- ECE Department
('CRS007', 'EC301', 'Digital Communication', 'ECE', 5, 50, 50, 4, 'ADM003'),
('CRS008', 'EC302', 'Microprocessors & Microcontrollers', 'ECE', 5, 50, 50, 4, 'ADM003'),

-- CME Department
('CRS009', 'CM101', 'Engineering Mechanics', 'CME', 2, 55, 55, 4, 'ADM004'),
('CRS010', 'CM102', 'Engineering Thermodynamics', 'CME', 2, 55, 55, 4, 'ADM004'),

-- MME Department
('CRS011', 'MM101', 'Material Science Basics', 'MME', 1, 40, 40, 3, 'ADM005'),
('CRS012', 'MM102', 'Manufacturing Processes', 'MME', 1, 35, 35, 3, 'ADM005');

select * from courses;


