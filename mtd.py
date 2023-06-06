import argparse
import asyncio

import yaml
import json
import sqlite3
import sys
from os.path import exists
import time

# purge imports
from typing import Any, Set, Tuple, cast, Optional
import logging
import requests
import attr
from frozendict import frozendict


logger = logging.getLogger(__name__)


# ToDo: Work in progress, the matrix way
@attr.s(frozen=True, slots=True, auto_attribs=True)
class RoomStreamToken:
    """Tokens are positions between events. The token "s1" comes after event 1.

            s0    s1
            |     |
        [0] ▼ [1] ▼ [2]

    Tokens can either be a point in the live event stream or a cursor going
    through historic events.

    When traversing the live event stream, events are ordered by
    `stream_ordering` (when they arrived at the homeserver).

    When traversing historic events, events are first ordered by their `depth`
    (`topological_ordering` in the event graph) and tie-broken by
    `stream_ordering` (when the event arrived at the homeserver).

    If you're looking for more info about what a token with all of the
    underscores means, ex.
    `s2633508_17_338_6732159_1082514_541479_274711_265584_1`, see the docstring
    for `StreamToken` below.

    ---

    Live tokens start with an "s" followed by the `stream_ordering` of the event
    that comes before the position of the token. Said another way:
    `stream_ordering` uniquely identifies a persisted event. The live token
    means "the position just after the event identified by `stream_ordering`".
    An example token is:

        s2633508

    ---

    Historic tokens start with a "t" followed by the `depth`
    (`topological_ordering` in the event graph) of the event that comes before
    the position of the token, followed by "-", followed by the
    `stream_ordering` of the event that comes before the position of the token.
    An example token is:

        t426-2633508

    ---

    There is also a third mode for live tokens where the token starts with "m",
    which is sometimes used when using sharded event persisters. In this case
    the events stream is considered to be a set of streams (one for each writer)
    and the token encodes the vector clock of positions of each writer in their
    respective streams.

    The format of the token in such case is an initial integer min position,
    followed by the mapping of instance ID to position separated by '.' and '~':

        m{min_pos}~{writer1}.{pos1}~{writer2}.{pos2}. ...

    The `min_pos` corresponds to the minimum position all writers have persisted
    up to, and then only writers that are ahead of that position need to be
    encoded. An example token is:

        m56~2.58~3.59

    Which corresponds to a set of three (or more writers) where instances 2 and
    3 (these are instance IDs that can be looked up in the DB to fetch the more
    commonly used instance names) are at positions 58 and 59 respectively, and
    all other instances are at position 56.

    Note: The `RoomStreamToken` cannot have both a topological part and an
    instance map.

    ---

    For caching purposes, `RoomStreamToken`s and by extension, all their
    attributes, must be hashable.
    """

    topological: Optional[int] = attr.ib(
        validator=attr.validators.optional(attr.validators.instance_of(int)),
    )
    stream: int = attr.ib(validator=attr.validators.instance_of(int))

    instance_map: "frozendict[str, int]" = attr.ib(
        factory=frozendict,
        validator=attr.validators.deep_mapping(
            key_validator=attr.validators.instance_of(str),
            value_validator=attr.validators.instance_of(int),
            mapping_validator=attr.validators.instance_of(frozendict),
        ),
    )

    def __attrs_post_init__(self) -> None:
        """Validates that both `topological` and `instance_map` aren't set."""

        if self.instance_map and self.topological:
            raise ValueError(
                "Cannot set both 'topological' and 'instance_map' on 'RoomStreamToken'."
            )

    @classmethod
    async def parse(cls, store: "PurgeEventsStore", string: str) -> "RoomStreamToken":
        try:
            if string[0] == "s":
                return cls(topological=None, stream=int(string[1:]))
            if string[0] == "t":
                parts = string[1:].split("-", 1)
                return cls(topological=int(parts[0]), stream=int(parts[1]))
            if string[0] == "m":
                parts = string[1:].split("~")
                stream = int(parts[0])

                instance_map = {}
                for part in parts[1:]:
                    key, value = part.split(".")
                    instance_id = int(key)
                    pos = int(value)

                    instance_name = await store.get_name_from_instance_id(instance_id)  # type: ignore[attr-defined]
                    instance_map[instance_name] = pos

                return cls(
                    topological=None,
                    stream=stream,
                    instance_map=frozendict(instance_map),
                )
        except RuntimeError:
            raise
        except Exception:
            pass
        raise RuntimeError(400, "Invalid room stream token %r" % (string,))

    @classmethod
    def parse_stream_token(cls, string: str) -> "RoomStreamToken":
        try:
            if string[0] == "s":
                return cls(topological=None, stream=int(string[1:]))
        except Exception:
            pass
        raise RuntimeError(400, "Invalid room stream token %r" % (string,))

    def copy_and_advance(self, other: "RoomStreamToken") -> "RoomStreamToken":
        """Return a new token such that if an event is after both this token and
        the other token, then its after the returned token too.
        """

        if self.topological or other.topological:
            raise Exception("Can't advance topological tokens")

        max_stream = max(self.stream, other.stream)

        instance_map = {
            instance: max(
                self.instance_map.get(instance, self.stream),
                other.instance_map.get(instance, other.stream),
            )
            for instance in set(self.instance_map).union(other.instance_map)
        }

        return RoomStreamToken(None, max_stream, frozendict(instance_map))

    def as_historical_tuple(self) -> Tuple[int, int]:
        """Returns a tuple of `(topological, stream)` for historical tokens.

        Raises if not an historical token (i.e. doesn't have a topological part).
        """
        if self.topological is None:
            raise Exception(
                "Cannot call `RoomStreamToken.as_historical_tuple` on live token"
            )

        return self.topological, self.stream

    def get_stream_pos_for_instance(self, instance_name: str) -> int:
        """Get the stream position that the given writer was at at this token.

        This only makes sense for "live" tokens that may have a vector clock
        component, and so asserts that this is a "live" token.
        """
        assert self.topological is None

        # If we don't have an entry for the instance we can assume that it was
        # at `self.stream`.
        return self.instance_map.get(instance_name, self.stream)

    def get_max_stream_pos(self) -> int:
        """Get the maximum stream position referenced in this token.

        The corresponding "min" position is, by definition just `self.stream`.

        This is used to handle tokens that have non-empty `instance_map`, and so
        reference stream positions after the `self.stream` position.
        """
        return max(self.instance_map.values(), default=self.stream)

    async def to_string(self, store: "DataStore") -> str:
        if self.topological is not None:
            return "t%d-%d" % (self.topological, self.stream)
        elif self.instance_map:
            entries = []
            for name, pos in self.instance_map.items():
                instance_id = await store.get_id_for_instance(name)
                entries.append(f"{instance_id}.{pos}")

            encoded_map = "~".join(entries)
            return f"m{self.stream}~{encoded_map}"
        else:
            return "s%d" % (self.stream,)


# ToDo this might be obsolete
def select_json_of(self, _message_id: str) -> dict:
    # Select the event json of current message
    get_msg_json: str = f"SELECT json FROM event_json WHERE event_id = '{_message_id}';"

    # Execute query and collect the json as a dict
    self.db_cursor.execute(get_msg_json)
    # Pull one result from query and convert the string into a json object with json.loads
    event_json: dict = json.loads(self.db_cursor.fetchone())

    return event_json


class MtD:
    # Object to manage the connection and execute sql queries
    db_cursor: sqlite3.Cursor
    db_connection: sqlite3.Connection
    server: str
    admin_token: str

    def __init__(self, _config: str):
        # Read the YAML file
        with open(_config, "r") as stream:
            try:
                config: dict = yaml.safe_load(stream)
                # ToDo how do they (matrix) go about? Also hard coded structure?
                _db: str = config['database']['args']['database']
                self.server = config['server_name']
                # print(_db)
                # print(_server)
            except yaml.YAMLError as exc:
                print(exc)

        self.db_connection = self.setup_database(_db)

        # load the admin token
        with open('admin.token') as f:
            first_line = f.readline()
        self.admin_token = first_line

    # ToDo/Debug: keep track of what ids are deleted and search dump to make sure
    all_collected: list

    # ToDo checksum compare before and after user deletion (only changes are by user)
    # ToDo search every event id by user and user name in sql dump

    # check if room is created by user then, delete first msg matrix way

    def api_test(self, param: str):
        print("API call")
        return "API does works: " + param

    def is_admin(self, _token: str) -> bool:
        sql_query: str = f"SELECT user_id FROM access_tokens WHERE token='{_token}';"
        self.db_cursor.execute(sql_query)
        user_id: str = self.db_cursor.fetchone()

        sql_query = f"SELECT admin FROM users WHERE name='{user_id}';"
        self.db_cursor.execute(sql_query)

        return self.db_cursor.fetchone()

    def select_from(self, _table: str, _column: str, _condition: str = None) -> list:
        """A custom methode to execute sql queries on the database.

        To make it simpler to execute common select statements, just provide, the _table, the _column and an optional
        _condition. You can use multiple columns but only the first one will be used, since its configured that way
        in setup_database.

        Parameters
        ----------
        _table : str
            The table from which to select.

        _column : str
            The column or a list of columns to select from, though only the first will be used.

        _condition : str, optional
            You can also provide a condition to select only some entries.
        """
        # Build SQL query
        if _condition:
            sql_query: str = f"SELECT {_column} FROM {_table} WHERE {_condition};"
        else:
            sql_query: str = f"SELECT {_column} FROM {_table};"

        # Execute sql query on database file
        self.db_cursor.execute(sql_query)

        # Collect the results table, this is a list of all messages from _user of given type
        result_list: list = self.db_cursor.fetchall()

        return result_list

    def delete_from(self):
        # ToDo
        return

    def get_token(self, _user_id: str) -> str:
        # ToDo does it matter that every device has a token?
        # And do I get if from the request?
        self.db_cursor.execute(f"SELECT token FROM access_tokens WHERE user_id='{_user_id}' LIMIT 1;")
        return self.db_cursor.fetchone()

    def valid_token(self, _token: str) -> bool:
        return bool(self.is_admin(_token))

    def select_message_ids_from(self, _user: str) -> list:
        message_types = "('m.room.message', 'm.room.encrypted')"  # ToDo what type is really needed?

        # Select all messages from _user or type message_type
        return self.select_from("events", "event_id", f"\"type\" in {message_types} AND sender='@{_user}:{self.server}'")

    def setup_database(self, _database: str) -> sqlite3.Connection:
        """ Set up the connection to a database file and return the cursor to execute queries"""
        if not _database.lower().endswith('.db'):
            print(f"File [{_database}] is not a database (not .db)")
            sys.exit()
        elif not exists(_database):
            print(f"File [{_database}] does not exist")
            sys.exit()

        # Create a SQL connection to our SQLite database
        self.db_connection = sqlite3.connect(_database)

        # To turning returned tuples to values, redefine the row_factory function
        self.db_connection.row_factory = lambda cursor, row: row[0]

        # creating cursor
        self.db_cursor = self.db_connection.cursor()

        return self.db_connection

    def purge_first_message(self, room_id: str):
        # find 4th message to delete to (exclusive)
        events = self.select_from("events", "event_id", f"room_id = '{room_id}' ORDER BY "
                                        "received_ts ASC LIMIT 4")

        # API call
        url = f"http://127.0.0.1:8008/_synapse/admin/v1/purge_history/{room_id}/{events[-1]}"
        headers = {'Authorization': 'Bearer ' + self.admin_token}
        print(url)

        # Debug
        # give time to execute purge (late obsolete, if not wait for response to be done)
        # time.sleep(10)
        #response = requests.post(url, headers=headers)
        #print(response.status_code)
        #print(response)
        #print(response.json())

    def delete_room_events(self, _user_id: str):
        print("\n\nDeleting user events")

        # Delete the creation message by api
        # Get a list of all rooms the user created
        room_list = self.select_from("events", "room_id", f"type='m.room.create' AND sender='{_user_id}'")
        for room in room_list:
            self.purge_first_message(room)

        for event_id in self.select_from("room_memberships", "event_id", f"sender='{_user_id}'"):
            self.delete_event(event_id)
        #db_cursor.execute(f"DELETE FROM room_memberships WHERE sender='{_user_id}';")

        #print(select_from("room_memberships", "event_id, room_id", f"sender='{_user_id}'"))

    def delete_event(self, _event_id: str):
        for event_json in self.select_from("event_json", "json", f"event_id='{_event_id}'"):
            if event_json.find("\"membership\":\"join\"") >= 0:
                print("skiping: ", event_json)
                return

        self.db_cursor.execute(f"DELETE FROM event_json WHERE event_id='{_event_id}';")
        self.db_cursor.execute(f"DELETE FROM current_state_events WHERE event_id='{_event_id}';")
        self.db_cursor.execute(f"DELETE FROM event_to_state_groups WHERE event_id='{_event_id}';")
        self.db_cursor.execute(f"DELETE FROM stream_ordering_to_exterm WHERE event_id='{_event_id}';")
        self.db_cursor.execute(f"DELETE FROM event_auth WHERE event_id='{_event_id}';")
        self.db_cursor.execute(f"DELETE FROM event_auth_chains WHERE event_id='{_event_id}';")
        self.db_cursor.execute(f"DELETE FROM event_edges WHERE event_id='{_event_id}';")
        self.db_cursor.execute(f"DELETE FROM state_groups WHERE event_id='{_event_id}';")
        self.db_cursor.execute(f"DELETE FROM state_groups_state WHERE event_id='{_event_id}';")
        self.db_cursor.execute(f"DELETE FROM event_json WHERE event_id='{_event_id}';")

    def matrix_delete(self, _room_id: str, _user_id: str, token: RoomStreamToken) -> Set[int]:
        # Tables that should be pruned:
        #     event_auth
        #     event_backward_extremities
        #     event_edges
        #     event_forward_extremities
        #     event_json
        #     event_push_actions
        #     event_relations
        #     event_search
        #     event_to_state_groups
        #     events
        #     rejections
        #     room_depth
        #     state_groups
        #     state_groups_state
        #     destination_rooms

        # we will build a temporary table listing the events so that we don't
        # have to keep shovelling the list back and forth across the
        # connection. Annoyingly the python sqlite driver commits the
        # transaction on CREATE, so let's do this first.
        #
        # furthermore, we might already have the table from a previous (failed)
        # purge attempt, so let's drop the table first.

        self.db_cursor.execute("DROP TABLE IF EXISTS events_to_purge")

        self.db_cursor.execute(
            "CREATE TEMPORARY TABLE events_to_purge ("
            "    event_id TEXT NOT NULL,"
            "    should_delete BOOLEAN NOT NULL"
            ")"
        )

        # First ensure that we're not about to delete all the forward extremeties
        self.db_cursor.execute(
            "SELECT e.event_id, e.depth FROM events as e "
            "INNER JOIN event_forward_extremities as f "
            "ON e.event_id = f.event_id "
            "AND e._room_id = f._room_id "
            "WHERE f._room_id = ?",
            (_room_id,),
        )
        rows = self.db_cursor.fetchall()
        # if we already have no forwards extremities (for example because they were
        # cleared out by the `delete_old_current_state_events` background database
        # update), then we may as well carry on.
        if rows:
            max_depth = max(row[1] for row in rows)

            # ToDo understand token
            if max_depth < token.topological:
                # We need to ensure we don't delete all the events from the database
                # otherwise we wouldn't be able to send any events (due to not
                # having any backwards extremities)
                raise RuntimeError(
                    400, "topological_ordering is greater than forward extremities"
                )

        logger.info("[purge] looking for events to delete")

        should_delete_expr = "state_events.state_key IS NULL"
        should_delete_params: Tuple[Any, ...] = ()

        # Todo understand token
        #should_delete_params += (_room_id, token.topological)

        # Note that we insert events that are outliers and aren't going to be
        # deleted, as nothing will happen to them.
        self.db_cursor.execute(
            "INSERT INTO events_to_purge"
            " SELECT event_id, %s"
            " FROM events AS e LEFT JOIN state_events USING (event_id)"
            f" WHERE sender='{_user_id}' AND (NOT outlier OR (%s)) AND e._room_id = ? AND topological_ordering < ?"
            % (should_delete_expr, should_delete_expr),
            should_delete_params
        )

        # We create the indices *after* insertion as that's a lot faster.

        # create an index on should_delete because later we'll be looking for
        # the should_delete / shouldn't_delete subsets
        self.db_cursor.execute(
            "CREATE INDEX events_to_purge_should_delete"
            " ON events_to_purge(should_delete)"
        )

        # We do joins against events_to_purge for e.g. calculating state
        # groups to purge, etc., so lets make an index.
        self.db_cursor.execute("CREATE INDEX events_to_purge_id ON events_to_purge(event_id)")

        self.db_cursor.execute("SELECT event_id, should_delete FROM events_to_purge")
        event_rows = self.db_cursor.fetchall()
        logger.info(
            "[purge] found %i events before cutoff, of which %i can be deleted",
            len(event_rows),
            sum(1 for e in event_rows if e[1]),
        )

        logger.info("[purge] Finding new backward extremities")

        # We calculate the new entries for the backward extremities by finding
        # events to be purged that are pointed to by events we're not going to
        # purge.
        self.db_cursor.execute(
            "SELECT DISTINCT e.event_id FROM events_to_purge AS e"
            " INNER JOIN event_edges AS ed ON e.event_id = ed.prev_event_id"
            " LEFT JOIN events_to_purge AS ep2 ON ed.event_id = ep2.event_id"
            " WHERE ep2.event_id IS NULL"
        )
        new_backwards_extrems = self.db_cursor.fetchall()

        logger.info("[purge] replacing backward extremities: %r", new_backwards_extrems)

        self.db_cursor.execute(
            "DELETE FROM event_backward_extremities WHERE _room_id = ?", (_room_id,)
        )

        # Update backward extremeties
        self.db_cursor.execute_batch(
            "INSERT INTO event_backward_extremities (_room_id, event_id)"
            " VALUES (?, ?)",
            [(_room_id, event_id) for event_id, in new_backwards_extrems],
        )

        logger.info("[purge] finding state groups referenced by deleted events")

        # Get all state groups that are referenced by events that are to be
        # deleted.
        self.db_cursor.execute(
            """
            SELECT DISTINCT state_group FROM events_to_purge
            INNER JOIN event_to_state_groups USING (event_id)
        """
        )

        referenced_state_groups = {sg for sg, in self.db_cursor}
        logger.info(
            "[purge] found %i referenced state groups", len(referenced_state_groups)
        )

        logger.info("[purge] removing events from event_to_state_groups")
        self.db_cursor.execute(
            "DELETE FROM event_to_state_groups "
            "WHERE event_id IN (SELECT event_id from events_to_purge)"
        )

        # Delete all remote non-state events
        for table in (
            "event_edges",
            "events",
            "event_json",
            "event_auth",
            "event_forward_extremities",
            "event_relations",
            "event_search",
            "rejections",
            "redactions",
        ):
            logger.info("[purge] removing events from %s", table)

            self.db_cursor.execute(
                "DELETE FROM %s WHERE event_id IN ("
                "    SELECT event_id FROM events_to_purge WHERE should_delete"
                ")" % (table,)
            )

        # event_push_actions lacks an index on event_id, and has one on
        # (_room_id, event_id) instead.
        for table in ("event_push_actions",):
            logger.info("[purge] removing events from %s", table)

            self.db_cursor.execute(
                "DELETE FROM %s WHERE _room_id = ? AND event_id IN ("
                "    SELECT event_id FROM events_to_purge WHERE should_delete"
                ")" % (table,),
                (_room_id,),
            )

        # Mark all state and own events as outliers
        logger.info("[purge] marking remaining events as outliers")
        self.db_cursor.execute(
            "UPDATE events SET outlier = ?"
            " WHERE event_id IN ("
            "    SELECT event_id FROM events_to_purge "
            "    WHERE NOT should_delete"
            ")",
            (True,),
        )

        # synapse tries to take out an exclusive lock on room_depth whenever it
        # persists events (because upsert), and once we run this update, we
        # will block that for the rest of our transaction.
        #
        # So, let's stick it at the end so that we don't block event
        # persistence.
        #
        # We do this by calculating the minimum depth of the backwards
        # extremities. However, the events in event_backward_extremities
        # are ones we don't have yet so we need to look at the events that
        # point to it via event_edges table.
        self.db_cursor.execute(
            """
            SELECT COALESCE(MIN(depth), 0)
            FROM event_backward_extremities AS eb
            INNER JOIN event_edges AS eg ON eg.prev_event_id = eb.event_id
            INNER JOIN events AS e ON e.event_id = eg.event_id
            WHERE eb._room_id = ?
        """,
            (_room_id,),
        )
        (min_depth,) = cast(Tuple[int], self.db_cursor.fetchone())

        logger.info("[purge] updating room_depth to %d", min_depth)

        self.db_cursor.execute(
            "UPDATE room_depth SET min_depth = ? WHERE _room_id = ?",
            (min_depth, _room_id),
        )

        # finally, drop the temp table. this will commit the self.db_cursor in sqlite,
        # so make sure to keep this actually last.
        self.db_cursor.execute("DROP TABLE events_to_purge")

        for event_id, should_delete in event_rows:
            self._invalidate_cache_and_stream(
                self.db_cursor, self._get_state_group_for_event, (event_id,)
            )

            # XXX: This is racy, since have_seen_events could be called between the
            #    transaction completing and the invalidation running. On the other hand,
            #    that's no different to calling `have_seen_events` just before the
            #    event is deleted from the database.
            if should_delete:
                self._invalidate_cache_and_stream(
                    self.db_cursor, self.have_seen_event, (_room_id, event_id)
                )
                self.invalidate_get_event_cache_after_self.db_cursor(self.db_cursor, event_id)

        logger.info("[purge] done")

        return referenced_state_groups

    async def delete_user(self, user: str) -> None:
        # Print info
        print(f"Deleting [{user}] from [?] at [{self.server}]")  # ? was [{_db}], but I cant access it here anymore

        user_id: str = f"@{user}:{self.server}"

        # Matrix way
        #token = self.get_token(user_id)
        #print("Token: ", token)
        #parsed_token = await RoomStreamToken.parse(self, token)
        #self.matrix_delete("!qUWtbjbukIbczwqdCj:matrix.digitalmedcare.de", user_id, parsed_token)
        #return

        # Custom way
        self.delete_room_events(user_id)

        message_id_list: list = self.select_message_ids_from(user)

        # From an issue discussion
        self.db_cursor.execute(f"DELETE FROM users WHERE name='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM user_directory WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM account_data WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM profiles WHERE user_id='{user}';")
        self.db_cursor.execute(f"DELETE FROM user_external_ids WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM user_external_ids WHERE user_id='{user}';")

        # Experimental
        self.db_cursor.execute(f"DELETE FROM user_ips WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM presence_stream WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM device_lists_stream WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM user_directory_search_content WHERE c0user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM devices WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM e2e_cross_signing_keys WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM e2e_cross_signing_signatures WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM user_signature_stream WHERE from_user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM user_stats_current WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM user_filters WHERE user_id='{user}';")
        self.db_cursor.execute("DELETE FROM ui_auth_sessions WHERE serverdict='{\"request_user_id\":\"" + user_id + "\"}';")
        self.db_cursor.execute(f"DELETE FROM ui_auth_sessions_credentials WHERE result='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM access_tokens WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM e2e_one_time_keys_json WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM current_state_delta_stream WHERE state_key='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM e2e_room_keys WHERE user_id='{user_id}';")

        # Room events
        self.db_cursor.execute(f"DELETE FROM state_events WHERE state_key='{user_id}';")


        # Other tables
        self.db_cursor.execute(f"DELETE FROM events WHERE sender='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM e2e_device_keys_json WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM open_id_tokens WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM event_push_summary WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM user_daily_visits WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM e2e_room_keys_versions WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM e2e_fallback_keys_json WHERE user_id='{user_id}';")
        # those two might be obsolete after deactivation
        self.db_cursor.execute(f"DELETE FROM receipts_linearized WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM receipts_graph WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM local_current_membership WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM current_state_events WHERE state_key='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM room_memberships WHERE user_id='{user_id}' OR sender='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM rooms WHERE creator='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM account_data WHERE user_id='{user_id}' OR content Like '%{user_id}%';")
        self.db_cursor.execute(f"DELETE FROM users_who_share_private_rooms WHERE user_id='{user_id}' OR other_user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM users_in_public_rooms WHERE user_id='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM state_groups_state WHERE state_key='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM room_aliases WHERE creator='{user_id}';")
        self.db_cursor.execute(f"DELETE FROM room_account_data WHERE user_id='{user_id}';")

        for message_id in message_id_list:
            self.delete_message(message_id)

        # Delete jsons containing Name
        self.db_cursor.execute(f"SELECT json FROM event_json")
        for _id in self.select_from("event_json", "event_id", f"json LIKE '%{user}%'"):
            self.db_cursor.execute(f"DELETE FROM event_json WHERE event_id='{_id}';")

        # Debug
        #with open('del_test.sql', 'r') as f:
        #    read_data = f.read()
        #for id in message_id_list:
        #    if id in read_data:
        #        print("True, ", id)

    def delete_message(self, id: str) -> None:
        # Execute sql query on database file
        self.db_cursor.execute(f"DELETE FROM events WHERE event_id='{id}';")
        self.db_cursor.execute(f"DELETE FROM event_json WHERE event_id='{id}';")
        self.db_cursor.execute(f"DELETE FROM event_forward_extremities WHERE event_id='{id}';")
        self.db_cursor.execute(f"DELETE FROM event_to_state_groups WHERE event_id='{id}';")
        self.db_cursor.execute("DELETE FROM room_account_data WHERE content='{\"event_id\":\"" + id + "\"}';")
        self.db_cursor.execute(f"DELETE FROM stream_ordering_to_exterm WHERE event_id='{id}';")
        self.db_cursor.execute(f"DELETE FROM event_edges WHERE event_id='{id}';")
        self.db_cursor.execute(f"DELETE FROM event_search_content WHERE c0event_id='{id}';")


def devmode(_mtd: MtD, _username):
    # Main body
    asyncio.run(_mtd.delete_user(_username))

    # _purge_history_txn("!OuwzcoSSRFQqnjXlYK:matrix.digitalmedcare.de", "syt_YWRtaW4_WSzXELBHTWvOkzZeWxtN_3GkVMI", )

    # Write changes to database
    # _mtd.db_connection.commit()

    # Close the connection
    _mtd.db_connection.close()


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

    # Optional argument, developer mode
    parser.add_argument('-d', '--developer',
                        help='Run in developer mode to set edit local file and execute additional shell commands',
                        action="store_true")

    # Parse arguments
    args = parser.parse_args()

    # create mtd
    mtd = MtD(args.config)

    # Developer mode
    if args.developer:
        print("Dev mode active")
        devmode(mtd, args.username)
        return

    # Measure run time
    start_time = time.time()

    # Main body
    asyncio.run(mtd.delete_user(args.username))

    # _purge_history_txn("!OuwzcoSSRFQqnjXlYK:matrix.digitalmedcare.de", "syt_YWRtaW4_WSzXELBHTWvOkzZeWxtN_3GkVMI", )

    # Write changes to database
    mtd.db_connection.commit()

    # Close the connection
    mtd.db_connection.close()

    # Measure run time
    execution_time = (time.time() - start_time)
    print('Execution time in seconds: ' + str(execution_time))
# ToDo performance measurement and counting in debug mode (also count outside of performance test)


if __name__ == "__main__":
    main()
