use std::{collections::BTreeMap, str::FromStr};
use serde_json::Value as JsonValue;
use sha256::digest;


fn sign_json(json_object: String, signing_key: String, signing_name: String) -> String {
    /*
    Python code:

    sign_json(json_object, signing_key, signing_name) {
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
    */
    let mut json_object: BTreeMap<String, JsonValue> = serde_json::from_str(&json_object.to_string()).expect("failed to make json object");

    let mut signatures: JsonValue = json_object.remove_entry("signatures").unwrap().1;
    let mut unsigned: JsonValue = json_object.remove_entry("unsigned").unwrap().1;

    /*
    Python code:

    let signed = signing_key.sign(encode_canonical_json(json_object));
    let signature_base64 = encode_base64(signed.signature);

    key_id = "%s:%s" % (signing_key.alg, signing_key.version);
    signatures.setdefault(signing_name, {})[key_id] = signature_base64;

    json_object["signatures"] = signatures;
    if unsigned is not None:
        json_object["unsigned"] = unsigned;*/

    return String::from("_");
}

fn encode_canonical_json(json_map: BTreeMap<String, JsonValue>) -> String {
    let encoded_json = json_map.clone();
    // All strings in Rust are already utf-8 encoded, no need to take care of that
    
    // Sort the keys of dictionaries.
    // is already sorted, in a binary tree map

    // Build a string from Map
    let mut json_string: String = String::from("{");
    for (i, ele) in encoded_json.iter().enumerate() {
        let key = ele.0;
        let value: String;
        if ele.1.is_null() {
            value = String::from("");
        } else {
            value = ele.1.to_string();
        }
        
        json_string.push_str("\"");
        json_string.push_str(&key);
        json_string.push_str("\":");
        json_string.push_str(value.as_str());
        if i != encoded_json.len() - 1 {
            json_string.push_str(",");
        }
    }
    json_string += "}";
    return json_string;
}

fn vec_to_byte_string(bytes: Vec<u8>) -> [u8; 32] {
    let mut byte_string: [u8; 32] = [0; 32];
    for (i, b) in bytes.iter().enumerate() {
        byte_string[i] = *b as u8;
    }

    return byte_string;
}

fn encode_unpadded_base64(json_bytes: [u8; 32])-> String {
    let encoded = base64::encode(json_bytes);

    let final_hash = encoded.replace("=", "");

    return final_hash;
}

fn python_digest(canon_event_json: String)-> [u8; 32] {
    let hex_hashed = digest(canon_event_json);
    
    // Must decode string into bytes, the .to_bytes() function converts each character to a byte
    let decoded = hex::decode(hex_hashed).unwrap();
    
    let byte_string = vec_to_byte_string(decoded);

    return byte_string;
}

fn compute_content_hash(event_json: &JsonValue)-> [u8; 32] {
    // take a copy of the event before we remove any keys.
    let mut event_object: BTreeMap<String, JsonValue> = serde_json::from_str(&event_json.to_string())
    .expect("failed to read file");

    // Keys under "unsigned" can be modified by other servers.
    // They are useful for conveying information like the age of an
    // event that will change in transit.
    // Since they can be modified we need to exclude them from the hash.
    event_object.remove("unsigned");

    // Signatures will depend on the current value of the "hashes" key.
    // We cannot add new hashes without invalidating existing signatures.
    event_object.remove("signatures");

    // The "hashes" key might contain multiple algorithms if we decide to
    // migrate away from SHA-2. We don't want to include an existing hash
    // output in our hash so we exclude the "hashes" dict from the hash.
    event_object.remove("hashes");

    // Other stuff to delete
    event_object.remove("age_ts");
    event_object.remove("outlier");
    event_object.remove("destinations");

    // Encode the JSON using a canonical encoding so that we get the same
    // bytes on every server for the same JSON object.
    let canon_event_json = encode_canonical_json(event_object);


    let python_replication = python_digest(canon_event_json);
    
    return python_replication;
}

// ToDo change name to "hash"?
pub(crate) fn generate_hash(json_value: &JsonValue)-> String {
    return encode_unpadded_base64(compute_content_hash(json_value));
}

pub(crate) fn sign(message_json: String)-> String {
    
    // return sign_json(message_json, signing_key, signing_name);
    // At this point everything breaks down since there is no equal solution in rust
    // It would have to be done in house
    return String::from("");
}
