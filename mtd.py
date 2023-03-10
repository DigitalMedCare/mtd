import argparse
import yaml
import json
import sqlite3
import sys
from os.path import exists


# Global object to execute sql queries
db_cursor: sqlite3.Cursor
db_connection: sqlite3.Connection
server: str

# ToDo keep track of what ids are deleted and search dump to make sure
all_collected: list


def select_from(_table: str, _column: str, _condition: str) -> list:
    global db_cursor

    # Build SQL query
    sql_query: str = f"SELECT {_column} FROM {_table} WHERE {_condition};"

    # Execute sql query on database file
    db_cursor.execute(sql_query)
    # Collect the results table, this is a list of all messages from _user of given type
    result_list: list = db_cursor.fetchall()

    return result_list


def select_message_ids_from(_user: str) -> list:
    global db_cursor
    global server

    message_type = "m.room.message"  # ToDo what type is really needed?

    # Select all messages from _user or type message_type
    return select_from("events", "event_id", f"type='{message_type}' AND sender='@{_user}:{server}'")


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


def delete_room_events(_user: str):
    user_id = f"@{_user}:{server}"

    print(select_from("room_memberships", "event_id, room_id", f"user_id='{user_id}'"))


def delete_user(user: str) -> None:
    global server
    user_id: str = f"@{user}:{server}"

    db_cursor.execute(f"DELETE FROM users WHERE name='{user_id}';")
    db_cursor.execute(f"DELETE FROM user_directory WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM account_data WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM profiles WHERE user_id='{user}';")
    db_cursor.execute(f"DELETE FROM user_external_ids WHERE user_id='{user_id}';")
    db_cursor.execute(f"DELETE FROM user_external_ids WHERE user_id='{user}';")

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

    db_cursor.execute(f"DELETE FROM events WHERE sender='{user_id}';")
    #db_cursor.execute(f"DELETE FROM event_json WHERE sender='{user_id}';")

    message_id_list: list = select_message_ids_from(user)

    for message_id in message_id_list:
        delete_message(message_id)


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
    parser.add_argument('config', type=str,
                        help='To get all necessary information like server domain and signing key you have to provide '
                             'the .yaml file.')

    # Parse arguments
    args = parser.parse_args()

    # Read the YAML file
    with open(args.config, "r") as stream:
        try:
            config: dict = yaml.safe_load(stream)
            _db: str = config['database']['args']['database']
            _server: str = config['server_name']
            print(_db)
            print(_server)
        except yaml.YAMLError as exc:
            print(exc)

    global db_connection
    db_connection = setup_database(_db)
    global server
    server = _server

    # Main body
    # delete_user(args.username)
    delete_room_events(args.username)

    # Write changes to database
    db_connection.commit()

    # Close the connection
    db_connection.close()


if __name__ == "__main__":
    main()
