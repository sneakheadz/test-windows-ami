# Specify the provider and access details
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}


# Default security group to access the instances via RDP over HTTP and HTTPS
resource "aws_security_group" "default" {
  name        = "terraform_EC2"
  description = "Used in the terraform"

  # RDP access from anywhere
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Lookup the correct AMI based on the region specified
data "aws_ami" "amazon_windows_2016" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }
}

resource "aws_instance" "EC2 Test" {
  instance_type = "t2.micro"
  ami           = "${data.aws_ami.amazon_windows_2016.image_id}"

  # The name of our SSH keypair you've created and downloaded
  # from the AWS console.
  #
  # https://console.aws.amazon.com/ec2/v2/home?region=us-west-2#KeyPairs
  #
  key_name = "${var.key_name}"

  # Our Security group to allow WinRM access
  security_groups = ["${aws_security_group.default.name}"]

  # Note that terraform uses Go WinRM which doesn't support https at this time. If server is not on a private network,
  # recommend bootstraping Chef via user_data.  See asg_user_data.tpl for an example on how to do that.
  user_data = <<EOF
<powershell>
# Variables
$temp = "c:\temp\"
$link = "https://s3.amazonaws.com/software-repo-test/grace-server-aws.msi"
$link1 = "https://s3.amazonaws.com/software-repo-test/Snare-Windows-Agent-v5.0.3-multiarch.exe"
$link11 = "https://s3.amazonaws.com/software-repo-test/SecOpsSnare.inf"
$link2 = "https://s3.amazonaws.com/software-repo-test/NessusAgent-7.1.0-x64.msi"
$link22 = "https://s3.amazonaws.com/software-repo-test/nessus.bat"
$link3 = "https://s3.amazonaws.com/software-repo-test/xagtSetup_20.40.0_universal.msi"
$link33 = "https://s3.amazonaws.com/software-repo-test/agent_config.json"
$link4 = "https://s3.amazonaws.com/software-repo-test/ossec-agent-win32-3.0.0-5505.exe"
$link44 = "https://s3.amazonaws.com/software-repo-test/ossec_install.ps1"
$link5 = "https://s3.amazonaws.com/software-repo-test/CylanceProtect_x64+1490.msi"
$link55 = "https://s3.amazonaws.com/software-repo-test/cylance.bat"
$file = "grace-server-aws.msi"
$file1 = "Snare-Windows-Agent-v5.0.3-multiarch.exe"
$file11 = "SecOpsSnare.inf"
$file2 = "NessusAgent-7.1.0-x64.msi"
$file22 = "nessus.bat"
$file3 = "xagtSetup_20.40.0_universal.msi"
$file33 = "agent_config.json"
$file4 = "ossec-agent-win32-3.0.0-5505.exe"
$file44 = "ossec_install.ps1"
$file5 = "CylanceProtect_x64+1490.msi"
$file55 = "cylance.bat"
$silent = "/quiet"
$silent1 = "/verysilent /suppressmsgboxes /LoadInf=SecOpsSnare.inf /Destination=r27logging.gsa.gov /DesPort=4100 /Protocol=1"
$silent3 = "/qn"
$sleep = "45"

#Install bit9

New-Item $temp -ItemType directory
cd $temp
Invoke-WebRequest -Uri $link -OutFile $file
Start-Sleep -s $sleep
Start-Process -FilePath $file -ArgumentList $silent
Start-Sleep -s $sleep

#Install Snare

Invoke-WebRequest -Uri $link1 -OutFile $file1
Start-Sleep -s $sleep
Invoke-WebRequest -Uri $link11 -OutFile $file11
Start-Sleep -s $sleep
Start-Process -FilePath $file1 -ArgumentList $silent1
Start-Sleep -s $sleep


#Install Fireeye

Invoke-WebRequest -Uri $link33 -OutFile $file33
Start-Sleep -s $sleep
Invoke-WebRequest -Uri $link3 -OutFile $file3
Start-Sleep -s $sleep
Start-Process -FilePath $file3 -ArgumentList $silent3
Start-Sleep -s $sleep

#Install OSSEC

Invoke-WebRequest -Uri $link4 -OutFile $file4
Start-Sleep -s $sleep
Invoke-WebRequest -Uri $link44 -OutFile $file44
Start-Sleep -s $sleep
Start-Process -FilePath $file44
Start-Sleep -s $sleep

#Install Nessus

Invoke-WebRequest -Uri $link2 -OutFile $file2
Start-Sleep -s $sleep
Invoke-WebRequest -Uri $link22 -OutFile $file22
Start-Process -FilePath $file22
Start-Sleep -s $sleep


#Install Cylance

Invoke-WebRequest -Uri $link5 -OutFile $file5
Start-Sleep -s $sleep
Invoke-WebRequest -Uri $link55 -OutFile $file55
Start-Process -FilePath $file55
Start-Sleep -s $sleep


</powershell>

EOF
}