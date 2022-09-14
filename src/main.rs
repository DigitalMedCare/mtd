use sqlite3::{State, Statement};
extern crate serde_json;
use serde_json::Value as JsonValue;
use serde_json::json;

use std::io;

fn main() {
    let mut input = String::new();

    println!("Input Username");
    match io::stdin().read_line(&mut input){
        Ok(_)=>{
            println!("Deleting for User: {}", input.to_lowercase());
        }
        Err(e) => println!("Something went wrong {}", e),
    }

    let new_input = input.trim_end().to_lowercase();
    find_and_delete_message(new_input);
}


fn find_and_delete_message(username: String){
    let connection = sqlite3::open("homeserver.db").unwrap();
    let mut event_id_statement = "select event_id from events where type='m.room.encrypted' and sender='@".to_owned();
    event_id_statement.push_str(&username);
    event_id_statement.push_str(":matrixtest.digitalmedcare.de'");

    println!("event id statement: {}", event_id_statement);


    let  statement = connection
    .prepare(event_id_statement)
    .unwrap();

    let messages = find_messages(statement);
    let mut counter = 0;
    for i in messages.iter(){
        counter = counter + 1;
        println!("{}: {}",counter, i);
     
    let mut where_statement = "select * from event_json where event_id = ".to_owned();
    where_statement.push_str("'");
    where_statement.push_str(&i);
    where_statement.push_str("'");
    let new =  connection
        .prepare(where_statement)
        .unwrap();

        let json = find_json(new);
        let mut update_statement: String = "UPDATE event_json  ".to_owned();
        let new_json= find_message_content(json);
    
    
        println!{"new_json {}",new_json};
    
        update_statement.push_str("SET json ='");
        update_statement.push_str(&new_json);
       update_statement.push_str("' WHERE event_id = '");
       update_statement.push_str( &i);
       update_statement.push_str("';");
 
       connection.execute(&update_statement).unwrap();
        
        println!("{}", update_statement);
 }

}

fn find_message_content(result: String) -> String{
    
    let message_from_json:Result<JsonValue, serde_json::Error> = serde_json::from_str(&result);
    
    if message_from_json.is_ok(){
        let mut p: JsonValue = message_from_json.unwrap();
        p["content"] = json!({
            "body": "MESSAGE DELETED",
            "msgtype": "m.text"});
        //p["content"]["org.matrix.msc1767.text"] = json!("Deleted Message");
        return p.to_string();
    }else{
        return "Feierabend".to_string();
        }

    
}

fn find_messages(mut statement: Statement) -> Vec<String>{ 
    let mut messages_vec: Vec<String> = Vec::new();
    while let State::Row = statement.next().unwrap(){
        messages_vec.push(statement.read::<String>(0).unwrap().to_string());
    }
    return messages_vec;
}

fn find_json(mut statement: Statement) -> String{
    while let State::Row = statement.next().unwrap(){
        return  statement.read::<String>(3).unwrap().to_string();
    }
    return "failed".to_string();
}