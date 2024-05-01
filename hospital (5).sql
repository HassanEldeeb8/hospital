-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 01, 2024 at 11:32 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `hospital`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `AvailableRoomsAtGivenTime` (IN `timeSlot` DATETIME)   BEGIN
    -- Select available rooms that are not booked during the specified time slot
    SELECT CONCAT('Room ', Room_Number) AS Available_Room
    FROM Room
    WHERE Availability = 1
    AND Room_Number NOT IN (
        SELECT Room_Number
        FROM Appointment
        WHERE Time = timeSlot
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteAppointment` (IN `appointmentID` INT)   BEGIN
    DECLARE appointmentExists INT;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    -- Check if the appointment exists
    SELECT COUNT(*) INTO appointmentExists FROM Appointment WHERE Appointment_ID = appointmentID;

    -- If appointment exists, delete it
    IF appointmentExists > 0 THEN
        DELETE FROM Appointment WHERE Appointment_ID = appointmentID;
        SELECT 'Appointment deleted successfully.' AS Message;
    ELSE
        SELECT 'Appointment not found.' AS Message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `FindPhysiciansByAvailability` (IN `operationName` VARCHAR(255), IN `timeSlot` DATETIME)   BEGIN
    SELECT 
        phy.Physician_ID,
        phy.PName
    FROM 
        Physician phy
    INNER JOIN 
        Works w ON phy.Physician_ID = w.Physician_ID
    INNER JOIN 
        Operation op ON w.Department_ID = op.Department_ID
    WHERE 
        op.Operation_Name = operationName
        AND NOT EXISTS (
            SELECT 1
            FROM Appointment app
            WHERE app.Physician_ID = phy.Physician_ID
                AND app.Time = timeSlot
        );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertAppointment` (IN `patientID` INT, IN `physicianID` INT, IN `roomNumber` INT, IN `operationName` VARCHAR(255), IN `appointmentTime` DATETIME)   BEGIN
    -- Insert the appointment into the Appointment table with auto-incremented ID
    INSERT INTO Appointment (Patient_ID, Physician_ID, Room_Number, Operation_Name, Time)
    VALUES (patientID, physicianID, roomNumber, operationName, appointmentTime);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertPatient` (IN `name` VARCHAR(255), IN `insuranceInfo` VARCHAR(255), IN `yearOfBirth` INT, IN `phoneNumber` VARCHAR(20))   BEGIN
    -- Insert the patient into the Patient table with auto-incremented ID
    INSERT INTO Patient (Name, Insurance_Info, Year_of_Birth, Phone_Number)
    VALUES (name, insuranceInfo, yearOfBirth, phoneNumber);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertPhysician` (IN `pname` VARCHAR(255), IN `salary` DECIMAL(10,2), IN `contactInfo` VARCHAR(255), IN `departmentID` INT)   BEGIN
    -- Insert the physician into the Physician table with auto-incremented ID
    INSERT INTO Physician (PName, Salary, Contact_Info)
    VALUES (pname, salary, contactInfo);

    -- Get the auto-incremented ID of the newly inserted physician
    SET @physicianID = LAST_INSERT_ID();

    -- Insert the association between the physician and department into the Works table
    INSERT INTO Works (Department_ID, Physician_ID)
    VALUES (departmentID, @physicianID);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ShowAppointmentsForPatient` (IN `patientID` INT)   BEGIN
    SELECT 
        a.Appointment_ID,
        p.Name AS Patient_Name,
        phy.PName AS Physician_Name,
        a.Time AS Appointment_Time,
        op.Operation_Name AS Operation
    FROM 
        Appointment a
    INNER JOIN 
        Patient p ON a.Patient_ID = p.Patient_ID
    INNER JOIN 
        Physician phy ON a.Physician_ID = phy.Physician_ID
    INNER JOIN 
        Operation op ON a.Operation_Name = op.Operation_Name
    WHERE 
        a.Patient_ID = patientID;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateAppointment` (IN `appointmentID` INT, IN `newPhysicianID` INT, IN `newAppointmentTime` DATETIME)   BEGIN
    DECLARE originalPhysicianID INT;
    DECLARE originalTime DATETIME;

    -- Retrieve the original physician ID and time of the appointment
    SELECT Physician_ID, Time INTO originalPhysicianID, originalTime
    FROM Appointment
    WHERE Appointment_ID = appointmentID;

    -- Check if the new physician is available at the new time
    IF newPhysicianID IS NOT NULL AND newAppointmentTime IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM Appointment
            WHERE Physician_ID = newPhysicianID AND Time = newAppointmentTime AND Appointment_ID != appointmentID
        ) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The new physician is not available at the given time.';
        END IF;
    END IF;

    -- Update the appointment with the new physician ID and time
    UPDATE Appointment
    SET Physician_ID = IFNULL(newPhysicianID, originalPhysicianID),
        Time = IFNULL(newAppointmentTime, originalTime)
    WHERE Appointment_ID = appointmentID;

    -- Optional: Output a success message
    SELECT 'Appointment updated successfully!' AS Message;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `BedOccupancyRate` () RETURNS DECIMAL(5,2)  BEGIN
    DECLARE totalBeds INT;
    DECLARE occupiedBeds INT;
    DECLARE occupancyRate DECIMAL(5,2);

    -- Get the total number of beds
    SELECT COUNT(*) INTO totalBeds FROM Room;

    -- Get the number of occupied beds
    SELECT COUNT(*) INTO occupiedBeds FROM Room WHERE Availability = 1;

    -- Calculate the occupancy rate
    IF totalBeds > 0 THEN
        SET occupancyRate = (occupiedBeds / totalBeds) * 100;
    ELSE
        SET occupancyRate = 0;
    END IF;

    RETURN occupancyRate;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `RevenueGenerationByDepartment` (`departmentId` INT) RETURNS DECIMAL(10,2)  BEGIN
    DECLARE totalRevenue DECIMAL(10,2);

    -- Calculate total revenue for the given department
    SELECT SUM(op.Cost) INTO totalRevenue
    FROM Appointment a
    INNER JOIN Operation op ON a.Operation_Name = op.Operation_Name
    WHERE op.Department_ID = departmentId;

    RETURN totalRevenue;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `appointment`
--

CREATE TABLE `appointment` (
  `Appointment_ID` int(11) NOT NULL,
  `Patient_ID` int(11) DEFAULT NULL,
  `Physician_ID` int(11) DEFAULT NULL,
  `Time` datetime DEFAULT NULL,
  `Operation_Name` varchar(255) DEFAULT NULL,
  `Room_Number` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `appointment`
--

INSERT INTO `appointment` (`Appointment_ID`, `Patient_ID`, `Physician_ID`, `Time`, `Operation_Name`, `Room_Number`) VALUES
(2, 2, 2, '2024-04-15 09:00:00', 'Knee Replacement', 103),
(3, 3, 3, '2024-04-15 10:00:00', 'Angioplasty', 105),
(4, 4, 4, '2024-04-15 11:00:00', 'Lumbar Fusion', 107),
(5, 5, 5, '2024-04-15 12:00:00', 'Cataract Surgery', 109),
(6, 6, 6, '2024-04-15 13:00:00', 'Hip Replacement', 111),
(7, 7, 7, '2024-04-15 14:00:00', 'Gastric Bypass', 113),
(8, 8, 8, '2024-04-15 15:00:00', 'Coronary Bypass', 115),
(9, 9, 9, '2024-04-15 16:00:00', 'LASIK Surgery', 117),
(10, 10, 10, '2024-04-15 17:00:00', 'Tonsillectomy', 119),
(11, 11, 15, '2024-04-15 08:30:00', 'Appendectomy', 121),
(12, 12, 2, '2024-04-15 09:30:00', 'Knee Replacement', 123),
(13, 13, 13, '2024-04-15 10:30:00', 'Angioplasty', 125),
(14, 14, 15, '2024-12-04 11:30:00', 'Lumbar Fusion', 127),
(15, 15, 15, '2024-04-15 12:30:00', 'Cataract Surgery', 129),
(16, NULL, NULL, NULL, NULL, NULL),
(18, 1, 3, '2026-05-20 10:00:00', 'Knee Replacement', 103),
(20, 1, 1, '2022-02-22 02:22:00', 'Appendectomy', 101),
(22, 1, 5, '2022-02-22 02:22:00', 'Appendectomy', 101),
(24, 5, 5, '0000-00-00 00:00:00', 'Hip Replacement', 101);

--
-- Triggers `appointment`
--
DELIMITER $$
CREATE TRIGGER `Prevent_Double_Booking` BEFORE INSERT ON `appointment` FOR EACH ROW BEGIN
    DECLARE countAppointments INT;
    DECLARE duration TIME;

    -- Retrieve the duration of the operation associated with the appointment
    SELECT Duration INTO duration
    FROM Operation
    WHERE Operation_Name = NEW.Operation_Name;

    -- Calculate the end time of the new appointment by adding its duration to the start time
    SET @end_time = ADDTIME(NEW.Time, duration);

    -- Check if the doctor has another appointment overlapping with the new appointment's time range
    SELECT COUNT(*) INTO countAppointments 
    FROM Appointment 
    WHERE Physician_ID = NEW.Physician_ID 
    AND NOT (
        @end_time <= Time OR NEW.Time >= ADDTIME(Time, duration)
    );
    
    -- If the doctor has another appointment overlapping with the new appointment, raise an error
    IF countAppointments > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The doctor already has an appointment during this time';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `UpdateRoomAvailability` AFTER INSERT ON `appointment` FOR EACH ROW BEGIN
    DECLARE totalAppointments INT;
    DECLARE duration TIME;

    -- Retrieve the duration of the operation associated with the appointment
    SELECT Duration INTO duration
    FROM Operation
    WHERE Operation_Name = NEW.Operation_Name;

    -- Calculate the end time of the new appointment by adding its duration to the start time
    SET @end_time = ADDTIME(NEW.Time, duration);

    -- Count the total number of appointments for the room within the appointment's time range
    SELECT COUNT(*) INTO totalAppointments
    FROM Appointment
    WHERE Room_Number = NEW.Room_Number
    AND NOT (
        @end_time <= Time OR NEW.Time >= ADDTIME(Time, duration)
    );

    -- Update the availability in the Room table based on the total number of appointments
    IF totalAppointments > 0 THEN
        UPDATE Room SET Availability = 0 WHERE Room_Number = NEW.Room_Number;
    ELSE
        UPDATE Room SET Availability = 1 WHERE Room_Number = NEW.Room_Number;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_appointment_insert` BEFORE INSERT ON `appointment` FOR EACH ROW BEGIN
    DECLARE room_count INT;
    DECLARE duration TIME;

    -- Retrieve the duration of the operation associated with the appointment
    SELECT Duration INTO duration
    FROM Operation
    WHERE Operation_Name = NEW.Operation_Name;

    -- Calculate the end time of the new appointment by adding its duration to the start time
    SET @end_time = ADDTIME(NEW.Time, duration);

    -- Check if the room is available within the specified time range
    SELECT COUNT(*)
    INTO room_count
    FROM Appointment
    WHERE Room_Number = NEW.Room_Number
    AND NOT (
        @end_time <= Time OR NEW.Time >= ADDTIME(Time, duration)
    );

    -- If the room is already assigned to an appointment within the specified time range, prevent the insertion
    IF room_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Room is already assigned to another appointment during the specified time range';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `department`
--

CREATE TABLE `department` (
  `Department_ID` int(11) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `Description` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `department`
--

INSERT INTO `department` (`Department_ID`, `name`, `Description`) VALUES
(1, 'Cardiology', 'Specializes in heart-related conditions'),
(2, 'Orthopedics', 'Specializes in bone and joint disorders'),
(3, 'Neurology', 'Specializes in disorders of the nervous system'),
(4, 'Oncology', 'Specializes in cancer treatment and care'),
(5, 'Pediatrics', 'Specializes in medical care for children');

-- --------------------------------------------------------

--
-- Table structure for table `operation`
--

CREATE TABLE `operation` (
  `Operation_Name` varchar(255) NOT NULL,
  `Department_ID` int(11) DEFAULT NULL,
  `Cost` decimal(10,2) DEFAULT NULL,
  `Duration` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `operation`
--

INSERT INTO `operation` (`Operation_Name`, `Department_ID`, `Cost`, `Duration`) VALUES
('Angioplasty', 3, 5000.00, '01:45:00'),
('Appendectomy', 1, 1500.00, '02:00:00'),
('Cataract Surgery', 5, 2500.00, '01:30:00'),
('Coronary Bypass', 1, 12000.00, '04:30:00'),
('Gastric Bypass', 3, 10000.00, '02:45:00'),
('Hip Replacement', 2, 9000.00, '03:00:00'),
('Knee Replacement', 2, 8000.00, '03:30:00'),
('LASIK Surgery', 5, 3000.00, '01:15:00'),
('Lumbar Fusion', 4, 7000.00, '04:15:00'),
('Tonsillectomy', 4, 2000.00, '01:45:00');

-- --------------------------------------------------------

--
-- Table structure for table `patient`
--

CREATE TABLE `patient` (
  `Patient_ID` int(11) NOT NULL,
  `Name` varchar(255) DEFAULT NULL,
  `Insurance_Info` varchar(255) DEFAULT NULL,
  `Year_of_Birth` int(11) DEFAULT NULL,
  `Phone_Number` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `patient`
--

INSERT INTO `patient` (`Patient_ID`, `Name`, `Insurance_Info`, `Year_of_Birth`, `Phone_Number`) VALUES
(1, 'Ahmed Mohsen', '2', 1993, '010-7972-5512'),
(2, 'Mohammed Ahmed', '55', 2017, '012-9155-5617'),
(3, 'Rammy Barkkat ', '100', 2007, '015-9626-9781'),
(4, 'Menna Nabil', '97', 2019, '012-6102-7235'),
(5, 'Christopher ahmed', '5', 2022, '012-8916-7332'),
(6, 'Ahmed Ashraf', '31', 1978, '010-2956-6733'),
(7, 'Ahmed Sallam', '62', 1992, '011-2702-4451'),
(8, 'Ahmed mohamed ', '26', 2020, '010-1494-9482'),
(9, 'ahemd Abd Elsamea', '63', 1964, '010-0208-9562'),
(10, 'sara mohamed', '93', 2011, '015-7306-3752'),
(11, 'Ahmed Hany', '8', 1985, '012-7776-7137'),
(12, 'Aly kareem', '5', 2016, '010-3063-6010'),
(13, 'Menna Ashraf', '42', 1986, '011-8933-4826'),
(14, 'Waleed aly', '83', 2009, '015-0960-1515'),
(15, 'Wael yaser ', '90', 1995, '010-4917-3286'),
(16, 'Mohamed Salah', '77', 1972, '012-1475-9428'),
(17, 'Kasem Nabil ', '51', 2007, '010-6933-6333'),
(18, 'Yosra Ahmed', '30', 1990, '012-1916-4929'),
(19, 'Regina Ortiz', '7', 2016, '015-8350-0527'),
(20, 'Habiba Ayman', '72', 2014, '015-7674-6486'),
(21, 'Mazen Elhelw', '99', 2008, '012-4210-3243'),
(22, 'Susan Ahmed ', '5', 2005, '010-7332-2097'),
(23, 'Yasser Aly', '4', 1991, '015-4265-0178'),
(24, 'Abeer Ali ', '37', 2001, '012-9610-4911'),
(25, 'Mostafa Mohamed', '86', 2006, '015-7988-7027'),
(27, 'H', '55', 2000, '111'),
(28, 'mm', '34', 2002, '999');

-- --------------------------------------------------------

--
-- Table structure for table `physician`
--

CREATE TABLE `physician` (
  `Physician_ID` int(11) NOT NULL,
  `PName` varchar(255) DEFAULT NULL,
  `Salary` decimal(10,2) DEFAULT NULL,
  `Contact_Info` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `physician`
--

INSERT INTO `physician` (`Physician_ID`, `PName`, `Salary`, `Contact_Info`) VALUES
(1, 'Dr. Abdel Nour', 100000.00, '555-1234'),
(2, 'Dr. Ibrahim', 95000.00, '555-5678'),
(3, 'Dr. Mansour', 110000.00, '555-9876'),
(4, 'Dr. Salah', 105000.00, '555-4321'),
(5, 'Dr. Farag', 98000.00, '555-8765'),
(6, 'Dr. Said', 102000.00, '555-2468'),
(7, 'Dr. Khalil', 115000.00, '555-1357'),
(8, 'Dr. Kamel', 99000.00, '555-8642'),
(9, 'Dr. Saeed', 105000.00, '555-3197'),
(10, 'Dr. Awad', 97000.00, '555-7524'),
(11, 'Dr. Adel', 112000.00, '555-6985'),
(12, 'Dr. El-Masry', 108000.00, '555-4785'),
(13, 'Dr. Hamdi', 96000.00, '555-1230'),
(14, 'Dr. Samir', 104000.00, '555-4569'),
(15, 'Dr. Tawfik', 107000.00, '555-9870'),
(16, 'Mo Abd Elazim', 23333.00, '002');

-- --------------------------------------------------------

--
-- Table structure for table `room`
--

CREATE TABLE `room` (
  `Room_Number` int(11) NOT NULL,
  `Availability` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `room`
--

INSERT INTO `room` (`Room_Number`, `Availability`) VALUES
(101, 1),
(102, 1),
(103, 1),
(104, 1),
(105, 1),
(106, 1),
(107, 1),
(108, 1),
(109, 1),
(110, 1),
(111, 1),
(112, 1),
(113, 1),
(114, 1),
(115, 1),
(116, 1),
(117, 1),
(118, 1),
(119, 1),
(120, 1),
(121, 1),
(122, 1),
(123, 1),
(124, 1),
(125, 1),
(126, 1),
(127, 1),
(128, 1),
(129, 1),
(130, 1);

-- --------------------------------------------------------

--
-- Table structure for table `works`
--

CREATE TABLE `works` (
  `Department_ID` int(11) NOT NULL,
  `Physician_ID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `works`
--

INSERT INTO `works` (`Department_ID`, `Physician_ID`) VALUES
(1, 1),
(1, 2),
(1, 11),
(2, 3),
(2, 4),
(2, 12),
(2, 16),
(3, 5),
(3, 6),
(3, 13),
(4, 7),
(4, 8),
(4, 14),
(5, 9),
(5, 10),
(5, 15);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `appointment`
--
ALTER TABLE `appointment`
  ADD PRIMARY KEY (`Appointment_ID`),
  ADD KEY `Patient_ID` (`Patient_ID`),
  ADD KEY `Physician_ID` (`Physician_ID`),
  ADD KEY `Operation_Name` (`Operation_Name`),
  ADD KEY `Room_Number` (`Room_Number`);

--
-- Indexes for table `department`
--
ALTER TABLE `department`
  ADD PRIMARY KEY (`Department_ID`);

--
-- Indexes for table `operation`
--
ALTER TABLE `operation`
  ADD PRIMARY KEY (`Operation_Name`),
  ADD KEY `Department_ID` (`Department_ID`);

--
-- Indexes for table `patient`
--
ALTER TABLE `patient`
  ADD PRIMARY KEY (`Patient_ID`);

--
-- Indexes for table `physician`
--
ALTER TABLE `physician`
  ADD PRIMARY KEY (`Physician_ID`);

--
-- Indexes for table `room`
--
ALTER TABLE `room`
  ADD PRIMARY KEY (`Room_Number`);

--
-- Indexes for table `works`
--
ALTER TABLE `works`
  ADD PRIMARY KEY (`Department_ID`,`Physician_ID`),
  ADD KEY `Physician_ID` (`Physician_ID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `appointment`
--
ALTER TABLE `appointment`
  MODIFY `Appointment_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `department`
--
ALTER TABLE `department`
  MODIFY `Department_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `patient`
--
ALTER TABLE `patient`
  MODIFY `Patient_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT for table `physician`
--
ALTER TABLE `physician`
  MODIFY `Physician_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `appointment`
--
ALTER TABLE `appointment`
  ADD CONSTRAINT `appointment_ibfk_1` FOREIGN KEY (`Patient_ID`) REFERENCES `patient` (`Patient_ID`),
  ADD CONSTRAINT `appointment_ibfk_2` FOREIGN KEY (`Physician_ID`) REFERENCES `physician` (`Physician_ID`),
  ADD CONSTRAINT `appointment_ibfk_3` FOREIGN KEY (`Operation_Name`) REFERENCES `operation` (`Operation_Name`),
  ADD CONSTRAINT `appointment_ibfk_4` FOREIGN KEY (`Room_Number`) REFERENCES `room` (`Room_Number`);

--
-- Constraints for table `operation`
--
ALTER TABLE `operation`
  ADD CONSTRAINT `operation_ibfk_1` FOREIGN KEY (`Department_ID`) REFERENCES `department` (`Department_ID`);

--
-- Constraints for table `works`
--
ALTER TABLE `works`
  ADD CONSTRAINT `works_ibfk_1` FOREIGN KEY (`Department_ID`) REFERENCES `department` (`Department_ID`),
  ADD CONSTRAINT `works_ibfk_2` FOREIGN KEY (`Physician_ID`) REFERENCES `physician` (`Physician_ID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
