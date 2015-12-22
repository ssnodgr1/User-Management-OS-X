#!/bin/bash

# Based on a script from http://wiki.freegeek.org/index.php/Mac_OSX_adduser_script

# Added a while loop for input via a CSV file 10/31/14 --Sean Snodgrass (ssnodgr1@uncc.edu)

# Added the ability to assign a default login picture for either Admin or Standard users 11/08/14 --Sean Snodgrass

# Disables prompting for Apple ID/iCloud setup upon first login 11/10/14 -- Sean Snodgrass 

# =========================
# Add User OSX Command Line
# =========================

# An easy add user script for Mac OSX.
# Although I wrote this for 10.7 Lion Server, these commands have been the same since 10.5 Leopard.
# It's pretty simple as it uses and strings together the (rustic and ancient) commands that OSX 
# already uses to add users.

if [[ $UID -ne 0 ]]; then echo "Please run "$0" as root." && exit 1; fi

input="$1"
# Set "," as the field separator using $IFS
# and read line by line using a while read combo 
while IFS=',' read -r  PASSWORD FULLNAME USERNAME GROUP_ADD
do
  echo "$PASSWORD $FULLNAME $USERNAME $GROUP_ADD"


# A list of (secondary) groups the user should belong to
# This makes the difference between admin and non-admin users.


if [[ "$GROUP_ADD" = standard ]] ; then
    SECONDARY_GROUPS="staff everyone localaccounts _appstore _lpoperator _developer"  # for a non-admin user, as of 10.9
elif [[ "$GROUP_ADD" = admin ]] ; then
    SECONDARY_GROUPS="everyone localaccounts admin _lpadmin _appserveradm _appserverusr _appstore _lpoperator _developer" # for an admin user, as of 10.9
else
    echo "You did not make a valid selection!"; exit 1
fi

# Find a UID that is not currently in use
echo "Finding an unused UID for the new user..."


# Find the next available user ID
MAXID=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -ug | tail -1)
USERID=$((MAXID+1))


# Create the user account by running dscl (normally you would have to do each of these commands one
# by one in an obnoxious and time consuming way.)
echo "Creating necessary files..."

dscl . -create /Users/$USERNAME
dscl . -create /Users/$USERNAME UserShell /bin/bash
dscl . -create /Users/$USERNAME RealName "$FULLNAME"
dscl . -create /Users/$USERNAME UniqueID "$USERID"
dscl . -create /Users/$USERNAME PrimaryGroupID 20 # the default group on OS X (staff)
dscl . -create /Users/$USERNAME NFSHomeDirectory /Users/"$USERNAME"
dscl . -passwd /Users/$USERNAME "$PASSWORD"


# Add user to any specified groups
echo "Adding user to specified groups..."

for GROUP in $SECONDARY_GROUPS ; do
    dseditgroup -o edit -t user -a "$USERNAME" "$GROUP"
done

# Create the home directory
echo "Creating home directory..."
createhomedir -c 2>&1 | grep -v "shell-init"

#Set the user's picture

# Found @ https://jamfnation.jamfsoftware.com/discussion.html?id=4332

# Delete the hex entry for jpegphoto
dscl . delete /Users/"$USERNAME" jpegphoto
dscl . delete /Users/"$USERNAME" Picture



if [ "$GROUP_ADD" == "admin" ] ; then
dscl . create /Users/"$USERNAME" Picture "/Library/User Pictures/Animals/Eagle.tif" #set Eagle.tif for admins
 fi

if [ "$GROUP_ADD" == "standard" ] ; then 
    dscl . create /Users/"$USERNAME" Picture "/Library/User Pictures/Fun/Chalk.tif" #set Chalk.tif for standard users
    fi

echo "Created user $USERID: $USERNAME ($FULLNAME)"

done < "$input"

#DISABLE APPLE ID AND ICLOUD SETUP PROMPTS FOR EXISTING ACCTS. 
#FOUND @ http://derflounder.wordpress.com/2013/10/27/disabling-the-icloud-sign-in-pop-up-message-on-lion-and-later/ #rtrouton on github

for USER_HOME in /Users/*
  do
    USER_UID=`basename "${USER_HOME}"`
    if [ ! "${USER_UID}" = "Shared" ] 
    then 
      if [ ! -d "${USER_HOME}"/Library/Preferences ]
      then
        mkdir -p "${USER_HOME}"/Library/Preferences
        chown "${USER_UID}" "${USER_HOME}"/Library
        chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
      fi
      if [ -d "${USER_HOME}"/Library/Preferences ]
      then
        defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool TRUE
        defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
        defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion "${sw_vers}"
        chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant.plist
      fi
    fi
  done

# Kill the local Directory service on OS X 10.5-10.9; Found in MagerValp's CreateUserPkg-1.2.4.dmg by using Pacifist to view the underlying pkg. 

# Kill local directory service, so it will see our file changes -- it will automatically restart
    /usr/bin/killall DirectoryService 2>/dev/null || /usr/bin/killall opendirectoryd 2>/dev/null

#  This forces the system to rebuild the system caches which include the user's login picture
# along with the local directory cache.
kextcache -system-caches
