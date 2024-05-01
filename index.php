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
// Fetch summary statistics
$sql_total_patients = "SELECT COUNT(*) AS TotalPatients FROM Patient";
$result_total_patients = $conn->query($sql_total_patients);
$total_patients = $result_total_patients->fetch_assoc()['TotalPatients'];

$sql_occupancy_rate = "SELECT BedOccupancyRate() AS OccupancyRate";
$result_occupancy_rate = $conn->query($sql_occupancy_rate);
$occupancy_rate = $result_occupancy_rate->fetch_assoc()['OccupancyRate'];
?>


<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Hospital Dashboard</title>
    <link rel="stylesheet" type="text/css" href="style.css">
    </head>
<body>
    <h1>Welcome to the Hospital Dashboard</h1>
    <nav>
        <ul>
            <li><a href="new_patient.php">Register patient</a></li>
            <li><a href="appointment.php">Book an appointment</a></li>
            <li><a href="update_appointment.php">Update an Appointment</a></li>
            <li><a href="new_physician.php">Register a Physician</a></li>
            <li><a href="departments.php">Departments</a></li>
        </ul>
    </nav>
    <div>
        <h2>Summary Statistics</h2>
        <p>Total Patients: <?php echo $total_patients; ?></p>
        <p>Bed Occupancy Rate: <?php echo $occupancy_rate; ?>%</p>
    </div>
</body>
</html>