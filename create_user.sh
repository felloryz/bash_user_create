#!/bin/bash

# Display help message
function display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -u      Specify useername"
    echo "  -p      Specify user password"
    echo "  -r      Set root privileges"
    echo "  -h      Display help"
}

# Check if arguments are not empty
if [ $# -eq 0 ]; then
    echo "Missing arguments"
    display_help
    exit 0
fi

# Initialize variables for arguments
username=""
password=""
root_flag=false

# Parse options using getopts
while getopts ":u:p:r" OPTION; do
    case $OPTION in
        u)
            username=$OPTARG
            ;;
        p)
            password=$OPTARG
            ;;
        r)
            root_flag=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            display_help
            exit 0
            ;;
        :)
            echo "Option -$OPTARG requires an argument"
            display_help
            exit 0
            ;;
    esac
done

shift $((OPTIND-1)) # Shift script arguments

if $root_flag; then
    current_uid=0
    current_gid=0
else
    # last_uid=$(tail -1 /etc/passwd | cut -d: -f3) 
    last_uid=$(awk -F ":" '$3 > 1000 { uid = $3 } END { print uid }' /etc/passwd) # Get UID from /etc/passwd
    current_uid=$((last_uid+1))
    # last_gid=$(tail -1 /etc/passwd | cut -d: -f4)
    last_gid=$(awk -F ":" '$4 > 1000 { gid = $4 } END { print gid }' /etc/passwd)  # Get GID from /etc/passwd
    current_gid=$((last_gid+1))
fi


passwd_string="$username:x:$current_uid:$current_gid::/home/$username:/bin/bash"
echo "$passwd_string" >> /etc/passwd

if [ -z $password ]; then
    password_hash="*"
else
    hash_salt=$(openssl rand -base64 10)
    password_hash=$(openssl passwd -6 -salt $hash_salt $password)
fi

last_password_changed=$((`date +%s` / (3600 * 24)))

shadow_string="$username:$password_hash:$last_password_changed:0:99999:7:::"
echo "$shadow_string" >> /etc/shadow

# User home directory create 
mkdir "/home/$username"
chmod 755 "/home/$username"
chown "$username" "/home/$username"

group_string="$username:x:$current_gid:"
echo "$group_string" >> /etc/group