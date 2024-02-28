# Copy-Profile
This is intended to actually copy a user's profile from one machine to another.

In my original code I wanted to copy a single user's profile from one computer to another.  I did have another script working to copy multiple users, but this focuses on a single user.

Please use very carefully.  This has the potential to crash.

The code I have provided in both of these scripts was successful at times, but also had their issues.
*** You HAVE to make sure that the user is not logged on.  You MUST beware if the user is logged on to the same PC that this will cause potential issues with the profile and system itself.  In the case you have done this, you will have to run SFC /SCANNOW or a DISM /Online repair command. ***

The copy profile script is designed to do the following on the source computer:
1.  Prompt for the user to copy, source computer, and backup/destination computer
2.  Searches the source computer's C:\Users for the specified user profile folder to copy and copies that profile folder to a back up location
3.  Searches the registry for the user's registry SID and makes a exported .reg file for the user

The restore profile script is designed to do the following on the destination computer:
1.  Prompts for the user that is to be restored, source computer, and backup/destination computer (in case you have an actual backup location to restore from to a destinaton PC)
2.  Searches for that user's profile folder and robocopies it to the destination PC
3.  Creates the user's SID key in the registry
4.  Imports the .reg file to that user's SID key

There are potential issues in which I was trying to work out.  Because throughout the day I am working on other projects, I don't get the chance to keep testing to perfect this.  I am only supplying this in case someone out there may be able to assist with perfecting this code.

The issues always arose from copying the NTUSER.DAT file and other files that may contain a '.lck' file (locked file) in AppData so this is where one must be careful and make a back up of the source PC in case something happens.  The thing that always happened in the worst case scenario was that no one was able to log into the PC after logging off of the computer under the profile that was copied.  This can usually be fixed by running SFC /SCANNOW from a cmd prompt (most likely using a bootable USB media).  Worst case scenario is that the data is on the PC, copy all that you can if needed and try again after a fresh image of the PC (worst case scenario).

I have tested this and it does work.  The only things I know are wrong with it are described above.  You must ensure the user is not logged into the PC, and you must ensure they won't be logging into that machine for the duration of the user profile migration.  My testing has confirmed that indeed, you can actually copy a user's profile into a new machine.  So, instead of the user having to log in for the first time on the new PC, and go through all of the 'Welcome to Windows, we are getting everything ready' sort of thing, the user can simply log into the new PC without having to wait for the initial setup process and have their desktop, application settings, and etc.  This is almost like they were not on a new PC, everything would appear to be like the old PC, so the end user doesn't need to do much at all when it comes to configuring anything and customizing their desktop or PC to their specifications again.
