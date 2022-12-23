use sqlite3::Connection;
use sqlite3::{State, Statement};
extern crate serde_json;
use indicatif::ProgressBar;
use serde_json::json;
use serde_json::Value as JsonValue;
use std::env;
use std::fs;
use std::io;
use std::time::Instant;

mod hash;

struct DatabaseMTD {
    database: Connection,
    server_domain: String,
}
impl DatabaseMTD {
    fn get_server_domain(&self) -> &str {
        if self.server_domain == String::from("") {
            panic!("Database was not initalized. Use the '.init()' method.");
        }
        return self.server_domain.as_str();
    }

    fn execute(&self, sql_query: &str) -> Vec<String> {
        // ToDo: prepare or something else? prepare seems wrong? I remember there was an issue with the other one
        let mut result_table: Statement = self.database.prepare(sql_query).unwrap();

        let mut messages_vec: Vec<String> = Vec::new();
        while let State::Row = result_table.next().unwrap() {
            messages_vec.push(result_table.read::<String>(0).unwrap().to_string());
        }
        return messages_vec;
    }

    fn execute_single(&self, sql_query: &str) -> String {
        let result: Vec<String> = self.execute(sql_query);
        if result.len() > 1 {
            panic!(
                "Result from SQL query is more than one:\n query: {}\nResult: {:?}",
                sql_query, result
            );
        }

        return result.first().unwrap().to_string();
    }

    pub fn new(database_path: &str) -> Self {
        Self {
            database: sqlite3::open(database_path).unwrap(),
            server_domain: String::from(""),
        }
    }

    // ToDo, this is a workaround, because you cant really do anything in the "constructor"
    pub fn init(&mut self) {
        let sql_query: String = String::from("SELECT DISTINCT server FROM room_alias_servers;");

        let domains: Vec<String> = self.execute(&sql_query);

        if domains.len() > 1 {
            panic!(
                "Found multiple domains. Thats not accounted for:\n{:?}",
                domains
            );
        } else if domains.len() > 1 {
            panic!("Found no domains. Thats not accounted for:\n{:?}", domains);
        }
        self.server_domain = domains.get(0).unwrap().to_string();
        println!("## matrix server domain has been taken from database [Table 'room_alias_servers', column 'server'] ##")
    }

    pub fn find_all_event_types(&self, username: &str) {
        println!("Following event types where found:");
        println!("--------------------");

        let sql_query: String = format!(
            "SELECT DISTINCT type FROM events WHERE sender='@{}:{}';",
            username, self.server_domain
        );

        let event_types: Vec<String> = self.execute(&sql_query);

        for event_type in event_types {
            println!("{}", event_type);
        }
        println!("--------------------\n");
    }

    fn update_json(&self, json_as_string: String) -> String {
        // convert string to JSON object
        let mut event_json: JsonValue= serde_json::from_str(&json_as_string).unwrap();
        /*
        let event_json: Result<JsonValue, serde_json::Error> = serde_json::from_str(&json_as_string);
        
        if event_json.is_err() {
            panic!(
                "String could not produce valid JSON object\nString: {}",
                json_as_string
            );
        }

        let mut event_json_obj: JsonValue = event_json.unwrap();
        */

        // Check hash
        /*
        let real_hash: String = p["hashes"]["sha256"].to_string();
        let content_hash: String = format!("\"{}\"", hash::generate_hash(&p));
        println!("real hash: {real_hash}");
        println!("calc hash: {content_hash}\n");
        let cmp = (content_hash == real_hash).to_string();

        // assert_eq!(content_hash, real_hash);
        println!("same? {cmp}\n");
        */

        event_json["content"] = json!({
                "body": "MESSAGE DELETED",
                "msgtype": "m.text"});

        // This might be dangerous, if p.to_string() formats it different
        return event_json.to_string();
    }

    // WIP
    fn delete_message(&self, message_id: String) {
        // Get the event json of the message
        // That json contains all data about that message
        let json_string: String = self.get_new_event_json(&message_id);

        let update_statement: String = format!(
            "UPDATE event_json  SET json ='{json_string}' WHERE event_id = '{message_id}';",
        );

        self.database.execute(&update_statement).unwrap();
    }

    // WIP
    fn get_new_event_json(&self, event_id: &String) -> String {
        let select_message_event_json: String =
            format!("SELECT json FROM event_json WHERE event_id = '{event_id}';");

        let event_json: String = self.execute_single(&select_message_event_json);

        let new_json: String = self.update_json(event_json);

        return new_json;
    }

    // WIP this might get changed to traverse prev_event or other behavior
    pub fn delete_user_messages(&self, username: &str) {
        self.find_all_event_types(username);

        // Select all message ids from user (of type encrypted message)
        let select_assl_message_ids: String = format!(
            "SELECT event_id FROM events WHERE type='m.room.encrypted' AND sender='@{}:{}'",
            username, self.server_domain
        );
        let messages: Vec<String> = self.execute(&select_assl_message_ids);

        // Delete every message content
        let bar = ProgressBar::new(messages.len().try_into().unwrap());
        for message_id in messages {
            bar.inc(1);
            self.delete_message(message_id);
        }
        bar.finish();
    }

    /*fn pub delete_user(user: &str) {
        let u: String = user;
    }*/

    /*fn pub delete_user_from_group(user: &str) {
        let u: String = user;
    }*/
}

fn test_hashing() {
    let file_contet =
        fs::read_to_string("raw2.json").expect("Should have been able to read the file");

    let json_file: Result<JsonValue, serde_json::Error> = serde_json::from_str(&file_contet);

    // Original
    let real_json: JsonValue = json_file.unwrap();
    let real_hash = real_json["hashes"]["sha256"].to_string().replace("\"", "");
    println!("real hash: {real_hash}");

    // Homebrew
    let mut new_json: JsonValue = real_json.clone();
    let content_hash: String = hash::generate_hash(&new_json);

    println!("calc hash: {content_hash}\n");
    let cmp = (content_hash == real_hash).to_string();

    assert_eq!(content_hash, real_hash);
    println!("same? {cmp}\n");

    new_json["hashes"] = json!({ "sha256": content_hash });
    assert_eq!(new_json, real_json);
}

fn main() {
    let mut db: DatabaseMTD = DatabaseMTD::new("");
    test_hashing();

    let start: Instant = Instant::now();

    let args: Vec<String> = env::args().collect();

    let mut user: &String = &String::from("");
    let mut path: &String = &String::from("");

    if args.len() == 3 {
        user = &args[1];
        path = &args[2];
    }
    if args.len() == 4 {
        user = &args[1];
        path = &args[2];

        let matrix = &args[3];
    }
    if args.len() != 1 && args.len() < 3 {
        println!("length: {}", args.len());
        println!("NOT ENOUGH ARGUMENTS! \u{1F44E}");
    }

    if args.len() == 1 {
        panic!("No arguments provided");
    }
    db = DatabaseMTD::new(path);
    db.init();
    db.delete_user_messages(user);
    //find_and_delete_message(user.to_string(), path.to_string(), db.get_server_domain());

    println!("MATRIX: {}", db.get_server_domain());

    let elapsed_time = start.elapsed().as_millis();
    println!("The time is probably {}ms", elapsed_time);
    // println!("Time to beat is 20ms, from previous version!")
}
