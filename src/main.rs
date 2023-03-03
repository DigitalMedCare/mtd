use sqlite3::Connection;
use sqlite3::{State, Statement};
extern crate serde_json;
use indicatif::ProgressBar;
use serde_json::json;
use serde_json::Value as JsonValue;
use std::env;
use std::time::Instant;

mod validation;

struct DatabaseMTD {
    database: Connection,
    server_domain: String,
}
impl DatabaseMTD {
    fn get_server_domain(&self) -> &str {
        if self.server_domain == String::from("") {
            panic!("Database was not initialized. Use the '.init()' method.");
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

    // WIP
    fn update_json(&self, json_as_string: String) -> String {
        // convert string to JSON object
        let mut event_json: JsonValue = serde_json::from_str(&json_as_string).unwrap();

        // Build new event json
        // Change message content
        event_json["content"] = json!({
            "body": "MESSAGE DELETED",
            "msgtype": "m.text"});
        
        // Generate new hash ToDo: before or after signing?
        let sha256_hash: String = validation::generate_hash(&event_json);
        // Set new hash
        event_json["hashes"] = json!({
            "sha256": sha256_hash,
        });

        // ToDo: signature?
        // *generate signature*

        // This might be dangerous, if p.to_string() formats it different
        return event_json.to_string();
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

    // This is for dev purposes
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

    pub fn get_json(&self, message_id: &str) -> String {
        let select_message_event_json: String =
            format!("SELECT json FROM event_json WHERE event_id = '{message_id}';");

        return self.execute_single(&select_message_event_json);
    }

    // ToDo, this might be changed, so it returns the prev_event. recursively iterate over it like that
    // But how do I find the very last message then?
    pub fn delete_message(&self, message_id: &str) {
        // Get the event json of the message
        // This json contains all data about that message/event
        let json_as_string: String = self.get_json(message_id).to_string();

        // Update json data to not contain the message
        let updated_json_string: String = self.update_json(json_as_string);

        // Update json in database / Write changes to database
        let update_statement: String = format!(
            "UPDATE event_json  SET json ='{updated_json_string}' WHERE event_id = '{message_id}';",
        );
        self.database.execute(&update_statement).unwrap();
    }

    // WIP this might get changed to traverse prev_event or other behavior
    pub fn get_all_user_message_ids(&self, username: &str) -> Vec<String> {
        self.find_all_event_types(username);

        // Select all message ids from user (of type encrypted message)
        let select_all_message_ids: String = format!(
            "SELECT event_id FROM events WHERE type='m.room.message' AND sender='@{}:{}'",
            username, self.server_domain
        );
        let message_ids: Vec<String> = self.execute(&select_all_message_ids);

        return message_ids;
    }

    // ToDo: these functions will be necessary later
    /*fn pub delete_user(user: &str) {
        let u: String = user;
    }*/

    /*fn pub delete_user_from_group(user: &str) {
        let u: String = user;
    }*/
}

fn test_hashing(username: String, db: &DatabaseMTD) {
    let db_json_ids: Vec<String> = db.get_all_user_message_ids(&username);

    println!("Testing hashes for user [{username}]");
    for db_json_id in &db_json_ids {
        // Original
        let db_json: JsonValue = serde_json::from_str(&db.get_json(&db_json_id)).unwrap();
        let db_hash: String = db_json["hashes"]["sha256"].to_string().replace("\"", "");
        //println!("real hash: {db_hash}");

        // Homebrew
        let content_hash: String = validation::generate_hash(&db_json);
        //println!("calc hash: {content_hash}");

        assert_eq!(content_hash, db_hash);
        let cmp: bool = (content_hash == db_hash);
        if !cmp {
            println!("hash did not match:\noriginal: {}\ngenerated: {}", db_hash, content_hash);
            return;
        }
        //println!("same? {cmp}\n");
    }
    let num_hashes: usize = db_json_ids.len();
    println!("All hashes [{num_hashes}] match!");
}

fn test_signature(message: String) {
    let msg_json: JsonValue = serde_json::from_str(&message).unwrap();
    let server: String = String::from("matrix.digitalmedcare.de"); // ToDo change! not hard coded
    let generator: String = String::from("ed25519:a_zzds"); // ToDo change! not hard coded
    let original_signature: String = msg_json["signatures"][server][generator].to_string();

    let new_signature: String = validation::sign(message);
}

fn main() {
    let mut db: DatabaseMTD = DatabaseMTD::new("");

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

        // ToDo: this all might get removed to support only one or two usages
        // let matrix = &args[3];
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
    // Test hashes
    test_hashing(user.to_string(), &db);

    // Do the work
    let messages: Vec<String> = db.get_all_user_message_ids(user);
    let bar:ProgressBar = ProgressBar::new(messages.len().try_into().unwrap());
    // Delete every message content
    for message_id in messages {
        bar.inc(1);
        db.delete_message(&message_id);
    }
    bar.finish();
    

    println!("MATRIX: {}", db.get_server_domain());

    let elapsed_time = start.elapsed().as_millis();
    println!("The time is probably {}ms", elapsed_time);

    test_hashing(user.to_string(), &db);
    // println!("Time to beat is 20ms, from previous version!")
}
