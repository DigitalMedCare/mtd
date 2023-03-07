import argparse
import yaml
import json
import re
import sqlite3
import sys

# from canonicaljson import encode_canonical_json
import signedjson.key
import signedjson.types
from hashlib import sha256
import base64
import copy
from os.path import exists


# Global object to execute sql queries
db_cursor: sqlite3.Cursor


def json_key_match(regex: str, json_obj: dict) -> str:
    for element in json_obj:
        res = re.match(regex, element)
        if res:
            return element
    return ""


def json_get_signature(json_obj: dict) -> str:
    server: str = json_key_match(r"^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$",
                                 json_obj['signatures'])
    key_id: str = json_key_match(r"[a-zA-Z0-9]*:.*", json_obj['signatures'][server])

    signature: str = json_obj['signatures'][server][key_id]

    return signature


def canonical_json_string(json_object: dict) -> str:
    # Copy object, to prevent changes on original object
    json_object = json_object.copy()

    # Keys under "unsigned" can be modified by other servers.
    # They are useful for conveying information like the age of an
    # event that will change in transit.
    # Since they can be modified we need to exclude them from the hash.
    json_object.pop("unsigned", None)

    # Signatures will depend on the current value of the "hashes" key.
    # We cannot add new hashes without invalidating existing signatures.
    json_object.pop("signatures", None)

    # The "hashes" key might contain multiple algorithms if we decide to
    # migrate away from SHA-2. We don't want to include an existing hash
    # output in our hash, so we exclude the "hashes" dict from the hash.
    json_object.pop("hashes", None)

    # Other stuff to delete
    json_object.pop("age_ts", None)
    json_object.pop("outlier", None)
    json_object.pop("destinations", None)

    # Sort keys and also dump json as string
    return json.dumps(
        json_object,
        # Encode code-points outside of ASCII as UTF-8 rather than \u escapes
        ensure_ascii=False,
        # Remove unnecessary white space.
        separators=(',', ':'),
        # Sort the keys of dictionaries.
        sort_keys=True,
        # Encode the resulting Unicode as UTF-8 bytes.
    )


def encode_canonical_json(value: object) -> bytes:
    return json.dumps(
        value,
        # Encode code-points outside of ASCII as UTF-8 rather than \u escapes
        ensure_ascii=False,
        # Remove unecessary white space.
        separators=(",", ":"),
        # Sort the keys of dictionaries.
        sort_keys=True,
        # Encode the resulting unicode as UTF-8 bytes.
    ).encode("UTF-8")


def compute_content_hash(json_object: dict) -> bytes:
    # Convert json to canonical form as string
    json_canonical: str = canonical_json_string(json_object)

    # Encode string in UTF-8 bytes
    event_json_bytes: bytes = json_canonical.encode("UTF-8")

    # Generate a hash for the given json object
    hash_object: hash = sha256(event_json_bytes)

    # digest() returns hmac (Keyed-Hashing for Message Authentication) value as bytes
    return hash_object.digest()


def encode_unpadded_base64(data: bytes):
    return base64.b64encode(data).decode("UTF-8").replace('=', '')


# ToDo is this even needed?
def encode_base64(input_bytes: bytes) -> str:
    """Encode bytes as a base64 string without any padding."""

    input_len = len(input_bytes)
    output_len = 4 * ((input_len + 2) // 3) + (input_len + 2) % 3 - 2
    output_bytes = base64.b64encode(input_bytes)
    output_string = output_bytes[:output_len].decode("ascii")
    return output_string


# ToDo for some reason it does not generate the same signature
def sign_json(json_object: dict, signing_key: signedjson.types.SigningKey, signing_name: str) -> dict:
    # Make a copy of the original json
    json_object: dict = copy.deepcopy(json_object)
    # Delete real content
    #new_json['content']['body'] = "Deleted"

    #key_file = open("example.key", "r")
    #key_file = open("homeserver.signing.key", "r")
    #base_key = signedjson.key.read_signing_keys(key_file)[0]

    #new_json = sign_json(new_json, base_key, "matrix.digitalmedcare.de")

    #server: str = json_key_match(r"^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$", new_json['signatures'])
    #key_id: str = json_key_match(r"[a-zA-Z0-9]*:.*", new_json['signatures'][server])
    #my_sign = json_get_signature(new_json)

    #print("my signature: ", my_sign)
    #print("same? ", my_sign == real_sign)
    #new_json['signatures'][server][key_id] = my_sign

    #print(real_json)
    #print(new_json)

    #json_file.close()


    # Following code is from the matrix spec
    signatures = json_object.pop("signatures", {})
    unsigned = json_object.pop("unsigned", None)

    signed = signing_key.sign(encode_canonical_json(json_object))
    signature_base64 = encode_base64(signed.signature)

    key_id = "%s:%s" % (signing_key.alg, signing_key.version)
    signatures.setdefault(signing_name, {})[key_id] = signature_base64

    json_object["signatures"] = signatures
    if unsigned is not None:
        json_object["unsigned"] = unsigned

    return json_object


def hash_json(json_object: dict) -> dict:
    new_json: dict = json_object.copy()
    hash_value: str = hash_of_json(json_object)
    # ToDo do like in the spec
    new_json["hashes"] = {"sha256": hash_value}
    return new_json


def hash_of_json(json_object: dict) -> str:
    return encode_unpadded_base64(compute_content_hash(json_object))


def print_all_message_types(_user: str, _database: str):
    db_connection = sqlite3.connect(_database)
    db_connection.row_factory = lambda cursor, row: row[0]
    cur = db_connection.cursor()

    server_domain = "matrix.digitalmedcare.de"  # Todo use like rust version

    # Select all messages types
    select_message = f"SELECT DISTINCT type FROM events WHERE sender='@{_user}:{server_domain}';"
    cur.execute(select_message)
    message_types = cur.fetchall()
    db_connection.close()

    print("\n---------- Message types -----------")
    for message_id in message_types:
        print(message_id)
    print("------------------------------------")


def select_message_ids_from(_user: str) -> list:
    global db_cursor

    message_type = "m.room.message"  # ToDo what type is really needed?
    server_domain = "matrix.digitalmedcare.de"  # Todo use like rust version

    # Select all messages from _user or type message_type
    select_message = f"SELECT event_id FROM events WHERE type='{message_type}' AND sender='@{_user}:{server_domain}';"

    # Execute sql query on database file
    db_cursor.execute(select_message)
    # Collect the results table, this is a list of all messages from _user of given type
    message_id_list = db_cursor.fetchall()

    return message_id_list


def select_json_of(_message_id: str) -> dict:
    # Select the event json of current message
    get_msg_json: str = f"SELECT json FROM event_json WHERE event_id = '{_message_id}';"

    # Execute query and collect the json as a dict
    db_cursor.execute(get_msg_json)
    # Pull one result from query and convert the string into a json object with json.loads
    event_json: dict = json.loads(db_cursor.fetchone())

    return event_json


def test_on(user: str, _signing_key: signedjson.types.SigningKey, _verbose: bool = False):
    print("Testing on database")
    print("User:     ", user)

    message_id_list: list = select_message_ids_from(user)

    hash_results: dict = {}
    sign_results: dict = {}
    json_results: dict = {}
    for message_id in message_id_list:
        message_json: dict = select_json_of(message_id)
        new_json: dict = message_json.copy()
        # ToDo derive from key like in the spec
        real_hash = message_json['hashes']['sha256']
        calc_hash = hash_of_json(new_json)

        # ToDo extract signing name from config like in spec
        signing_name: str = "matrix.digitalmedcare.de"
        real_sign = json_get_signature(message_json)
        calc_sign = json_get_signature(sign_json(message_json, _signing_key, signing_name))
        new_json = hash_json(new_json)
        new_json = sign_json(new_json, _signing_key, signing_name)

        hash_results[message_id] = real_hash == calc_hash
        sign_results[message_id] = real_sign == calc_sign
        json_results[message_id] = message_json == new_json

        # Verbose output
        if _verbose:
            print(f"{message_id}")
            print("  real hash: ", real_hash)
            print("  calc hash: ", calc_hash)
            print(f"  -> {calc_hash == real_hash}")
            print("  real sign: ", real_sign)
            print("  calc sign: ", calc_sign)
            print(f"  -> {calc_sign == real_sign}")
            print("Raw json: ", message_json)
            print("New json: ", new_json)
            print("\n")

    # Print results
    print("_______________________________________________________________________")
    total: int = len(hash_results)
    correct_hashes = list(hash_results.values()).count(True)
    correct_signs = list(sign_results.values()).count(True)
    correct_jsons = list(json_results.values()).count(True)
    print(f"{total} messages checked")
    print("        | success rate | failed |")
    print("hashing | {:^12.2%} | {:^6} |".format(correct_hashes/total, list(hash_results.values()).count(False)))
    print("signing | {:^12.2%} | {:^6} |".format(correct_signs/total, list(sign_results.values()).count(False)))
    print("overall | {:^12.2%} | {:^6} |".format(correct_jsons/total, list(json_results.values()).count(False)))
    # print(f"{round(correct_hashes/total * 100, 3)}% is correct.")
    # print(f"{list(hash_results.values()).count(False)} failed.")


def setup_database(_database: str) -> sqlite3.Connection:
    """ Set up the connection to a database file and return the cursor to execute queries"""
    if not _database.lower().endswith('.db'):
        # ToDo proper check of filetype
        print(f"File [{_database}] is not a database (not .db)")
        sys.exit()
    elif not exists(_database):
        print(f"File [{_database}] does not exist")
        sys.exit()

    global db_cursor

    # Create a SQL connection to our SQLite database
    db_connection: sqlite3.Connection = sqlite3.connect(_database)

    # To turning returned tuples to values, redefine the row_factory function
    db_connection.row_factory = lambda cursor, row: row[0]

    # creating cursor
    db_cursor = db_connection.cursor()

    return db_connection


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

    # Access
    print(args.username)

    # Read the YAML file
    with open(args.config, "r") as stream:
        try:
            config: dict = yaml.safe_load(stream)
            print(config['database']['args']['database'])
            print(config['signing_key_path'])
        except yaml.YAMLError as exc:
            print(exc)

    sys.exit()

    # parameter
    _db: str = "homeserver.db"
    #_key: str = "modexample.key"
    #_key: str = "example.key"
    _key: str = "homeserver.signing.key"

    db_connection = setup_database(_db)

    _user: str = "bobby"
    _key_file = open(_key, "r")
    base_key = signedjson.key.read_signing_keys(_key_file)[0]

    # Hash all
    test_on(_user, base_key, True)

    # Debug stuff
    #print_all_message_types(_user, _database)

    # Close the connection
    db_connection.close()


if __name__ == "__main__":
    main()
