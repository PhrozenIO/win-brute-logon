# Win Brute Logon (Proof Of Concept)

Release date : `2020-05-14`

## Briefly

I was doing some research about some specific API's for a huge InfoSec project I'm working on (It will be release very soon) when I found something unbelievable.

You can call `LogonUserW` API with wrong user information any time you want without any restriction / lockdown or special privilege.

This means that even from a Guest account, the most restricted Windows User Account, you can crack any user password in just few minutes (depending on the complexity of the password and number of available cores)

It is not what we could call a vulnerability but more a serious weakness in user authentication. 

I hope to see Microsoft implementing a security lockdown and slow the process of authentication using those API's.

A use case, whould be during your PenTest, after gaining access to a low priv user escalating your privileges.

## Information

Tested on Windows 10 latest version 64bit/32bit - (1909 - Build 18363.778).
Tested on Windows 7 latest version 64bit/32bit.

Will surely work on any previous Windows Versions.

The PoC is multithreaded to speed up the process, I will probably improve that part in a near future.

I used a very low performance VM (2 Cores) for the test, I successfully cracked the password in just few seconds. You can find the video in my Twitter account : @DarkCoderSc

I also tried on a slitly better machine (4 core) Intel core i3 NUC and I was able to test arround 10 000 passwords / sec which is incredible. 

You will find in the repository both compiled version for 32 and 64bit.

You will need Delphi (Free version or not) to compile yourself the program.

![Console](https://i.ibb.co/Cm5052S/screen.png)

# Mitigation

- Disable guest account if it is not absolutely required.
- Follow the rules to create a complex password and apply to all accounts.
- Implement lockdown mechanisms for user authentication.

Microsoft was alterted. 
