#!/bin/bash

# Based on a script from http://wiki.freegeek.org/index.php/Mac_OSX_adduser_script

# Added a while loop for input via a CSV file 10/31/14 --Sean Snodgrass (ssnodgr1@uncc.edu)

# Added the ability to assign a default login picture for either Admin or Standard users 11/08/14 --Sean Snodgrass

# =========================
#  Delete User OSX Command Line
# =========================

# An easy delete user script for Mac OSX.
# This script should work from 10.5 to 10.9 as the dscl commands haven't changed, as far as I can tell.
if [[ $UID -ne 0 ]]; then echo "Please run "$0" as root." && exit 1; fi

input="$1"
# Set "," as the field separator using $IFS
# and read line by line using a while read combo 

while IFS=',' read -r  PASSWORD FULLNAME USERNAME GROUP_ADD
do
  echo "$PASSWORD $FULLNAME $USERNAME $GROUP_ADD"


# A list of (secondary) groups the user should belong to
# This makes the difference between admin and non-admin users.

#Testing seems to show that when a user is deleted...that it is removed from all of the groups it once belonged to
#But I am keeping this here but commented out, incase it or a variation on it is actually needed.

# if [[ "$GROUP_ADD" = standard ]] ; then
 #    SECONDARY_GROUPS="staff everyone localaccounts _appstore _lpoperator _developer"  # for a non-admin user, as of 10.9
# elif [[ "$GROUP_ADD" = admin ]] ; then
#    SECONDARY_GROUPS="everyone localaccounts admin _lpadmin _appserveradm _appserverusr _appstore _lpoperator _developer" # for an admin user, as of 10.9
# else
#    echo "You did not make a valid selection!"; exit 1
# fi


# Delete the user account by running dscl with the delete flag instead of create
echo "Deleting necessary files..."

dscl . delete /Users/"$USERNAME"


#Delete user from any specified groups
 echo "Deleting users from specified groups..."

#List groups 
#dscl . list /groups

#Delete a specific group 
# dseditgroup -o delete $GROUP

#Check if a user is member of a specific group 
# dsmemberutil checkmembership -U "$USER" -G "$GROUP" 
#Ex. convert test8 from an admin to a standard user; sudo dseditgroup -o edit -d test8 -t user admin

#Testing seems to show that when a user is deleted...that it is removed from all of the groups it once belonged to
#But I am keeping this here but commented out, incase it or a variation on it is actually needed.

# for GROUP in $SECONDARY_GROUPS ; do
 #    dseditgroup -o edit -d "$USERNAME" -t user "$GROUP"
# done

# Delete the home directory
echo "Deleting home directory..."
rm -rf /Users/"$USERNAME"

echo "Deleted user $USERID: $USERNAME ($FULLNAME)"

done < "$input"

# Kill the local Directory service on OS X 10.5-10.9; Found in MagerValp's CreateUserPkg-1.2.4.dmg by using Pacifist to view the underlying pkg. 

# Kill local directory service, so it will see our file changes -- it will automatically restart
    /usr/bin/killall DirectoryService 2>/dev/null || /usr/bin/killall opendirectoryd 2>/dev/null

#  This forces the system to rebuild the system caches which include the user's login picture
# along with the local directory cache.
kextcache -system-caches
