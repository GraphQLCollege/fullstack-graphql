#! /bin/sh

mkdir ~/.ssh
touch ~/.ssh/config
cat >> ~/.ssh/config << EOF
VerifyHostKeyDNS yes
StrictHostKeyChecking no
EOF