# mtd (Matrix to DSGVO)

# Setup

install python3 if not already installed: \
`sudo apt install python1`

(setup is missing requirements.txt right now, to install all dependencies)


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



## SQL queries
Best json formatter:  
[jsonformatter](https://jsonformatter.org/)

### Get all event ids from all messages or encrypted messages
```SQL
select event_id from events where type='m.room.message';
select event_id from events where type='m.room.encrypted';
select event_id from events where type='m.room.encrypted' or type='m.room.message';
```


### Get all messages of one user
```SQL
select * from events where type='m.room.<type>' and sender='@<user>:<server>';
select * from events where (type='m.room.message' or type='m.room.encrypted') and sender='@<user>:<server>';

-- Examples:
select * from events where type='m.room.encrypted' and sender='@ralf:matrix.digitalmedcare.de';
select * from events where (type='m.room.message' or type='m.room.encrypted') and sender='@ralf:matrix.digitalmedcare.de';

-- Test server (matrixtest and typo 'digitalmecare'):
select * from events where (type='m.room.message' or type='m.room.encrypted') and sender='@ralf:matrixtest.digitalmecare.de';
```


### Get one the json of one event (which is a message)
```SQL
select * from event_json where event_id = '<event_id>';
select json from event_json where event_id = 'event_id';

-- Example:
select json from event_json where event_id = '$nNftajqqPM7Enz7MvnThzUMKrc_US8UL3pVZ_VYAbV4';
```


###

### Update Message
```SQL
UPDATE event_json
SET
    json = '<json>'
WHERE
    event_id = '<id>';

-- Examples:
UPDATE event_json
SET json = {
  "auth_events": [
    "$tfG1Nt7BR6H4aalXKvzP6M6SHZ0qZUTm6guwxQ4V7EI",
    "$9BYlpymfD2EsEC7fhMegFJyEQ8jlLNEOfIlQO47nMUI",
    "$2ngO4WStxVAoOWES7T6ey7DtEr0L4gBZ1BHveuiQ7Jw"
  ],
  "content": {
    "body": "MESSAGE DELETED",
    "msgtype": "m.text"
  },
  "depth": 556,
  "hashes": {
    "sha256": "Gu/LBpVnzu+oLXiqfxIr4PjPic1gJZ25A/OK5D2LJI4"
  },
  "origin": "matrixtest.digitalmecare.de",
  "origin_server_ts": 1663158369687,
  "prev_events": [
    "$9BYlpymfD2EsEC7fhMegFJyEQ8jlLNEOfIlQO47nMUI"
  ],
  "prev_state": [],
  "room_id": "!JKpcIWvbGjIaNivmds:matrixtest.digitalmecare.de",
  "sender": "@ralf:matrixtest.digitalmecare.de",
  "signatures": {
    "matrixtest.digitalmecare.de": {
      "ed25519:a_OjFb": "1WdxxtrC00R4ZxrcjLJ1oMymDnA8OmhcD2Bn8hyyrKuU5QUHm4jUTlLES4gGu3MPlJ8rgxSF+4U98Udqf3/wAQ"
    }
  },
  "type": "m.room.encrypted",
  "unsigned": {
    "age_ts": 1663158369687
  }
}
WHERE event_id = '$nNftajqqPM7Enz7MvnThzUMKrc_US8UL3pVZ_VYAbV4';
```


### Count Messages
```SQL
select count(sender) from events where sender='@<user>:<server>' and type='m.room.<message type>';

-- Examples:
select count(sender) from events where sender='@aj:matrix.digitalmedcare.de' and type='m.room.encrypted';
select count(sender) from events where sender='@aj:matrix.digitalmedcare.de' and type='m.room.message';
select count(sender) from events where sender='@aj:matrix.digitalmedcare.de' and (type='m.room.encrypted' or type='m.room.message');

-- Test server (matrixtest and typo 'digitalmecare'):
select count(sender) from events where sender='@aj:matrixtest.digitalmecare.de' and (type='m.room.encrypted' or type='m.room.message');
```
