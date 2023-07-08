# DevOps Task


## How to navigate

1. Setup Environment variables [click here](#target1)
2. Provision EC2 SERVER  USING TERRAFORM [click here](#target2) 
3. Setteing up the LAMP stack on the server  [click here](#target3) 
4. Creating php.idex  [click here](#target4)
5. Github Actions [click here](#target5) 
6. Networking Basics [click here](#target6) 
7. Connect to instance [click here](#target7) 


## Provision EC2 server using Terraform

<a id="target1"></a>

### Setup Environment variables

##### you should use .local directory which is included in .gitignore that contain script that you can source to set up the enviroment variable 

```bash
# This code exports environment variables for the AWS access key ID, secret access key, and default region.
# Replace the placeholders with your own AWS access key ID, secret access key, and default region.
export AWS_ACCESS_KEY_ID=<your-access-key-id>
export AWS_SECRET_ACCESS_KEY=<your-secret-access-key>
export AWS_DEFAULT_REGION=<your-default-region>

# This code exports environment variables for the Terraform variable username, password, and dbname.
# Replace the placeholders with the values you want to use for each variable.
export TF_VAR_username=<your-username>
export TF_VAR_password=<your-password>
export TF_VAR_dbname=<your-dbname>

```

<a id="target2"></a>

### Provision EC2 SERVER  USING TERRAFORM

##### My terraform directory stucture include the following :
1. networking.tf: contain all the networking compoenents of the sever like the vpc , the subnet , routing tables and the security gorups
2. main.tf :      contain EC2 configration and provsioning the server
3. variables.tf:  contain all varaibles that is required to pass to our terraform project include EC2 configraionts and dB user and password
4. local.tf :     contain a script which is passed to the EC2 to setup all dependeices for the Lamp stack and also the php.index
5. outputs.tf :   tells  terraform to output the public Id of the server so we can test it .

##### I won't go deeper in the terraform documentaion since it's not the main task goal :


<a id="target3"></a>

### Setteing up the LAMP stack on the server

##### I used a script to setup all dependencies for the LAMP stack also to create MYSQL data base to be ready for PHP connection :

###### The script contain the follwoing commands  :


###### Preparing Apache web server  :

```bash
sudo apt install apache2 -y
#This command enables the Apache web server to start automatically when the system boots up. 
sudo systemctl enable apache2
#This command adds a rule to Ubuntuto allow incoming traffic on HTTP port 80 for the Apache web server.
sudo ufw allow 'Apache'
```

###### Editting the dir.conf to make the Apache server recognize index.php :

```bash
sudo echo "<IfModule mod_dir.c>
    DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
</IfModule>" > /etc/apache2/mods-enabled/dir.conf
```

###### Restartting the Apache web server on a Ubuntu system to ensure that the changes take effect. :

```bash
sudo systemctl restart apache2 
```

###### Preparing PHP and MYSQL server  :

```bash
sudo apt install php libapache2-mod-php php-mysql -y
sudo apt install mysql-server -y
sudo systemctl start mysql.service
```

###### Creating MYSQL USER , PASSWORD , dBase and a table called visitors , notice that these values are passed via terraform , please check local.tf file  :

```bash
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
```
 <a id="target4"></a>

### Creating php.idex that would handle clients requests :
##### notice that these values are passed via terraform , please check local.tf file   a var called PHP which contain the php.index content :


###### Declaring dBase variables to connecto to MYSQL dB :

```bash
$servername = "localhost";
$username = "${var.username}";
$password = "${var.password}";
$dbname = "${var.dbname}";
```

###### Create a new MySQL connection :

```bash
$conn = new mysqli($servername, $username, $password, $dbname);

// Check if the connection was successful
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
```

###### Get the visitor's IP address and current time :

```bash
$visitor_ip = $_SERVER['REMOTE_ADDR'];

$current_time = date("Y-m-d H:i:s");
```


###### Insert the visitor's IP address and current time into the database :

```bash
$sql = "INSERT INTO visitors (ip_address, visit_time) VALUES ('$visitor_ip', '$current_time')";
if ($conn->query($sql) === TRUE) {
    echo "Record added successfully";
} else {
    echo "Error adding record: " . $conn->error;
}
```

###### Retrieve the last 10 visitor IP addresses and visit times from the database :

```bash
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
```

###### Close the MySQL connection :

```bash
$conn->close();
```

<a id="target5"></a>

### Creating github actions workflow   :
##### I use a work flow on dev branch to check the terraform configration and ensure it follows the best practices :


<a id="target6"></a>


## Networking Basics :

1. IP address  : An IP address is a unique numerical identifier assigned to every device connected to a network that uses the Internet Protocol for communication. It is used to identify and communicate with other devices on the network, and allows devices to send and receive data across the internet.

2. MAC address : A MAC address is a unique identifier assigned to every network interface controller on a device. It is used to identify devices on a   local network.MAC addresses are fixed and cannot be changed.


3. switches  : switch is a network device that connects devices on a local network. It operates at the data link layer and uses a MAC address table to forward data between devices on the network.
4. routers : router is a network device that connects multiple networks together and forwards data between them. It operates at the network layer of the OSI model and uses routing tables to determine the best path for data to take between networks.

5. routing protocols  : Routing protocols are a set of rules and algorithms. They are used to exchange routing information between routers 


<a id="target7"></a>


## Connect to the instance :

1. Obtain the public IP address or DNS name of your EC2 instance from the Amazon EC2 console.
2. Open a terminal or command prompt on your local machine
3. Ensure that you have the private key file for the key pair that you selected when you launched the EC2 instance.
4. Set the permissions on the private key file to be read-only by the owner with the following command :
```bash
chmod 400 /path/to/private_key.pem
```
5. Connect to the EC2 instance using SSH with the following command:
```bash
ssh -i private_key.pem user@public-ip-address
```

