use sqlite::{State, Statement};
use regex::Regex;

fn main() {
    find_and_delete_message();
}

fn find_and_delete_message(){
    let connection = sqlite::open("homeserver.db").unwrap();
        
    let  statement = connection
    .prepare("select event_id from events where type='m.room.message'")
    .unwrap();

    let messages = find_messages(statement);
    println!("{}", messages);

    let mut where_statement = "select * from event_json where event_id = ".to_owned();
    where_statement.push_str("'");
    where_statement.push_str(&messages);
    where_statement.push_str("'");

    let new =  connection
        .prepare(where_statement)
        .unwrap();

    let json = find_json(new);

    println!("{}",json);

    let re = Regex::new(r"Sup").unwrap();
    assert!(re.is_match(&json));

    let result =  str::replace(&json, "Sup", "Delted Message"); 
    let mut update_statement: String = "UPDATE event_json  ".to_owned();

    update_statement.push_str("SET json ='");
    update_statement.push_str(&result);
    update_statement.push_str("' WHERE event_id = '$zhXyXUJvn7NwHtgzKpls_9uem_TsWm9rpCj6N3GO8eE';");

    connection.prepare(update_statement).unwrap();
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