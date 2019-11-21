#!/bin/bash
systemctl list-units --type=service --state=running | grep -e mysql -e apache -e smb -e samba -e cups -e ftp -e ssh -e pop3 -e smbd -e imap -e netbios -e rpcbind -e smtp -e nntp
