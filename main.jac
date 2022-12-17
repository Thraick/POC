import {*} with './edges.jac';
import {*} with './globals.jac';
import {*} with './nodes.jac';
import {*} with './graphs.jac';
import {*} with './walkers.jac';
import {*} with './utils/model/kit/bi_enc.jac';
import {*} with './utils/model/kit/tfm_ner.jac';





walker init {
    root {
        take --> node::user else{ 
            spawn here --> graph::dialogue_system;
            spawn here --> node::user;
            spawn here walker::ingest_faq;
        }
        global.main_root = here.info["jid"];
    }
}



walker talk {
    has question, phone_number;
    has predicted_intent;
    has extracted_entities={};
    has dialogue_context ={};
    has response;
    has next_state;
    has prev_state;
    has cont_state;
    has respond = true;
    has media ="";

    root {
        take --> node::user;
    }
    user {
        if(cont_state == ""): std.out('cont_state is an EMPTY STR');
        take *(cont_state);
    }
    dialogue_state {
        if (respond) {
            std.out("\n\nnext_state");
            std.out(next_state);
            take next_state else {
                report {
                    "name": here.name,
                    "response": "Sorry I can't handle that just yet cai."
                };
            }
            respond = false;
        } 
    }
}

