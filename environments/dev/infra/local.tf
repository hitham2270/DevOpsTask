locals {
  script = <<EOT
#!/bin/bash
sudo apt update

sudo apt install apache2 -y
sudo systemctl enable apache2
sudo ufw allow 'Apache'

sudo echo "<IfModule mod_dir.c>
    DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
</IfModule>" > /etc/apache2/mods-enabled/dir.conf

sudo systemctl restart apache2 

sudo apt install php libapache2-mod-php php-mysql -y
sudo apt install mysql-server -y
sudo systemctl start mysql.service
sudo rm /var/www/html/index.html

mysql -u root << EOP
# Execute MySQL commands
CREATE DATABASE ${var.dbname};
CREATE USER '${var.username}'@'localhost' IDENTIFIED BY '${var.password}';
GRANT ALL PRIVILEGES ON  ${var.dbname}.* TO '${var.username}'@'localhost';
FLUSH PRIVILEGES;
USE ${var.dbname};
CREATE TABLE visitors (
    id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ip_address VARCHAR(15) NOT NULL,
    visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
exit

EOP

EOT


  php = <<EOT
<?php
$servername = "localhost";
$username = "${var.username}";
$password = "${var.password}";
$dbname = "${var.dbname}";


echo "Hello, world!";

// Create a new MySQL connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check if the connection was successful
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Get the visitor's IP address
$visitor_ip = $_SERVER['REMOTE_ADDR'];

// Get the current time
$current_time = date("Y-m-d H:i:s");

// Insert the visitor's IP address and current time into the database
$sql = "INSERT INTO visitors (ip_address, visit_time) VALUES ('$visitor_ip', '$current_time')";
if ($conn->query($sql) === TRUE) {
    echo "Record added successfully";
} else {
    echo "Error adding record: " . $conn->error;
}

// Retrieve the last 10 visitor IP addresses and visit times from the database
$sql = "SELECT * FROM visitors ORDER BY visit_time DESC LIMIT 10";
$result = $conn->query($sql);

// Display the visitor IP addresses and visit times in a table
if ($result->num_rows > 0) {
    echo "<table>";
    echo "<tr><th>IP Address</th><th>Visit Time</th></tr>";
    while($row = $result->fetch_assoc()) {
        echo "<tr><td>" . $row["ip_address"] . "</td><td>" . $row["visit_time"] . "</td></tr>";
    }
    echo "</table>";
} else {
    echo "No visitors";
}

// Close the MySQL connection
$conn->close();
?> > 

EOT

}

resource "null_resource" "cp_file" {
  provisioner "file" {
    source      = "${path.module}/index.php"
    destination = "/home/ubuntu/index.php"
    connection {
      type        = "ssh"
      host        = aws_instance.project-iac.public_ip
      user        = "ubuntu"
      private_key = file("${path.module}/../../../.local/key2.pem")
    }
  }
  depends_on = [aws_instance.project-iac]

}

resource "time_sleep" "wait_18_seconds" {
  create_duration = "18s"

  depends_on = [null_resource.cp_file, aws_instance.project-iac]

}


resource "null_resource" "mv_file" {
  provisioner "remote-exec" {
    inline = [
      "sudo mv /home/ubuntu/index.php /var/www/html/index.php ",
    ]
    connection {
      type        = "ssh"
      host        = aws_instance.project-iac.public_ip
      user        = "ubuntu"
      private_key = file("${path.module}/../../../.local/key2.pem")
    }
  }
  depends_on = [time_sleep.wait_18_seconds]

}

resource "local_file" "write_config_file" {
  content  = local.script
  filename = "${path.module}/.local/script.sh"
}

resource "local_file" "write_php_file" {
  content  = local.php
  filename = "${path.module}/.local/index.php"
}
