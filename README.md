# mtd (Matrix to DSGVO)

# Setup

* Install python3 on debian 11 its preinstalled if not already installed. \
* Install pip3: \
`sudo apt install python3-pip`
* Install required packages: \
`pip3 install -r requirements.txt`


# How to use

Python3 is necessary, but since matrix runs on it, it should already be installed.

You call the script via python and give two positional parameters. The user you want to delete and the path to the config file.
```bash
python3 mtd.py [username] [path/to/homeserver.yaml]
```

for example:
```bash
./mtd mustermann /etc/matrix-synapse/homeserver.yaml
```


# What does it actually do?

Every message of a user gets removed from the database entirely. This action can't be undone.
It also removes any occurrence of the username. \
Right now it does not remove every trace of every message, but it also does not cause any inconsistencies.
