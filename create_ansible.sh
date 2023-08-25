#! /bin/bash

sudo su
sudo yum update -y
sudo yum install pip -y
sudo python3 -m pip install --user ansible