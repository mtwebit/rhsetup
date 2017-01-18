# rhsetup
This is a collection of small utilities to customize a minimal RH-based Linux install and to install additional software.

## Howto use
Install the OS using the minimal install ISO.  
Don't install any other apps. You are building a server. No GUI, no junk, only the necessary packages. (You can install them later if you wish.)  
Ensure that networking is up and working.  
Optionally copy your SSH/RSA key and use public key authentication:  
<code>user@client:~$ ssh-copy-id root@server.domain</code>  
Log in as root and issue the following command:  
<code>bash &lt;(curl -Ls https://raw.githubusercontent.com/mtwebit/rhsetup/master/rh-setup)</code>  
Follow the instructions :)

## Main features
* Installs popular package repos (EPEL, REMI etc.)  
* Offers easy installation and semi-automatic cusomization of several applications and utilities like cloud storage, webmail, Shibboleth, iSCSI, inotify, etc. (see below)  
* Provides a detailed list of TODOs and recommendations based on the installed applications  
* It has a modular, easy-to-extend architecture to roll your own app setup scripts  
* Everything will work with SELinux set to enforced.  
* Offers many security-related settings and tips to harden your setup  

## What's included
See the various branches of this repo.
