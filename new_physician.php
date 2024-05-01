<?php
// Database connection parameters
$servername = "localhost";
$username = "root";
$password = "";
$database = "hospital";

// Create connection
$conn = new mysqli($servername, $username, $password, $database);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Check if the form is submitted
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Retrieve form data
    $pname = $_POST['pname'];
    $salary = $_POST['salary'];
    $contact_info = $_POST['contact_info'];
    $department_id = $_POST['department_id'];

    // Prepare and execute the stored procedure to insert a physician
    $stmt = $conn->prepare("CALL InsertPhysician(?, ?, ?, ?)");
    $stmt->bind_param("sisi", $pname, $salary, $contact_info, $department_id);

    if ($stmt->execute()) {
        $registration_message = "Physician registered successfully!";
    } else {
        $registration_error = "Error: " . $stmt->error;
    }
}

// Fetch departments
$sql_departments = "SELECT Department_ID, Name FROM Department";
$result_departments = $conn->query($sql_departments);
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Register Physician</title>
    <link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
    <h1>Register a Physician</h1>
    <nav>
        <ul>
            <li><a href="index.php">Return to homepage</a></li>
        </ul>
    </nav>
    <?php if(isset($registration_message)): ?>
        <div class="success-message"><?php echo $registration_message; ?></div>
    <?php endif; ?>
    
    <?php if(isset($registration_error)): ?>
        <div class="error-message"><?php echo $registration_error; ?></div>
    <?php endif; ?>

    <form action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>" method="post">
        <label for="pname">Name:</label>
        <input type="text" name="pname" id="pname" required>

        <label for="salary">Salary:</label>
        <input type="number" name="salary" id="salary" required>

        <label for="contact_info">Contact Info:</label>
        <input type="text" name="contact_info" id="contact_info" required>

        <label for="department_id">Department:</label>
        <select name="department_id" id="department_id">
            <?php while ($row = $result_departments->fetch_assoc()) { ?>
                <option value="<?php echo $row['Department_ID']; ?>"><?php echo $row['Name']; ?></option>
            <?php } ?>
        </select>

        <input type="submit" value="Register Physician">
    </form>
</body>
</html>

<?php
// Close the database connection
$conn->close();
?>
