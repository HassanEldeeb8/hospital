<?php
$servername = "localhost"; // Change this if your database server is different
$username = "root"; // Change this to your database username
$password = ""; // Change this to your database password
$database = "hospital"; // Change this to your database name
$conn = new mysqli($servername, $username, $password, $database);
// Fetch departments and their physicians
$sql_departments = "SELECT d.Department_ID, d.Name AS DepartmentName, p.Physician_ID, p.PName
                    FROM Department d
                    JOIN Works w ON d.Department_ID = w.Department_ID
                    JOIN Physician p ON w.Physician_ID = p.Physician_ID
                    ORDER BY d.Department_ID";

$result_departments = $conn->query($sql_departments);

// Fetch total number of appointments for each physician
$sql_total_appointments = "SELECT p.Physician_ID, p.PName, COUNT(a.Appointment_ID) AS TotalAppointments
                           FROM Physician p
                           LEFT JOIN Appointment a ON p.Physician_ID = a.Physician_ID
                           GROUP BY p.Physician_ID, p.PName";
$result_total_appointments = $conn->query($sql_total_appointments);

// Fetch the department responsible for the highest number of operations
$sql_department_operations = "SELECT o.Department_ID, d.Name AS DepartmentName, COUNT(o.Operation_Name) AS OperationCount
                              FROM Operation o
                              JOIN Department d ON o.Department_ID = d.Department_ID
                              GROUP BY o.Department_ID, d.Name
                              ORDER BY OperationCount DESC";
$result_department_operations = $conn->query($sql_department_operations);

// Fetch average salary of physicians in each department
$sql_avg_salary = "SELECT d.Department_ID, d.Name AS DepartmentName, AVG(p.Salary) AS AverageSalary
                   FROM Department d
                   JOIN Works w ON d.Department_ID = w.Department_ID
                   JOIN Physician p ON w.Physician_ID = p.Physician_ID
                   GROUP BY d.Department_ID, d.Name";
$result_avg_salary = $conn->query($sql_avg_salary);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Departments and Physicians</title>
    <link rel="stylesheet" type="text/css" href="style.css">
    <script>
        function toggleVisibility(elementId) {
            var element = document.getElementById(elementId);
            if (element.style.display === "none") {
                element.style.display = "block";
            } else {
                element.style.display = "none";
            }
        }
    </script>
</head>
<body>
    <h1>Departments</h1>
    <nav>
        <ul>
            <li><a href="index.php">Return to homepage</a></li>
        </ul>
    </nav>
    <h2>List of Departments and Their Physicians</h2>
    <?php
    $current_department_id = null;
    while ($row = $result_departments->fetch_assoc()) {
        if ($current_department_id !== $row['Department_ID']) {
            if ($current_department_id !== null) {
                echo "</ul>";
            }
            $current_department_id = $row['Department_ID'];
            echo "<button onclick=\"toggleVisibility('department_$current_department_id')\"><strong>{$row['DepartmentName']}</strong></button>";
            echo "<ul id='department_$current_department_id' style='display: none;'>";
        }
        echo "<li>{$row['PName']}</li>";
    }
    echo "</ul>";
    ?>

    <h2>Total Appointments for Each Physician</h2>
    <button onclick="toggleVisibility('total_appointments')"><strong>Show Total Appointments</strong></button>
    <table id="total_appointments" style="display: none;">
        <tr>
            <th>Physician Name</th>
            <th>Total Appointments</th>
        </tr>
        <?php while ($row = $result_total_appointments->fetch_assoc()) { ?>
            <tr>
                <td><?php echo $row['PName']; ?></td>
                <td><?php echo $row['TotalAppointments']; ?></td>
            </tr>
        <?php } ?>
    </table>

    <!-- Other sections follow the same pattern -->

    <!-- Revenue Generation by Department -->
    <h2>Revenue Generation by Department</h2>
    <form method="POST" action="">
        <label for="department_id">Select Department:</label>
        <select name="department_id" id="department_id">
            <?php
            $sql_departments = "SELECT Department_ID, Name FROM Department";
            $result_departments = $conn->query($sql_departments);
            while ($row = $result_departments->fetch_assoc()) { ?>
                <option value="<?php echo $row['Department_ID']; ?>"><?php echo $row['Name']; ?></option>
            <?php } ?>
        </select>
        <input type="submit" value="Get Revenue">
    </form>

    <?php
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        $department_id = $_POST['department_id'];

        $stmt = $conn->prepare("SELECT RevenueGenerationByDepartment(?) AS Revenue");
        $stmt->bind_param("i", $department_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($row = $result->fetch_assoc()) {
            echo "<p>Revenue for selected department: $" . $row['Revenue'] . "</p>";
        }
    }
    ?>

</body>
</html>
