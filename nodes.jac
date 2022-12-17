import {*} with './edges.jac';
import {*} with './globals.jac';
import {*} with './walkers.jac';

node user {
    has id;
    has prev_state = null;
    has dialogue_context ={};

    can start_conv with talk entry {
        if (here.prev_state == null) {
            here.prev_state = global.dialogue_root;
        }
        visitor.cont_state = here.prev_state;
        visitor.dialogue_context = here.dialogue_context;
    }

    can update_with_conv with maintainer entry {
        here.prev_state = visitor.prev_state;
        here.dialogue_context = visitor.dialogue_context;
    }
}

node dialogue_state {
    // ai kit 
    can bi_enc.infer;
    can tfm_ner.extract_entity;
    // custom modules
    can flow.info_json;
    can flow.select_response;
    can flow.gen_response;
    can flow.collect_info;
    can flow.select_options;
    can twilio.twilio_bot;

    can classify_intent {
        if(visitor.respond){

            intent_labels = -[intent_transition]->.edge.intent;
            std.out(intent_labels);
            visitor.predicted_intent = bi_enc.infer(
                contexts = [visitor.question],
                candidates = intent_labels,
                context_type = "text",
                candidate_type = "text"
            )[0]["predicted"]["label"];

            std.log("INTENT:  ", visitor.predicted_intent);
        }
    }

    can extract_entities {
        // if(visitor.respond){
            res = tfm_ner.extract_entity(visitor.question);
            if(res.type == list || res.type == dict){

                for ent in res {
                    ent_type = ent["entity_value"];
                    ent_text = ent["entity_text"];
                    //init new type props
                    if ( !(ent_type in visitor.extracted_entities) ){
                        visitor.extracted_entities[ent_type] = [];
                    }
                    
                    //add new entities
                    if( ent_text not in visitor.extracted_entities[ent_type] ){
                        visitor.extracted_entities[ent_type].l::append(ent_text);
                    }
                }
            }

            std.log("ENTITIES:  ", visitor.extracted_entities);
        // }
    }

    can business_logic {
        // if(!visitor.respond) {
            visitor.dialogue_context.dict::update(visitor.extracted_entities);

            for label in global.entity_label {
                if (label in visitor.extracted_entities) {
                    visitor.dialogue_context[label]=visitor.extracted_entities[label];
                }
            }

            // if (visitor.collect_data !='') {
            //     visitor.dialogue_context[visitor.collect_data]=[visitor.question];
            // }
        // }

    }

    

    can nlu with talk entry {}

    can process with talk entry {
        if(visitor.predicted_intent){
            visitor.next_state = -[intent_transition(intent == visitor.predicted_intent)]->[0];
        }
        else{
            visitor.next_state = null;
        }
    }

    can nlg with talk entry {
        if (!visitor.respond and here.name != "dialogue_root") {
            report {
                "question": visitor.question,
                "name": here.name,
                "response": visitor.response
            };
            twilio.twilio_bot(visitor.response, visitor.phone_number, visitor.media);
        }
    }

    can cleanup with talk entry {
        // if(visitor.respond){
            intent_labels = -[intent_transition]->.edge.intent;
            if(intent_labels.length == 0){
                visitor.prev_state = global.dialogue_root;
            }
            else{
                visitor.prev_state = here.info['jid'];
            }

            spawn *(global.main_root) walker::maintainer( 
                prev_state = visitor.prev_state,
                dialogue_context = visitor.dialogue_context
            );
        // }
    }

}


node number_confirmation:dialogue_state {
    has name = 'number_confirmation';

    can nlu with talk entry {
        ::classify_intent;
        ::extract_entities;
        ::business_logic;

        json_data = file.load_json(global.state_path);
        for state_json in json_data{
            if(here.name == state_json['name'].str){
                state = state_json;
                arry = flow.select_response(state["extracted_item"], state["responses"], visitor.extracted_entities); # select a response
                if(arry[0] != ""){
                    visitor.response = arry[1];
                    visitor.next_state = here;
                }
                elif(arry[0] == ""){
                    my_dict = flow.info_json(state['info_file'], visitor.extracted_entities, state['info_items'] ); # setup data for response
                    visitor.dialogue_context = my_dict;
                    ans = flow.gen_response(arry[1], my_dict, null);
                    visitor.response = ans;
                }
            }
        }
    }

    can process with talk entry {
        if ("info_json" in visitor.dialogue_context and visitor.dialogue_context['info_json'].length > 1) {
            std.out('1 if process');
            visitor.respond = true;
            visitor.next_state = -[intent_transition(intent=='number_of_account')]->[0];
        }
        elif ("info_json" in visitor.dialogue_context and visitor.dialogue_context['info_json'].length == 1) {
            std.out('2 if process');
            visitor.respond = true;
            visitor.next_state = -[intent_transition(intent=='outstanding_balance')]->[0];
        }
        elif (visitor.predicted_intent && !visitor.next_state) {
            std.out('3 if process');
            visitor.next_state = -[intent_transition(intent==visitor.predicted_intent)]->[0];
        }
        else {
            std.out('4 if process');
            // std.out("visitor.next_state is null: instde number_confirmation");
            visitor.next_state = here;
        }
    }
    
    
}

node number_of_account:dialogue_state {
    has name= 'number_of_account';
    has state;

    can nlu with talk entry {
        visitor.predicted_intent = null;
        ::classify_intent;
        ::extract_entities;
        ::business_logic;
        // std.out('number_of_account');
        // visitor.response = 'change response';
        json_data = file.load_json(global.state_path);
        for state_json in json_data{
            if(here.name == state_json['name'].str){
                state = state_json;
                arry = flow.select_response(null, state["responses"], null); # select a response
                if(arry[0] != ""){
                    visitor.response = arry[1];
                    visitor.next_state = here;
                }
                elif(arry[0] == ""){
                    // my_dict = flow.info_json(state['info_file'], visitor.dialogue_context, state['info_items'] ); # setup data for response
                    // std.out("my_dict");
                    // std.out(my_dict);
                    // visitor.extract_entities = my_dict;
                    selected_option = flow.select_options(arry[1], visitor.dialogue_context, state['info_items']);

                    // ans = flow.gen_response(arry[1], visitor.dialogue_context, state['info_items']);
                    visitor.response = selected_option;

                }

            
            }
        }

    }
    can process with talk entry {
        std.out("visitor.dialogue_context");
        std.out(visitor.dialogue_context);
        if ('accountname' in visitor.dialogue_context) {
            std.out('noa process 1 if');
            visitor.next_state = -[intent_transition(intent=='outstanding_balance')]->[0];
        }
        elif (visitor.predicted_intent) {
            std.out('noa process 2 if');
            std.out(visitor.predicted_intent);
            visitor.next_state = -[intent_transition(intent==visitor.predicted_intent)]->[0];
        }
        else {
            std.out('noa process 3 if');
            visitor.next_state = -[intent_transition(intent=="select_account")]->[0];
        }
    }
}

node outstanding_balance:dialogue_state {
    has name= 'outstanding_balance';

    can nlu with talk entry {
        std.out('outstanding_balance');
        json_data = file.load_json(global.state_path);
        for state_json in json_data{
            if(here.name == state_json['name'].str){
                state = state_json;
                arry = flow.select_response(null, state["responses"], null); # select a response
                if(arry[0] != ""){
                    visitor.response = arry[1];
                    visitor.next_state = here;
                }
                elif(arry[0] == ""){
                    // my_dict = flow.info_json(state['info_file'], visitor.dialogue_context, state['info_items'] ); # setup data for response
                    // std.out("my_dict");
                    // visitor.dialogue_context = my_dict;
                    if ('accountname' not in visitor.dialogue_context){
                        visitor.dialogue_context['accountname']=[visitor.dialogue_context['info_json'][0]['account']];
                    }
                    std.out(visitor.dialogue_context);
                    selected_dict = {};
                    for item in visitor.dialogue_context['info_json']{
                        // std.out(item['account']);
                        // std.out(visitor.dialogue_context['accountname'][0]);
                        if (visitor.dialogue_context['accountname'][0] == item['account']){
                            selected_dict = item;
                        }
                    }
                    // }
                    // else {
                    //     // selected_dict['balance']=visitor.dialogue_context['info_json'][0]['balance'];
                    //     // selected_dict['due date']=visitor.dialogue_context['info_json'][0]['due date'];
                    //     selected_dict = flow.info_json(state['info_file'], visitor.dialogue_context['info_json'][0], state['info_items'] ); # setup data for response

                    // }
                    std.out("selected_dict");
                    std.out(selected_dict);
                    ans = flow.gen_response(arry[1], selected_dict, state['info_items']);
                    visitor.response = ans;

                }

            
            }
        }
    }

    can process with talk entry{
        // visitor.next_state= -[intent_transition(intent=='number_of_account')]->[0];
        // if(visitor.predicted_intent){
        //     std.out('ob process 1 if');
        //     // visitor.next_state = *(visitor.prev_state);
        //     visitor.next_state= -[intent_transition(intent==visitor.predicted_intent)]->[0];
        //     // visitor.next_state= -[intent_transition(intent==visitor.prev_state)]->;
        // }
        // else {
        //     std.out('ob process 2 if');
        //     visitor.next_state = *(global.dialogue_root);
        // }
        visitor.next_state = *(global.dialogue_root);

    }
}

node select_account:dialogue_state {
    has name = "select_account";

    can nlu with talk entry {
        std.out('select_account');
        state_json = file.load_json(global.state_path);
        for state in state_json{
            if (!visitor.respond) {
                if (here.name == state["name"].str){
                    arry = flow.select_response(null, state['responses'], null);
                    std.out(arry);
                    visitor.response = arry[1];
                }
            }
        }
    }

    can process with talk entry{
        if(visitor.prev_state){
            std.out('sa process 1 if');
            visitor.next_state = visitor.prev_state;
            // visitor.next_state= -[intent_transition(intent==visitor.prev_state)]->;
        }
        else{ 
            std.out('sa process 2 if');
            visitor.next_state = global.dialogue_root;}
    }
}


node invoice:dialogue_state {
    has name = 'invoice';

    can nlu with talk entry {
        ::classify_intent;
        ::extract_entities;
        ::business_logic;

        json_data = file.load_json(global.state_path);
        for state_json in json_data{
            if(here.name == state_json['name'].str){
                state = state_json;
                arry = flow.select_response(state["extracted_item"], state["responses"], visitor.extracted_entities); # select a response
                if(arry[0] != ""){
                    visitor.response = arry[1];
                    visitor.next_state = here;
                }
                elif(arry[0] == ""){
                    my_dict = flow.info_json(state['info_file'], visitor.extracted_entities, state['info_items'] ); # setup data for response
                    visitor.dialogue_context = my_dict;
                    ans = flow.gen_response(arry[1], my_dict['info_json'][0], null);
                    visitor.response = ans;
                }
            }
        }
    }


    can process with talk entry {
        if (visitor.predicted_intent && !visitor.next_state) {
            std.out('1 if process');
            visitor.next_state = -[intent_transition(intent==visitor.predicted_intent)]->[0];
        }
        else {
            std.out('2 if process');
            visitor.next_state = here;
        }
    }


}

node payment_history:dialogue_state {
    has name = 'payment_history';

    can nlu with talk entry {
        ::classify_intent;
        ::extract_entities;
        ::business_logic;

        json_data = file.load_json(global.state_path);
        for state_json in json_data{
            if(here.name == state_json['name'].str){
                state = state_json;
                arry = flow.select_response(state["extracted_item"], state["responses"], visitor.extracted_entities); # select a response
                if(arry[0] != ""){
                    visitor.response = arry[1];
                    visitor.next_state = here;
                }
                elif(arry[0] == ""){
                    my_dict = flow.info_json(state['info_file'], visitor.extracted_entities, state['info_items'] ); # setup data for response
                    visitor.dialogue_context = my_dict;
                    std.out(my_dict);
                    ans = flow.gen_response(arry[1], my_dict['info_json'][0], null);
                    visitor.response = ans;
                }
            }
        }

    }

}

node dialogue_root:dialogue_state {
    has name = "dialogue_root";
    can nlu with talk entry {
        ::classify_intent;
        ::extract_entities;
        ::business_logic;
    }
    can process with talk entry {
        if ("accountname" in visitor.extracted_entities) {
            visitor.next_state = -[intent_transition(intent=='outstanding_balance')]->[0];
        }
        elif(visitor.predicted_intent){
            visitor.next_state = -[intent_transition(intent == visitor.predicted_intent)]->[0];
        }
        else{
            visitor.next_state = null;
        }
        
    }
}

node soc:dialogue_state {
    has name = "greetings";

    can nlu with talk entry {
        state_json = file.load_json(global.state_path);
        for state in state_json{
            if (!visitor.respond) {
                if (here.name == state["name"].str){
                    arry = flow.select_response(null, state['responses'], null);
                    std.out(arry);
                    visitor.response = arry[1];
                }
            }
        }
    }

    can process with talk entry{
        visitor.next_state = -[intent_transition(intent==global.dialogue_root)]->;
    }
}

node eoc:dialogue_state {
    has name = "goodbye";

    can nlu with talk entry {
        state_json = file.load_json(global.state_path);
        for state in state_json{
            if (!visitor.respond) {
                if (here.name == state["name"].str){
                    arry = flow.select_response(null, state['responses'], null);
                    std.out(arry);
                    visitor.response = arry[1];
                }
            }
        }
    }

    can process with talk entry{
        visitor.next_state = -[intent_transition(intent==global.dialogue_root)]->;
    }
}


node faq_root:dialogue_state{
    has name = 'faq answer';
    can use.qa_classify;

    can nlu with talk entry{
        answers = -->.answer;
        best_answer = use.qa_classify(
            text = visitor.question,
            classes = answers
        );
        score = global.faq_score;
        nn = best_answer['match_idx'];
        std.log( "FAQ: " + " MATCH: ",best_answer['match'],"   SCORE: " ,best_answer['scores'][nn]);

        if (best_answer['scores'][nn] > score){
            visitor.response = best_answer['match'];
        }
    }

    can process with talk entry{
        if(visitor.prev_state){
            std.out('fr process if 1');
            visitor.next_state = *(visitor.prev_state);
            // visitor.next_state= -[intent_transition(intent==visitor.prev_state)]->;
        }
        else{ 
            std.out('fr process if 2');
            visitor.next_state = global.dialogue_root;
        }
    }

}

node faq_state{
    has name = 'faq state';
    has answer;
}


