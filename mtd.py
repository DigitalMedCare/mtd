import argparse
import yaml
import json
import sqlite3
import sys
from os.path import exists
import time

# purge time
from typing import Any, Set, Tuple, cast
import logging

# from typing import Any, List, Set, Tuple, cast

logger = logging.getLogger(__name__)

# Global object to execute sql queries
db_cursor: sqlite3.Cursor
db_connection: sqlite3.Connection
server: str

# ToDo keep track of what ids are deleted and search dump to make sure
all_collected: list

# ToDo checksum compare before and after user deletion (only changes are by user)
# ToDo search every event iy by user and user name in sql dump


# check if room is created by user then, delete first msg matrix way

def api_test(param: str):
    print("API call")
    return "API does works: " + param


def valid_token(token: str) -> bool:
    user_id: str = select_from("access_tokens", "user_id", f"token={token}")[0]
    return bool(select_from("users", "admin", f"user_id={user_id}")[0])


def select_from(_table: str, _column: str, _condition: str) -> list:
    global db_cursor

    # Build SQL query
    sql_query: str = f"SELECT {_column} FROM {_table} WHERE {_condition};"

    # Execute sql query on database file
    # ToDo what is this?
    #db_cursor.execute("SELECT event_id FROM events WHERE \"type\" in ('m.room.message', 'm.room.encrypted') AND sender='@bobby:matrix.digitalmedcare.de';")
    db_cursor.execute(sql_query)

    # Collect the results table, this is a list of all messages from _user of given type
    result_list: list = db_cursor.fetchall()

    # Todo Debug
    #print(result_list)

    return result_list


def select_message_ids_from(_user: str) -> list:
    global db_cursor
    global server

    message_types = "('m.room.message', 'm.room.encrypted')"  # ToDo what type is really needed?

    # Select all messages from _user or type message_type
    return select_from("events", "event_id", f"\"type\" in {message_types} AND sender='@{_user}:{server}'")


# ToDo this might be obsolete
def select_json_of(_message_id: str) -> dict:
    # Select the event json of current message
    get_msg_json: str = f"SELECT json FROM event_json WHERE event_id = '{_message_id}';"

    # Execute query and collect the json as a dict
    db_cursor.execute(get_msg_json)
    # Pull one result from query and convert the string into a json object with json.loads
    event_json: dict = json.loads(db_cursor.fetchone())

    return event_json


def setup_database(_database: str) -> sqlite3.Connection:
    """ Set up the connection to a database file and return the cursor to execute queries"""
    if not _database.lower().endswith('.db'):
        print(f"File [{_database}] is not a database (not .db)")
        sys.exit()
    elif not exists(_database):
        print(f"File [{_database}] does not exist")
        sys.exit()

    global db_cursor
    global db_connection

    # Create a SQL connection to our SQLite database
    db_connection = sqlite3.connect(_database)

    # To turning returned tuples to values, redefine the row_factory function
    db_connection.row_factory = lambda cursor, row: row[0]

    # creating cursor
    db_cursor = db_connection.cursor()

    return db_connection


def delete_room_events(_user_id: str):
    print("\n\nDeleting user events")

    for event_id in select_from("room_memberships", "event_id", f"sender='{_user_id}'"):
        delete_event(event_id)
    #db_cursor.execute(f"DELETE FROM room_memberships WHERE sender='{_user_id}';")

    #print(select_from("room_memberships", "event_id, room_id", f"sender='{_user_id}'"))


def delete_event(_event_id: str):
    db_cursor.execute(f"DELETE FROM event_json WHERE event_id='{_event_id}';")
    db_cursor.execute(f"DELETE FROM current_state_events WHERE event_id='{_event_id}';")
    db_cursor.execute(f"DELETE FROM event_to_state_groups WHERE event_id='{_event_id}';")
    db_cursor.execute(f"DELETE FROM stream_ordering_to_exterm WHERE event_id='{_event_id}';")
    db_cursor.execute(f"DELETE FROM event_auth WHERE event_id='{_event_id}';")
    db_cursor.execute(f"DELETE FROM event_auth_chains WHERE event_id='{_event_id}';")
    db_cursor.execute(f"DELETE FROM event_edges WHERE event_id='{_event_id}';")
    db_cursor.execute(f"DELETE FROM state_groups WHERE event_id='{_event_id}';")
    db_cursor.execute(f"DELETE FROM state_groups_state WHERE event_id='{_event_id}';")
    db_cursor.execute(f"DELETE FROM event_json WHERE event_id='{_event_id}';")


def delete_user(user: str) -> None:
    global server
    user_id: str = f"@{user}:{server}"

    message_id_list: list = select_message_ids_from(user)

    # From a github discussion
    db_cursor.execute(f"DELETE FROM users WHERE name='{user_id}';")
    db_cursor.execute(f"DELETE FROM user_directory WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM account_data WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM profiles WHERE user_id='{user}';")
    db_cursor.execute(f"DELETE FROM user_external_ids WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM user_external_ids WHERE user_id='{user}';")

    # Experimental
    db_cursor.execute(f"DELETE FROM user_ips WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM presence_stream WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM device_lists_stream WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM user_directory_search_content WHERE c0user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM devices WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM e2e_cross_signing_keys WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM e2e_cross_signing_signatures WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM user_signature_stream WHERE from_user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM user_stats_current WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM user_filters WHERE user_id='{user}';")
    db_cursor.execute("DELETE FROM ui_auth_sessions WHERE serverdict='{\"request_user_id\":\"" + user_id + "\"}';")
    db_cursor.execute(f"DELETE FROM ui_auth_sessions_credentials WHERE result='{user_id}';")
    db_cursor.execute(f"DELETE FROM access_tokens WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM e2e_one_time_keys_json WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM current_state_delta_stream WHERE state_key='{user_id}';")
    db_cursor.execute(f"DELETE FROM e2e_room_keys WHERE user_id='{user_id}';")

    # Room events
    db_cursor.execute(f"DELETE FROM state_events WHERE state_key='{user_id}';")

    # Other?
    db_cursor.execute(f"DELETE FROM events WHERE sender='{user_id}';")
    # db_cursor.execute(f"DELETE FROM event_json WHERE sender='{user_id}';")

    for message_id in message_id_list:
        delete_message(message_id)

    with open('del_test.sql', 'r') as f:
        read_data = f.read()
    for id in message_id_list:
        if id in read_data:
            print("True, ", id)

    delete_room_events(user_id)


def delete_message(id: str) -> None:
    # Execute sql query on database file
    db_cursor.execute(f"DELETE FROM events WHERE event_id='{id}';")
    db_cursor.execute(f"DELETE FROM event_json WHERE event_id='{id}';")
    db_cursor.execute(f"DELETE FROM event_forward_extremities WHERE event_id='{id}';")
    db_cursor.execute(f"DELETE FROM event_to_state_groups WHERE event_id='{id}';")
    db_cursor.execute("DELETE FROM room_account_data WHERE content='{\"event_id\":\"" + id + "\"}';")
    db_cursor.execute(f"DELETE FROM stream_ordering_to_exterm WHERE event_id='{id}';")
    db_cursor.execute(f"DELETE FROM event_edges WHERE event_id='{id}';")
    db_cursor.execute(f"DELETE FROM event_search_content WHERE c0event_id='{id}';")


def main():
    print("Main")
    # Instantiate the parser
    parser = argparse.ArgumentParser(
        description='A script to alter all messages of a matrix user in the database.'
    )

    # Required argument, user name
    parser.add_argument('username', type=str,
                        help='The name of the user to be deleted')

    # Optional argument, database path
    # ToDo check for default paths, then prompt? maybe only need db file?
    parser.add_argument('config', type=str,
                        help='To get all necessary information like server domain and signing key you have to provide '
                             'the .yaml file.')

    # Parse arguments
    args = parser.parse_args()

    # Measure run time
    start_time = time.time()

    # Read the YAML file
    with open(args.config, "r") as stream:
        try:
            config: dict = yaml.safe_load(stream)
            # ToDo hoe do they go about? Also hard coded structure?
            _db: str = config['database']['args']['database']
            _server: str = config['server_name']
            #print(_db)
            #print(_server)
        except yaml.YAMLError as exc:
            print(exc)

    global db_connection
    db_connection = setup_database(_db)
    global server
    server = _server

    # Main body
    delete_user(args.username)
    # _purge_history_txn("!OuwzcoSSRFQqnjXlYK:matrix.digitalmedcare.de", "syt_YWRtaW4_WSzXELBHTWvOkzZeWxtN_3GkVMI", )

    # Write changes to database
    db_connection.commit()

    # Print info
    print(f"Deleting [{args.username}] from [{_db}] at [{_server}]")

    # Close the connection
    db_connection.close()

    # Measure run time
    execution_time = (time.time() - start_time)
    print('Execution time in seconds: ' + str(execution_time))
# ToDo performance measurement and counting in debug mode (also count outside of performance test)


if __name__ == "__main__":
    main()
