use sqlite3::{State, Statement};
extern crate serde_json;
use indicatif::ProgressBar;
use serde_json::json;
use serde_json::Value as JsonValue;
use std::env;
use std::io;

fn main() {
    let args: Vec<String> = env::args().collect();
    let matrix = ":matrix.digitalmedcare.de"; 
    println!("MATRIX: {}", matrix);

    if args.len() == 3 {
        let user = &args[1];
        let path = &args[2];

        find_and_delete_message(user.to_string(), path.to_string(), matrix.to_string());
    }
    if args.len() == 4 {
        let user = &args[1];
        let path = &args[2];
        let matrix = &args[3];
        find_and_delete_message(user.to_string(), path.to_string(), matrix.to_string());
    }
    if args.len() != 1 && args.len() < 3 {
        println!("length: {}",args.len());
        println!("NOT ENOUGH ARGUMENTS! \u{1F44E}");
    }

    if args.len() == 1 {
        user_input();
    }
}

fn find_and_delete_message(username: String, path_to_db: String, matrix_adress: String) {
    let connection = sqlite3::open(path_to_db).unwrap();
    let mut event_id_statement =
        "select event_id from events where type='m.room.encrypted' and sender='@".to_owned();
    event_id_statement.push_str(&username);
    event_id_statement.push_str(":");
    event_id_statement.push_str(&matrix_adress);
    event_id_statement.push_str("'");

    print!("event:{} ", event_id_statement);

    let statement = connection.prepare(event_id_statement).unwrap();

    let messages = find_messages(statement);

    let bar = ProgressBar::new(messages.len().try_into().unwrap());

    for i in messages.iter() {
        bar.inc(1);
        let mut where_statement = "select * from event_json where event_id = ".to_owned();
        where_statement.push_str("'");
        where_statement.push_str(&i);
        where_statement.push_str("'");
        let new = connection.prepare(where_statement).unwrap();

        let json = find_json(new);
        let mut update_statement: String = "UPDATE event_json  ".to_owned();
        let new_json = find_message_content(json);

        update_statement.push_str("SET json ='");
        update_statement.push_str(&new_json);
        update_statement.push_str("' WHERE event_id = '");
        update_statement.push_str(&i);
        update_statement.push_str("';");

        connection.execute(&update_statement).unwrap();
    }
    bar.finish();
}

fn find_message_content(result: String) -> String {
    let message_from_json: Result<JsonValue, serde_json::Error> = serde_json::from_str(&result);

    if message_from_json.is_ok() {
        let mut p: JsonValue = message_from_json.unwrap();
        p["content"] = json!({
            "body": "MESSAGE DELETED",
            "msgtype": "m.text"});
        return p.to_string();
    } else {
        return "Feierabend".to_string();
    }
}

fn find_messages(mut statement: Statement) -> Vec<String> {
    let mut messages_vec: Vec<String> = Vec::new();
    while let State::Row = statement.next().unwrap() {
        messages_vec.push(statement.read::<String>(0).unwrap().to_string());
    }
    return messages_vec;
}

fn find_json(mut statement: Statement) -> String {
    while let State::Row = statement.next().unwrap() {
        return statement.read::<String>(3).unwrap().to_string();
    }
    return "failed".to_string();
}

fn user_input(){
    let mut input1 = String::new();
        let mut input2 = String::new();
        let mut input3 = String::new();
        
        println!("Input Username");
        match io::stdin().read_line(&mut input1) {
            Ok(_) => {
                println!("Deleting for User: {}", input1.to_lowercase());
            }
            Err(e) => println!("Something went wrong {}", e),
        }

        let username = input1.trim_end().to_lowercase();

        println!("path to homeserver.db");
        match io::stdin().read_line(&mut input2) {
            Ok(_) => {
                println!("Deleting for User: {}", input2.to_lowercase());
            }
            Err(e) => println!("Something went wrong {}", e),
        }

        let homserver = input2.trim_end().to_lowercase();

        

        println!("matrix adress");
        match io::stdin().read_line(&mut input3) {
            Ok(_) => {
                println!("Deleting for User: {}", input3.to_lowercase());
            }
            Err(e) => println!("Something went wrong {}", e),
        }

        let matrix = input3.trim_end().to_lowercase();

        find_and_delete_message(username, homserver, matrix);
}