use core::panic;

use sqlite::{State, Statement};
extern crate serde_json;
use serde_json::Value as JsonValue;
use serde_json::json;

fn main() {
    find_and_delete_message();
}


fn find_and_delete_message(){
    let connection = sqlite::open("homeserver.db").unwrap();
        
    let  statement = connection
    .prepare("select event_id from events where type='m.room.message'")
    .unwrap();

    let messages = find_messages(statement);

    let mut where_statement = "select * from event_json where event_id = ".to_owned();
    where_statement.push_str("'");
    where_statement.push_str(&messages);
    where_statement.push_str("'");

    let new =  connection
        .prepare(where_statement)
        .unwrap();

    let json = find_json(new);
    let mut update_statement: String = "UPDATE event_json  ".to_owned();
    let new_json = find_message_content(json);

    update_statement.push_str("SET json ='");
    update_statement.push_str(&new_json);
    update_statement.push_str("' WHERE event_id = '$zhXyXUJvn7NwHtgzKpls_9uem_TsWm9rpCj6N3GO8eE';");
    connection.prepare(&update_statement).unwrap();
    
    println!("{}", update_statement);
  
}

fn find_message_content(result: String) -> String{
    let message_from_json:Result<JsonValue, serde_json::Error> = serde_json::from_str(&result);
   
    if message_from_json.is_ok(){
        let mut p: JsonValue = message_from_json.unwrap();
        p["content"]["body"] = json!("Delted Message");
        return p.to_string();
    }else{
        println!("Feierabend!");
        panic!();
        
    }

    
}

fn find_messages(mut statement: Statement) -> String{
    while let State::Row = statement.next().unwrap(){
        return  statement.read::<String>(0).unwrap().to_string();
    }
    return "failed".to_string();
}

fn find_json(mut statement: Statement) -> String{
    while let State::Row = statement.next().unwrap(){
        return  statement.read::<String>(3).unwrap().to_string();
    }
    return "failed".to_string();
}