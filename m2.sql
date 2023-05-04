CREATE DATABASE M2
GO
--2.2(a)
CREATE view allAssocManagers AS 
SELECT SAM.username ,SU.password,SAM.name
FROM Syst_User SU INNER JOIN Sports_Association_Manager SAM ON SU.username = SAM.username
GO
--2.2(b)
CREATE view allClubRepresentatives AS
SELECT SU.username, SU.password , CR.name, C.name AS Club_name
FROM Syst_User SU INNER JOIN Club_Representative CR ON SU.username=CR.username 
     INNER JOIN Club C on C.club_ID = CR.club_ID
GO
--2.3(xvi)
CREATE FUNCTION [allUnassignedMatches]
(@club_name varchar(20))
RETURNS TABLE
AS
RETURN (select GC.name as guest_Club_name ,M.start_time 
from Match M inner join Club HC on M.host_club_ID=HC.lub_ID 
inner Join Club GC on GC.club_ID = M.guest_club_ID 
where HC.name=@club_name and M.stadium_ID is Null)
 GO
 --2.3(ii)
 CREATE PROC addNewMatch 
 @host_club VARCHAR(20),@guest_club VARCHAR(20),@start DATETIME ,@end DATETIME
 AS
 declare @hostID int 
 declare @guestID int 
 SELECT @hostID=club_ID from Club where name=@host_club
 SELECT @guestID=club_ID from Club where name=@guest_club
 insert into Match (start_time,end_time,host_club_ID,guest_club_ID)
 VALUES(@start,@end,@hostID,@guestID)
 GO

--2.3(xxvi)
create VIEW matchesPerTeam AS
select C.name,count(*)
from Club C INNER join Match M on (M.host_club_ID=C.club_ID or M.guest_club_ID=C.club_ID)
GROUP BY c.name
having C.end_date < CURRENT_TIMESTAMP

GO
--2.3(xviii)
create FUNCTION [allPendingRequests]
(@stad_mang_username varchar(20))
RETURNS TABLE
AS 
Return 
(Select CR.name as representative_name,C.name as guest_club_name ,M.start_time
from Host_Request HR INNER JOIN Club_Representative CR on HR.representative_ID=CR.ID 
INNER join Match M on HR.match_ID=M.match_ID 
inner Join Club C on M.guest_club_ID=C.club_ID
inner join Stadium_Manager SM on HR.manager_ID=SM.ID
where HR.status = 'unhandled' and HR.manager_ID=Stad_mang_ID and SM.username=@stad_mang_username 
 )
 


 GO
 --2.3(x)
 CREATE PROC deleteStadium 
 @stad_name VARCHAR(20)
 AS
delete from Stadium where name=@stad_name
GO

--2.3(xi)
Create PROCEDURE blockFan 
@national_ID VARCHAR(20)
AS
Update Fan 
Set status = 0 where national_ID=@national_ID
GO

--2.3(xvii)
CREATE PROCEDURE addStadiumManager 
@name VARCHAR(20), @stad_name VARCHAR(20), @username VARCHAR(20),@password VARCHAR(20)
AS
Declare @stad_id int
select @stad_id=ID from Stadium WHERE name=@stad_name
INSERT INTO Syst_User (username,password) Values (@username,@password)
INSERT INTO Stadium_Manager(name,stadium_ID,username) 
VALUES(@name,@stad_id ,@username)
GO

--2.3(i)
CREATE PROCEDURE addAssociationManager 
@name VARCHAR(20),@username VARCHAR(20),@password VARCHAR(20)
AS
INSERT INTO Syst_User (username,password) Values (@username,@password)
INSERT into Sports_Association_Manager (name,username) VALUES (@name,@username)
GO

--2.3(xix)
CREATE PROCEDURE acceptRequest 
@stad_mang_username VARCHAR(20),@host_club_name VARCHAR(20),@guest_club_name VARCHAR(20),@start DATETIME
AS
declare @stad_mang_ID INT
declare @match_id INT
DECLARE @guest_ID INT
DECLARE @host_ID INT
Declare @rep_Id INT

select @guest_ID=club_ID from Club where name=@guest_club_name
select @host_ID =club_ID from Club where name=@host_club_name
Select @rep_Id=ID from Club_Representative where club_ID=@host_ID

select @match_id=match_ID from Match 
where start_time=@start and host_club_ID=@host_ID and guest_club_ID=@guest_ID

SELECT @stad_mang_ID=ID from Stadium_Manager where username=@stad_mang_username

Update Host_Request 
Set status='accepted'
where manager_ID=@stad_mang_ID and match_ID=@match_id and representative_ID=@rep_Id 
GO

--2.3(xx)
CREATE PROCEDURE rejectRequest 
@stad_mang_username VARCHAR(20),@host_club_name VARCHAR(20),@guest_club_name VARCHAR(20),@start DATETIME
AS
declare @stad_mang_ID INT
declare @match_id INT
DECLARE @guest_ID INT
DECLARE @host_ID INT
Declare @rep_Id INT

select @guest_ID=club_ID from Club where name=@guest_club_name
select @host_ID =club_ID from Club where name=@host_club_name
Select @rep_Id=ID from Club_Representative where club_ID=@host_ID

select @match_id=match_ID from Match 
where start_time=@start and host_club_ID=@host_ID and guest_club_ID=@guest_ID

SELECT @stad_mang_ID=ID from Stadium_Manager where username=@stad_mang_username

Update Host_Request 
Set status='rejected'
where manager_ID=@stad_mang_ID and match_ID=@match_id and representative_ID=@rep_Id 
GO

--Monika's 
--2.3(vii)
CREATE PROCEDURE addTicket
@host_club_name varchar(20),@guest_club_name VARCHAR(20),@start DATETIME
AS
declare @match_id INT
DECLARE @guest_ID INT
DECLARE @host_ID INT
select @guest_ID=club_ID from Club where name=@guest_club_name
select @host_ID =club_ID from Club where name=@host_club_name
select @match_id=match_ID from Match 
where start_time=@start and host_club_ID=@host_ID and guest_club_ID=@guest_ID

INSERT INTO Ticket (status,match_ID) VALUES(1,match_id) 

GO

--2.3(viii)
CREATE PROCEDURE deleteClub 
@club_name varchar(20)
AS
DECLARE @guest_ID INT
select @guest_ID=club_ID from Club where name=@guest_club_name

DELETE from Match where guest_club_ID=@guest_ID
DELETE from Club where name=@club_name 
GO

--2.3(ix)

create PROCEDURE addStadium
@Stad_name varchar(20),@stad_address VARCHAR(20),@cap INT
AS
insert into Stadium (name,location,capacity,status) VALUES (@Stad_name,@stad_address,@cap,1)

GO

--2.3(iii) Revise
create VIEW clubsWithNoMatches 
AS
select C1.name from Club C1 
where not exists (select* from  Match M where M.guest_club_ID=C1.club_ID )
and not exists   (select* from  Match M where M.host_club_ID=C1.club_ID )
 

GO

--2.3(xxiv)
create PROCEDURE purchaseTicket 
 @national_ID varchar(20),@host_club_name varchar(20),@guest_club_name VARCHAR(20),@start DATETIME
AS
 declare @match_id INT
DECLARE @guest_ID INT
DECLARE @host_ID INT
Declare @ticket_id int
select @guest_ID=club_ID from Club where name=@guest_club_name
select @host_ID =club_ID from Club where name=@host_club_name
select @match_id=match_ID from Match 
where start_time=@start and host_club_ID=@host_ID and guest_club_ID=@guest_ID
select @ticket_id=ID from Ticket where match_ID=@match_id


insert into Ticket_Buying_Transactions (fan_nationalID,ticket_ID) VALUES (@national_ID,@ticket_id)

GO


