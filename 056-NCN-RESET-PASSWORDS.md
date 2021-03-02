# Change the root password

The NCNs deploy with a default password.  It is recommended to change that password before continuing.  In addition, this step will also generate ssh keys, which can be used for a more secure login to NCNs.

> **`NOTE`** This is a work-around for applying a new password. There will be a procedure for setting this in the
> image before booting NCNs - or for booting new NCNs.

# Using an SSH key

It is recommended to set the new password by using an SSH key.  This prevents you from having to enter the password for each NCN that you log into.  You have three path for this approach:

1. Use an existing keypair that is already setup on the NCNs (recommended)
2. Generate a new keypair on the PIT
3. Use an existing key

## Use an existing keypair that is already setup on the NCNs (recommended)

From the PIT, log into any NCN using SSH.  The NCNs are already setup with passwordless SSH, so you can quickly change the password using this method.

> If you have more than 9 NCNs, you should add those hostnames into the `for` loops below.

```
ncn-m002# for i in m003 w001 w002 w003 s001 s002 s003
do
ssh -t ncn-$i "passwd"
done
```

Follow the prompts to set your a new password.

## Generate a new keypair on the PIT

First, generate a new keypair from the LiveCD.  

```bash
ssh-keygen -t rsa -b 4098
```

If a key already exists, you could use that one.  In that case, just choose `N` at this message:

```
eniac-ncn-m001# ssh-keygen -t rsa -b 4098
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):
/root/.ssh/id_rsa already exists.
Overwrite (y/n)? n
```

Otherwise the output appears like this:

```
eniac-ncn-m001# ssh-keygen -t rsa -b 4098
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_rsa-root.
Your public key has been saved in /root/.ssh/id_rsa-root.pub.
The key fingerprint is:
SHA256:/BumqEZEQ/SECOv4MCfny4zT5OC6fqHwTkbKkNKJ94s root@ncn-m001
The key's randomart image is:
+---[RSA 4098]----+
|.. +o..          |
| .. +o           |
|.  . ..          |
|o+ ..  .         |
|X.B.    S        |
|*%.o.    .       |
|+B*.o     +      |
|.O++.. . o o     |
|*=E.o.. . .      |
```

Copy this key to every NCN:

> If you have more than 9 NCNs, you should add those hostnames into the `for` loops below.

```bash
for i in m002 m003 w001 w002 w003 s001 s002 s003
do
ssh-copy-id ncn-$i
done
```

> This is a tedious process of entering the password every time, but you will gain the ability to log in to each NCN _without_ a password.

Once that is done, you can log in to each NCN _without_ a password, and reset it to whatever you want using the `passwd` command.

> If you have more than 9 NCNs, you should add those hostnames into the `for` loops below.

```bash
for i in m002 m003 w001 w002 w003 s001 s002 s003
do
ssh -t ncn-$i "passwd"
done
```

From here on out, you'll be able to log in to the NCNs from the LiveCD without the need for a password.

## Use an existing key

You can follow the same method as above for generating a new keypair, but instead of generating a new one, copy your existing key to the PIT and use the instructions above starting with the `ssh-copy-id` command.
