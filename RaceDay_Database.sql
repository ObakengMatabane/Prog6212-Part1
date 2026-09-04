/* RaceDay Database Schema */

IF DB_ID('RaceDayDB') IS NULL
BEGIN
    CREATE DATABASE RaceDayDB;
END
GO

USE RaceDayDB;
GO


IF OBJECT_ID('dbo.Payments', 'U') IS NOT NULL DROP TABLE dbo.Payments;
IF OBJECT_ID('dbo.Results', 'U') IS NOT NULL DROP TABLE dbo.Results;
IF OBJECT_ID('dbo.Enrolments', 'U') IS NOT NULL DROP TABLE dbo.Enrolments;
IF OBJECT_ID('dbo.Categories', 'U') IS NOT NULL DROP TABLE dbo.Categories;
IF OBJECT_ID('dbo.Events', 'U') IS NOT NULL DROP TABLE dbo.Events;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
GO

/* Table: Users
   Stores both Organisers and Participants, differentiated by Role.*/
CREATE TABLE dbo.Users (
    UserId          INT IDENTITY(1,1) PRIMARY KEY,
    FullName        NVARCHAR(100)   NOT NULL,
    Email           NVARCHAR(150)   NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(256)   NOT NULL,
    Role            NVARCHAR(20)    NOT NULL DEFAULT 'Participant'
                        CHECK (Role IN ('Organiser', 'Participant')),
    CreatedAt       DATETIME        NOT NULL DEFAULT GETDATE()
);
GO

/* Table: Events
   Each event is created by exactly one Organiser (Users). */

CREATE TABLE dbo.Events (
    EventId         INT IDENTITY(1,1) PRIMARY KEY,
    OrganiserId     INT             NOT NULL,
    EventName       NVARCHAR(150)   NOT NULL,
    Description     NVARCHAR(500)   NULL,
    EventDate       DATE            NOT NULL,
    Location        NVARCHAR(150)   NOT NULL,
    DistanceKm      DECIMAL(6,2)    NOT NULL,
    EventType       NVARCHAR(20)    NOT NULL DEFAULT 'Run'
                        CHECK (EventType IN ('Run', 'Walk', 'Cycle')),
    RouteInfo       NVARCHAR(500)   NULL,
    CreatedAt       DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Events_Organiser FOREIGN KEY (OrganiserId)
        REFERENCES dbo.Users(UserId)
);
GO

/*  Table: Categories
   Each event has one or more categories (e.g. 5km, 10km, 21km). */
CREATE TABLE dbo.Categories (
    CategoryId      INT IDENTITY(1,1) PRIMARY KEY,
    EventId         INT             NOT NULL,
    CategoryName    NVARCHAR(100)   NOT NULL,
    DistanceKm      DECIMAL(5,2)    NOT NULL,
    MaxParticipants INT             NOT NULL DEFAULT 100,
    EntryFee        DECIMAL(8,2)    NOT NULL DEFAULT 0,
    CONSTRAINT FK_Categories_Events FOREIGN KEY (EventId)
        REFERENCES dbo.Events(EventId)
);
GO

/* ------------------------------------------------------------
   Table: Enrolments
   Links a Participant (Users) to a Category they have entered.
   ------------------------------------------------------------ */
CREATE TABLE dbo.Enrolments (
    EnrolmentId     INT IDENTITY(1,1) PRIMARY KEY,
    ParticipantId   INT             NOT NULL,
    CategoryId      INT             NOT NULL,
    EnrolmentDate   DATETIME        NOT NULL DEFAULT GETDATE(),
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'Pending'
                        CHECK (Status IN ('Pending', 'Confirmed', 'Cancelled')),
    CONSTRAINT FK_Enrolments_Users FOREIGN KEY (ParticipantId)
        REFERENCES dbo.Users(UserId),
    CONSTRAINT FK_Enrolments_Categories FOREIGN KEY (CategoryId)
        REFERENCES dbo.Categories(CategoryId),
    CONSTRAINT UQ_Enrolment_Once UNIQUE (ParticipantId, CategoryId)
);
GO

/* ------------------------------------------------------------
   Table: Results
   One result per enrolment, captured by the Organiser.
   ------------------------------------------------------------ */
CREATE TABLE dbo.Results (
    ResultId        INT IDENTITY(1,1) PRIMARY KEY,
    EnrolmentId     INT             NOT NULL UNIQUE,
    FinishTime      TIME            NULL,
    Position        INT             NULL,
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'Finished'
                        CHECK (Status IN ('Finished', 'DNF', 'DQ')),
    CapturedAt      DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Results_Enrolments FOREIGN KEY (EnrolmentId)
        REFERENCES dbo.Enrolments(EnrolmentId)
);
GO

/* ------------------------------------------------------------
   Table: Payments
   One payment record per enrolment (entry fee).
   ------------------------------------------------------------ */
CREATE TABLE dbo.Payments (
    PaymentId       INT IDENTITY(1,1) PRIMARY KEY,
    EnrolmentId     INT             NOT NULL UNIQUE,
    Amount          DECIMAL(8,2)    NOT NULL DEFAULT 0,
    PaymentStatus   NVARCHAR(20)    NOT NULL DEFAULT 'Pending'
                        CHECK (PaymentStatus IN ('Pending', 'Paid', 'Refunded')),
    PaymentDate     DATETIME        NULL,
    CONSTRAINT FK_Payments_Enrolments FOREIGN KEY (EnrolmentId)
        REFERENCES dbo.Enrolments(EnrolmentId)
);
GO

/* Inserting the DATA */
/* Users with 2 Organisers and 2 Participants */
INSERT INTO dbo.Users (FullName, Email, PasswordHash, Role) VALUES
('Thandiwe Nkosi',  'thandiwe.nkosi@raceday.co.za', 'HASH_PLACEHOLDER_1', 'Organiser'),
('Pieter van Wyk',   'pieter.vanwyk@raceday.co.za',  'HASH_PLACEHOLDER_2', 'Organiser'),
('Lindiwe Dube',     'lindiwe.dube@example.com',     'HASH_PLACEHOLDER_3', 'Participant'),
('Sipho Mahlangu',   'sipho.mahlangu@example.com',   'HASH_PLACEHOLDER_4', 'Participant');
GO

/*  Events: 3 events across South Africa  */
/* Note: Event.DistanceKm reflects the event's headline/longest distance;
   Category.DistanceKm below breaks this down per category on offer. */
INSERT INTO dbo.Events (OrganiserId, EventName, Description, EventDate, Location, DistanceKm, EventType, RouteInfo) VALUES
(1, 'Kunyarugo Farms Trail Run', 'A scenic trail run through the Kunyarugo Farms estate in Limpopo.', '2026-10-17', 'Limpopo', 21.1, 'Run', 'Farm gravel roads and single-track, moderate elevation gain.'),
(1, 'Polokwane City 10K',        'A flat, fast road race through the streets of Polokwane.',          '2026-11-08', 'Polokwane, Limpopo', 10.0, 'Run', 'Closed-road tarmac loop, mostly flat.'),
(2, 'Cape Winelands Cycle Tour', 'A charity cycling event through the Cape Winelands.',                '2026-09-27', 'Stellenbosch, Western Cape', 100.0, 'Cycle', 'Rolling hills, tarred roads, water points every 15km.');
GO

/*  Categories */
INSERT INTO dbo.Categories (EventId, CategoryName, DistanceKm, MaxParticipants, EntryFee) VALUES
(1, '10km Trail', 10.0, 200, 150.00),
(1, '21km Trail', 21.1, 150, 250.00),
(2, '5km Fun Run', 5.0, 300, 80.00),
(2, '10km Road Race', 10.0, 300, 150.00),
(3, '50km Cycle', 50.0, 250, 300.00),
(3, '100km Cycle', 100.0, 200, 450.00);
GO

/* Enrolments*/
INSERT INTO dbo.Enrolments (ParticipantId, CategoryId, Status) VALUES
(3, 1, 'Confirmed'),   -- Lindiwe enters 10km Trail
(3, 5, 'Confirmed'),   -- Lindiwe enters 50km Cycle
(4, 2, 'Confirmed'),   -- Sipho enters 21km Trail
(4, 4, 'Pending');     -- Sipho enters 10km Road Race
GO

/* Results */
INSERT INTO dbo.Results (EnrolmentId, FinishTime, Position, Status) VALUES
(1, '00:52:14', 12, 'Finished'),
(3, '01:48:30', 5, 'Finished');
GO

/*  Payments:*/
INSERT INTO dbo.Payments (EnrolmentId, Amount, PaymentStatus, PaymentDate) VALUES
(1, 150.00, 'Paid', '2026-09-01'),
(2, 300.00, 'Paid', '2026-09-01'),
(3, 250.00, 'Paid', '2026-09-05'),
(4, 150.00, 'Pending', NULL);
GO
