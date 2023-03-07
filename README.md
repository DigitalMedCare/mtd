# mtd (Matrix to DSGVO)

# How to use

Just type in ./mtd
If you don't give it any parameters, it prompts you the different things you can input.

You can also start it with some parameters.
It's always in the same pattern:

```bash 
python3 [username] --database [path/to/homeserver.db] [matrix adress]
```

for example:
```bash
./mtd mustermann /var/lib/matrix-synapse/homeserver.db
``` 

For the Standard matrix.digitalmedcare.de we use, you can even leave out the last parameter.

# How to install

make sure you have rustc and rustup installed.
Then go into the project folder. 

You can either type in:

```bash 
cargo run 
``` 

or
```bash 
cargo build --release  
```

The first option, only let's you compile and run mtd. So you won't be able to give it any parameters.
It's heavly advised you use the build option. Because then you don't have to recompile the program.
The compiled and build program from cargo build is saved in:

```bash
mtd/target/release
``` 

# What does it actually do?

Basicly, it just sends SQL Querries to the Matrix Server.
In which the JSON Files are changed. In these JSON files are the messages themselves.
The message String gets changed to "Deleted Message". So the message is for no one readable. Even the Server Admins.

With this method, the database just gets updated. Nothing is deleted or removed.

In the next Section, it is explained which SQL Querries are made by mtd.

# SQl Querries

## Copy remote database
```bash
scp root@212.227.190.252:~/synapse/homeserver.db ~/Downloads/homeserver.db
```



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
