/*
Denormalization Lab SQL to set up tables and "migrated" attributes.

This is the parent table for this lab.  We could have created a parent above this that
captured information about the college, such as the name of the Dean, the location of
the Dean's office, ... but I chose to start at this point in that chain.
*/

drop table department;
drop table course;
-- drop table section;

create table department (
    college     varchar (50) not null,
    deptname    varchar (50) not null,				# unique name of the department
    chair       varchar (50) not null,				# Full name of dept chair
    officeBldg  varchar (10) not null,				# varchar(3) might be enough
    officeNo    integer      not null,
    constraint department_pk primary key (deptname));	# I believe dept names unique across campus

/*
This is a few representative departments within CSULB.  I have two colleges represented here.
Do not let this list stunt your creativity.  If you have other departments/colleges that you
want to work with, by all means, insert them here as well.

Note that we can insert several records at a shot with one statement with this form of the
insert.  Good news is it's less typing.  Bad news is, they either all go in at once, or none
of these rows goes in.
*/
insert into department (college, deptname, chair, officeBldg, officeNo)
    values  ('Engineering', 'Chemical Engineering', 'Roger Lo', 'EN2', 100),
            ('Engineering', 'Computer Engineering Computer Science', 'Mehrdad Aliasgari', 'ECS', 542),
            ('Liberal Arts', 'English', 'Eileen Klink', 'MHB', 419);

/*
Within each department, there are many courses.  Just about every deparment has a 100 course
that is the intro to that department's area of study.  So clearly, the course number is not
unique.  But the combination of department name and course number is unique.  So, the relationship
from department to course is identifying, of course.
*/
create table course (
    departmentName  varchar(50)     not null,				# Notice that it gets a new name
    courseName      varchar(50)     not null,
    courseNumber    integer         not null,
    description     varchar(2000)   not null,				# Never put this into the key
    units           int             not null,
    constraint      course_department_01 foreign key (departmentName)	# We role named name in department
                    references department (deptname),
    constraint      course_pk primary key (departmentName, courseNumber),
    constraint      course_uk_01 unique (departmentName, courseName));	# This is a candidate key

select * from department;

insert into course (departmentName, courseName, courseNumber, description, units)
    values  ('Computer Engineering Computer Science', 'The Digital Information Age',
                202, 'The introduction and use of common-place digital and
                      electronic devices and how this technology affects our society.
                      Topics include advances in 3D imaging, 3D printing,
                      Processors, Memory, Security and Privacy.', 3),
            ('Computer Engineering Computer Science', 'Database Fundamentals',
                323, 'Fundamental topics on database management. Topics include
                      entity-relationship models, database design, data definition
                      language, the relational model, data manipulation language,
                      database application programming and normalization.', 3),
            ('English', 'Introduction to Creative Writing: Fiction',
                205,  'Practice in the basic elements of fiction writing: character
                       sketch, plot development, description, and dialog.', 3);

-- Let's look at the data
select	dept.deptname , dept.chair, c.courseName, c.courseNumber, c.units
from	department dept inner join course c on dept.deptname = c.DEPARTMENTNAME
order by dept.deptname, c.courseNumber;

ALTER TABLE course ADD COLUMN chair varchar (50) not null;

/*
    Create an on insert trigger in Course that will copy the value of the department chair from
    Department into Course.
*/
DELIMITER //
CREATE TRIGGER add_chair_to_dept
    BEFORE INSERT ON course FOR EACH ROW
BEGIN
        SET NEW.chair = (SELECT chair from department where deptname = NEW.departmentName);
END //
DELIMITER ;

/* TESTING */
insert into course (departmentName, courseName, courseNumber, description, units)
    values  ('Computer Engineering Computer Science', 'Principles of Programming Languages',
                342, 'We will study the how''s and why''s of programming language design and
                      implementation to a much greater level of detail than is possible in lower-level
                      courses. We will cover essential programming language concepts like binding time,
                      type systems, abstraction mechanisms, reNlection, recursion, memory management,
                      lambda calculus, and message passing. We will also contrast different language paradigms
                      (procedural, object-oriented, functional, logic, concurrent) and complete programming
                      assignments in each. Particular emphasis will be placed on the functional programming paradigm,
                      and its concerns of higher-order functions and immutable state.', 3);
SELECT * FROM course;
/*
    Create an on-update trigger in Department that will update all of the courses in that
    department if the chair gets changed at the department level.
*/
DELIMITER //
CREATE TRIGGER before_update_dept
    BEFORE UPDATE ON department FOR EACH ROW
BEGIN
        IF NEW.deptname <> OLD.deptname OR NEW.chair <> OLD.chair THEN
            UPDATE course
                SET chair = NEW.chair
                WHERE departmentName = NEW.deptname;
        END IF;
END //
DELIMITER ;
/*
  DELETE FROM course where departmentName = 'English';
 */

SELECT * FROM department;
/*
DELETE FROM department where deptname = 'Chemical Engineering' OR deptname = 'Computer Engineering Computer Science' OR deptname = 'English' ;
 */

/*
   TESTING consistence on update department
 */
select	departmentName, chair, courseName, courseNumber from course order by courseName;
update	department
set		chair='Mehrdad Aliasgari'
where	deptname = 'Computer Engineering Computer Science';

/*
Write an on-update trigger in Course that will make sure that you cannot change the value
of the chair from within Course.
*/
/*
   This on-update trigger in course will be executed before the before_update_dept trigger which is why we are not being able
   update the chair in department table because that event involves the success, passing the check , of this trigger. I tried
   to find a way to manage the ordering of the triggers but the information I got is not good enough or it does not work. The
   first option was to use the FOLLOWS _triggerName_ or PRECEDES key works to manage the sequence. The second option was to use
   the settriggerorder indexing but I don't know if mysql understands that syntax :).

   Don't mind the above information I wrote. You showed me how to deal with this exception which is by using the SET whenever
   their is on-update event on course
 */
DELIMITER //
CREATE TRIGGER before_update_course
    BEFORE UPDATE ON course FOR EACH ROW
BEGIN
        IF NEW.chair <> old.chair THEN
           SET NEW.chair = (SELECT chair from department where deptname = NEW.departmentName);
        END IF;
END //
DELIMITER ;

/*
   TESTING update the chair from course
   the before_update_course will be invoked and overrides the chair we passed to the update with the chair
   from department table that has the given departmentName
*/
UPDATE course
SET chair = 'Berkhard Englert'
WHERE departmentName = 'Computer Engineering Computer Science';
/*
 Console Output: 
 cecs3232022springs05n32s> UPDATE course
                          SET chair = 'Berkhard Englert'
                          WHERE departmentName = 'Computer Engineering Computer Science'
[2022-04-22 11:50:48] 3 rows affected in 45 ms
 */
 
/*
    Create deptCourse table
 */
create table deptcourse
(
    college      varchar(50)   not null,
    deptname     varchar(50)   not null,
    chair        varchar(50)   not null,
    officeBldg   varchar(10)   not null,
    officeNo     int           not null,
    courseName   varchar(50)   not null,
    courseNumber int           not null,
    description  varchar(2000) not null,
    units        int           not null,
    primary key (deptname, courseNumber),
    constraint deptCourse_CK
        unique (deptname, courseName)
);


/*
Add an on insert trigger to the deptCourse table that checks to make sure that there are
no other rows in the table that disagree with the new row regarding any of the
department information.
*/
DELIMITER //
CREATE TRIGGER before_insert_deptCourse
    BEFORE INSERT ON deptcourse FOR EACH ROW
BEGIN
        IF NEW.chair <> (SELECT distinct (chair) from deptcourse where deptname = NEW.deptname) THEN
           SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, there are
           other rows in the table that disagree with the new row regarding the department chair.';
        END IF;
        IF NEW.deptname <> (SELECT distinct (deptname) from deptcourse where chair = NEW.chair) THEN
           SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, there are
           other rows in the table that disagree with the new row regarding the department name.';
        END IF;
        IF NEW.college <> (SELECT distinct (college) from deptcourse where  deptname = NEW.deptname AND chair = NEW.chair) THEN
           SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, there are
           other rows in the table that disagree with the new row regarding the department college.';
        END IF;
        IF NEW.officeBldg <> (SELECT distinct (officeBldg) from deptcourse where  deptname = NEW.deptname AND chair = NEW.chair) THEN
           SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, there are
           other rows in the table that disagree with the new row regarding the department officeBldg.';
        END IF;
        IF NEW.officeNo <> (SELECT distinct (officeNo) from deptcourse where deptname = NEW.deptname AND chair = NEW.chair) THEN
           SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, there are
           other rows in the table that disagree with the new row regarding the department officeNo.';
        END IF;

END //
DELIMITER ;
/*
TESTING insertion
What should happen? The second insertion should not got thru because the chair has different value
compare to the one we have in our record.
*/
insert into deptcourse (college, deptname, chair, officeBldg, officeNo, courseName, courseNumber, description, units)
    values  ('Engineering', 'Computer Engineering Computer Science', 'Mehrdad Aliasgari', 'ECS', 542,'The Digital Information Age',
                202, 'The introduction and use of common-place digital and
                      electronic devices and how this technology affects our society.
                      Topics include advances in 3D imaging, 3D printing,
                      Processors, Memory, Security and Privacy.', 3);

insert into deptcourse (college, deptname, chair, officeBldg, officeNo, courseName, courseNumber, description, units)
    values  ('Engineering', 'Computer Engineering Computer Science', 'Berkhard Englert', 'ECS', 542,'The Digital Information Age',
                202, 'The introduction and use of common-place digital and
                      electronic devices and how this technology affects our society.
                      Topics include advances in 3D imaging, 3D printing,
                      Processors, Memory, Security and Privacy.', 3);
/* Console Output: [45000][1644] Error, there are other rows in the table that disagree with the new row regarding the department chair */


/*
Add an on-update trigger to the deptCourse table that checks to make sure that no one
is able to change any of the departmental information such that there are any
discrepancies between courses within the same department.
 */

DELIMITER //
CREATE TRIGGER before_update_deptCourse
    BEFORE UPDATE ON deptcourse FOR EACH ROW
BEGIN
        IF NEW.college <> OLD.college OR NEW.chair <> OLD.chair
           OR NEW.deptname <> OLD.deptname OR NEW.officeBldg <> OLD.officeBldg
           OR NEW.officeNo <> OLD.officeNo THEN
           SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, You cannot change any of the departmental information for consistency purpose';
        END IF;
END //
DELIMITER ;

/*
 TESTING update
 This should not be allowed since we are not allowed to change any department information for consistency purpose
 before_update_deptCourse will be invoked during this operation and it should print out a message says there is no
 such privilege to update any department information
*/
UPDATE deptcourse
SET chair = 'Berkhard Englert'
WHERE deptname = 'Computer Engineering Computer Science' AND courseNumber = 202;

/*
    Console Output: [45000][1644] Error, You cannot change any of the departmental information for consistency purpose
 */
select * from deptcourse;
