#! /bin/bash

yum update -y
yum install pip -y
python3 -m pip install --user ansible