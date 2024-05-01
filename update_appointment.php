<?php
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

// Function to handle the form submission for updating appointment
function updateAppointment($appointmentID, $newPhysicianID, $newAppointmentTime) {
    global $conn;

    if ($newPhysicianID === '') {
        $newPhysicianID = NULL;
    }
    if ($newAppointmentTime === '') {
        $newAppointmentTime = NULL;
    }

    // Prepare the stored procedure call
    $stmt = $conn->prepare("CALL UpdateAppointment(?, ?, ?)");
    $stmt->bind_param("iis", $appointmentID, $newPhysicianID, $newAppointmentTime);

    // Execute the procedure
    if ($stmt->execute()) {
        return $stmt->get_result()->fetch_assoc()['Message'];
    } else {
        return "Error updating appointment: " . $stmt->error;
    }
}

// Function to handle the form submission for deleting appointment
function deleteAppointment($appointmentID) {
    global $conn;

    // Prepare the stored procedure call
    $stmt = $conn->prepare("CALL DeleteAppointment(?)");
    $stmt->bind_param("i", $appointmentID);

    // Execute the procedure
    if ($stmt->execute()) {
        return $stmt->get_result()->fetch_assoc()['Message'];
    } else {
        return "Error deleting appointment: " . $stmt->error;
    }
}

// Fetch and display the appointments
// Fetch and display the appointments
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['show_appointments'])) {
    $selectedPatientID = $_POST['patient_id'];

    // Prepare the SQL statement to retrieve appointments for the selected patient
    $sql = "SELECT a.Appointment_ID, p.Name AS Patient_Name, CONCAT(phy.Physician_ID, ' - ', phy.PName) AS Physician, DATE_FORMAT(a.Time, '%Y-%m-%d %H:%i:%s') AS Appointment_DateTime, op.Operation_Name AS Operation
            FROM Appointment a
            INNER JOIN Patient p ON a.Patient_ID = p.Patient_ID
            INNER JOIN Physician phy ON a.Physician_ID = phy.Physician_ID
            INNER JOIN Operation op ON a.Operation_Name = op.Operation_Name
            WHERE a.Patient_ID = $selectedPatientID";

    // Execute the SQL statement
    $result = $conn->query($sql);

    if ($result) {
        if ($result->num_rows > 0) {
            echo "<h2>Appointments for Patient</h2>";
            echo "<table border='1'>";
            echo "<tr><th>Appointment ID</th><th>Patient Name</th><th>Physician</th><th>Appointment Date & Time</th><th>Operation</th></tr>";
            while ($row = $result->fetch_assoc()) {
                echo "<tr><td>" . $row['Appointment_ID'] . "</td><td>" . $row['Patient_Name'] . "</td><td>" . $row['Physician'] . "</td><td>" . $row['Appointment_DateTime'] . "</td><td>" . $row['Operation'] . "</td></tr>";
            }
            echo "</table>";
        } else {
            echo "No appointments found for the selected patient.";
        }
    } else {
        echo "Error fetching appointments: " . $conn->error;
    }
}

// Check if the form has been submitted for updating or deleting appointment
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (isset($_POST['update_appointment'])) {
        $appointmentID = $_POST['appointment_id'];
        $newPhysicianID = $_POST['new_physician_id'];
        $newAppointmentTime = $_POST['new_appointment_time'];

        // Call the update function
        $resultMessage = updateAppointment($appointmentID, $newPhysicianID, $newAppointmentTime);
        echo "<p>$resultMessage</p>";
    } elseif (isset($_POST['delete_appointment'])) {
        $appointmentID = $_POST['appointment_id'];

        // Call the delete function
        $resultMessage = deleteAppointment($appointmentID);
        echo "<p>$resultMessage</p>";
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Update Appointment</title>
    <link rel="stylesheet" type="text/css" href="style.css"> <!-- Ensure you have a CSS file for styling -->
</head>
<body>
    <h1>Update an Appointment</h1>
    <nav>
        <ul>
            <li><a href="index.php">Return to homepage</a></li>
        </ul>
    </nav>

    <!-- Form for showing appointments for a specific patient -->
    <h2>Show Appointments for Patient</h2>
    <form action="update_appointment.php" method="post">
        <label for="patient_id">Select Patient:</label>
        <select id="patient_id" name="patient_id" required>
            <option value="">Select</option>
            <?php
            // Retrieve list of patients from the database
            $sql = "SELECT Patient_ID, Name FROM Patient";
            $result = $conn->query($sql);
            if ($result->num_rows > 0) {
                while ($row = $result->fetch_assoc()) {
                    echo "<option value='" . $row['Patient_ID'] . "'>" . $row['Name'] . "</option>";
                }
            }
            ?>
        </select>

        <input type="submit" name="show_appointments" value="Show Appointments">
    </form>

    <!-- Form for updating or deleting appointment -->
    <h2>Update or Delete Appointment</h2>
    <form action="update_appointment.php" method="post">
        <label for="appointment_id">Appointment ID:</label>
        <input type="number" id="appointment_id" name="appointment_id" required>

        <label for="new_physician_id">New Physician ID (leave blank if unchanged):</label>
        <input type="number" id="new_physician_id" name="new_physician_id">

        <label for="new_appointment_time">New Appointment Time (format: YYYY-MM-DD HH:MM:SS, leave blank if unchanged):</label>
        <input type="datetime-local" id="new_appointment_time" name="new_appointment_time">

        <input type="submit" name="update_appointment" value="Update Appointment">
        <input type="submit" name="delete_appointment" value="Delete Appointment">
    </form>
</body>
</html>
