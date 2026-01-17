#!/bin/bash
    ssh arch << EOF
    echo "Hello from arch"
    whoami
    cd ~/win
    ls
EOF
    ssh arch << EOF
    whoami
    ls
    exit
EOF