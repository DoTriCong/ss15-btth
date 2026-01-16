drop database if exists StudentManagement;
create database StudentManagement;
use StudentManagement;

create table Students (
    StudentID char(5) primary key,
    FullName varchar(50) not null,
    TotalDebt decimal(10,2) default 0
);

create table Subjects (
    SubjectID char(5) primary key,
    SubjectName varchar(50) not null,
    Credits int check (Credits > 0)
);

create table Grades (
    StudentID char(5),
    SubjectID char(5),
    Score decimal(4,2) check (Score between 0 and 10),
	primary key (StudentID, SubjectID),
    foreign key (StudentID) references Students(StudentID),
    foreign key (SubjectID) references Subjects(SubjectID)
);

create table GradeLog (
    LogID int auto_increment primary key,
    StudentID char(5),
    OldScore decimal(4,2),
    NewScore decimal(4,2),
    ChangeDate datetime default current_timestamp
);

insert into Students (StudentID, FullName, TotalDebt ) values
('SV01', 'Nguyen Van A', 3000000),
('SV03', 'Tran Thi B', 0);

insert into Subjects (SubjectID, SubjectName, Credits) values
('MH01', 'Database Systems', 3),
('MH02', 'Java Programming', 4);

insert into Grades (StudentID, SubjectID, Score) values
('SV01', 'MH01', 3.5),
('SV03', 'MH02', 8.0);

-- PHẦN A – CƠ BẢN

-- CÂU 1: Trigger kiểm tra Score hợp lệ
drop trigger if exists tg_CheckScore;
DELIMITER //
create trigger tg_CheckScore
before insert on Grades
for each row
begin
    if new.Score < 0 then
        set new.Score = 0;
    elseif new.Score > 10 then
        set new.Score = 10;
    end if;
end //
delimiter ;

-- CÂU 2: Transaction thêm sinh viên mới
start transaction;

insert into Students (StudentID, FullName)
values ('SV02', 'Ha Bich Ngoc');

update Students
set TotalDebt = 5000000
where StudentID = 'SV02';
commit;

-- PHẦN B – KHÁ

-- CÂU 3: Trigger ghi log khi sửa điểm
drop trigger if exists tg_LogGradeUpdate;
delimiter //
create trigger tg_LogGradeUpdate
after update on Grades
for each row
begin
    if old.Score <> new.Score then
        insert into GradeLog (StudentID, OldScore, NewScore, ChangeDate)
        values (old.StudentID, old.Score, new.Score, now());
    end if;
end //
delimiter ;

-- cau 4: stored procedure dong hoc phi
drop procedure if exists sp_PayTuition;
delimiter //
create procedure sp_PayTuition()
begin
    declare v_newDebt decimal(10,2);

    start transaction;

    update Students
    set TotalDebt = TotalDebt - 2000000
    where StudentID = 'SV01';

    select TotalDebt into v_newDebt
    from Students
    where StudentID = 'SV01';

    if v_newDebt < 0 then
        rollback;
    else
        commit;
    end if;
end //
delimiter ;

-- phan c – gioi

-- cau 5: trigger chan sua diem neu da qua mon
drop trigger if exists tg_PreventPassUpdate;
delimiter //
create trigger tg_PreventPassUpdate
before update on Grades
for each row
begin
    if old.Score >= 4.0 then
        signal sqlstate '45000'
        set message_text = 'Khong duoc phep sua diem khi sinh vien da qua mon';
    end if;
end //
delimiter ;

-- cau 6: stored procedure xoa diem co transaction
drop procedure if exists sp_DeleteStudentGrade;
delimiter //
create procedure sp_DeleteStudentGrade(
    in p_StudentID char(5),
    in p_SubjectID char(5)
)
begin
    declare v_score decimal(4,2);

    start transaction;

    select Score into v_score
    from Grades
    where StudentID = p_StudentID
      and SubjectID = p_SubjectID;

    insert into GradeLog (StudentID, OldScore, NewScore, ChangeDate)
    values (p_StudentID, v_score, null, now());

    delete from Grades
    where StudentID = p_StudentID
      and SubjectID = p_SubjectID;

    if row_count() = 0 then
        rollback;
    else
        commit;
    end if;
end //
delimiter ;
