<?php
// Database connection parameters
$servername = "localhost"; // Change this if your database server is different
$username = "root"; // Change this to your database username
$password = ""; // Change this to your database password
$database = "hospital"; // Change this to your database name

// Create connection
$conn = new mysqli($servername, $username, $password, $database);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Function to find physician availability
function findPhysiciansByAvailability($operationName, $timeSlot, $conn) {
    $stmt = $conn->prepare("CALL FindPhysiciansByAvailability(?, ?)");
    $stmt->bind_param("ss", $operationName, $timeSlot);
    $stmt->execute();
    $result = $stmt->get_result();

    // Fetch result and display
    echo "<h3>Available Physicians for $operationName at $timeSlot:</h3>";
    echo "<ul>";
    while ($row = $result->fetch_assoc()) {
        echo "<li>{$row['PName']}</li>";
    }
    echo "</ul>";

    $stmt->close();
}

// Function to check room availability
function checkRoomAvailability($appointmentDateTime, $conn) {
    $stmt = $conn->prepare("CALL AvailableRoomsAtGivenTime(?)");
    $stmt->bind_param("s", $appointmentDateTime);
    $stmt->execute();
    $result = $stmt->get_result();

    // Fetch result and display
    echo "<h3>Available Rooms for $appointmentDateTime:</h3>";
    echo "<ul>";
    while ($row = $result->fetch_assoc()) {
        echo "<li>{$row['Available_Room']}</li>";
    }
    echo "</ul>";

    $stmt->close();
}

// Handle form submission for booking appointment
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Check if form inputs are set
    $patient_id = $_POST['patient_id'] ?? null;
    $physician_id = $_POST['physician_id'] ?? null;
    $room_number = $_POST['room_number'] ?? null;
    $operation_name = $_POST['operation_name'] ?? null;
    $appointment_datetime = $_POST['appointment_datetime'] ?? null;

    if ($patient_id && $physician_id && $room_number && $operation_name && $appointment_datetime) {
        // Insert into the Appointment table
        $stmt = $conn->prepare("CALL InsertAppointment(?, ?, ?, ?, ?)");
        $stmt->bind_param("iiiss", $patient_id, $physician_id, $room_number, $operation_name, $appointment_datetime);

        if ($stmt->execute()) {
            echo "Appointment booked successfully!";
        } else {
            echo "Error: " . $stmt->error;
        }
    } else {
        echo "Error: Form data incomplete.";
    }
}

// Fetch patients, physicians, operations, and rooms
$sql_patients = "SELECT Patient_ID, Name FROM Patient";
$sql_physicians = "SELECT Physician_ID, PName FROM Physician";
$sql_operations = "SELECT Operation_Name FROM Operation";
$sql_rooms = "SELECT Room_Number FROM Room WHERE Availability = 1";

$result_patients = $conn->query($sql_patients);
$result_physicians = $conn->query($sql_physicians);
$result_operations = $conn->query($sql_operations);
$result_rooms = $conn->query($sql_rooms);
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Book an Appointment</title>
    <link rel="stylesheet" type="text/css" href="style.css"> <!-- Ensure you have a CSS file for styling -->
</head>
<body>
    <h1>Book an Appointment</h1>
    <nav>
        <ul>
            <li><a href="index.php">Return to homepage</a></li>
            <li><a href="update_appointment.php">Update an Appointment</a></li>
        </ul>
    </nav>
    <form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="post">
        <label for="patient_id">Select Patient:</label>
        <select name="patient_id" id="patient_id">
            <?php while ($row = $result_patients->fetch_assoc()) { ?>
                <option value="<?php echo $row['Patient_ID']; ?>"><?php echo $row['Name']; ?></option>
            <?php } ?>
        </select>

        <label for="physician_id">Select Physician:</label>
        <select name="physician_id" id="physician_id">
            <?php while ($row = $result_physicians->fetch_assoc()) { ?>
                <option value="<?php echo $row['Physician_ID']; ?>"><?php echo $row['PName']; ?></option>
            <?php } ?>
        </select>

        <label for="operation_name">Select Operation:</label>
        <select name="operation_name" id="operation_name">
            <?php while ($row = $result_operations->fetch_assoc()) { ?>
                <option value="<?php echo $row['Operation_Name']; ?>"><?php echo $row['Operation_Name']; ?></option>
            <?php } ?>
        </select>

        <label for="room_number">Select Room:</label>
        <select name="room_number" id="room_number">
            <?php while ($row = $result_rooms->fetch_assoc()) { ?>
                <option value="<?php echo $row['Room_Number']; ?>"><?php echo $row['Room_Number']; ?></option>
            <?php } ?>
        </select>

        <label for="appointment_datetime">Appointment Date and Time:</label>
        <input type="datetime-local" name="appointment_datetime" id="appointment_datetime" required>
        
        <input type="submit" value="Book Appointment">
    </form>

    <!-- Find Physician Box -->
    <div class="find-box">
        <h2>Find Physician Availability</h2>
        <form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="post">
            <label for="operation_name">Select Operation:</label>
            <select name="operation_name" id="operation_name">
                <?php
                // Reset query result pointer
                $result_operations->data_seek(0);
                while ($row = $result_operations->fetch_assoc()) {
                ?>
                    <option value="<?php echo $row['Operation_Name']; ?>"><?php echo $row['Operation_Name']; ?></option>
                <?php } ?>
            </select>
            <label for="time_slot">Select Time Slot:</label>
            <input type="datetime-local" name="time_slot" id="time_slot" required>
            <input type="submit" value="Find Physician">
        </form>
        <?php
        if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['operation_name']) && isset($_POST['time_slot'])) {
            $operationName = $_POST['operation_name'];
            $timeSlot = $_POST['time_slot'];
            findPhysiciansByAvailability($operationName, $timeSlot, $conn);
        }
        ?>
    </div>

    <!-- Room Availability Box -->
    <div class="availability-box">
        <h2>Room Availability</h2>
        <p>Check room availability for upcoming appointments:</p>
        <form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="post">
            <label for="appointment_date_time">Appointment Date and Time:</label>
            <input type="datetime-local" name="appointment_date_time" id="appointment_date_time" required>
            <input type="submit" value="Check Availability">
        </form>
        <?php
        if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['appointment_date_time'])) {
            $appointmentDateTime = $_POST['appointment_date_time'];
            checkRoomAvailability($appointmentDateTime, $conn);
        }
        ?>
    </div>
</body>
</html>
