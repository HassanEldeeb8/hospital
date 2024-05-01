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

// Check if the form is submitted
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $name = $_POST['name'];
    $insurance_info = $_POST['insurance_info'];
    $year_of_birth = $_POST['year_of_birth'];
    $phone_number = $_POST['phone_number'];

    // Prepare and bind the statement
    $stmt = $conn->prepare("CALL InsertPatient(?, ?, ?, ?)");
    $stmt->bind_param("ssis", $name, $insurance_info, $year_of_birth, $phone_number);

    // Execute the statement
    if ($stmt->execute()) {
        echo "Patient registered successfully!";
    } else {
        echo "Error: " . $stmt->error;
    }

    // Close statement
    $stmt->close();
}

// Close connection
$conn->close();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Register Patient</title>
    <link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
    <h1>Register a Patient</h1>
    <nav>
        <ul>
            <li><a href="appointment.php">Book an appointment</a></li>
            <li><a href="index.php">Return to homepage</a></li>
        </ul>
    </nav>
    <form action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>" method="post">
        <label for="name">Name:</label>
        <input type="text" name="name" id="name" required>

        <label for="insurance_info">Insurance Info:</label>
        <input type="text" name="insurance_info" id="insurance_info" required>

        <label for="year_of_birth">Year of Birth:</label>
        <input type="number" name="year_of_birth" id="year_of_birth" required>

        <label for="phone_number">Phone Number:</label>
        <input type="text" name="phone_number" id="phone_number" required>

        <input type="submit" value="Register Patient">
    </form>
</body>
</html>
