import {*} with './edges.jac';
import {*} with './globals.jac';
import {*} with './nodes.jac';

graph dialogue_system {
    has anchor dialogue_root;
    spawn {
        dialogue_root = spawn node::dialogue_root;
        global.dialogue_root = dialogue_root.info['jid'];

        soc = spawn node::soc;
        dialogue_root -[intent_transition(intent='greetings')]-> soc;

        eoc = spawn node::eoc;
        dialogue_root -[intent_transition(intent='goodbye')]-> eoc;

        faq_root = spawn node::faq_root;
        dialogue_root -[intent_transition(intent='faq_root')]-> faq_root;

        outstanding_balance = spawn node::outstanding_balance;
        number_of_account = spawn node::number_of_account;
        select_account = spawn node::select_account;
        number_confirmation = spawn node::number_confirmation;

        dialogue_root -[intent_transition(intent='outstanding_balance')]->outstanding_balance;
        number_of_account -[intent_transition(intent='outstanding_balance')]->outstanding_balance;
        number_of_account -[intent_transition(intent='select_account')]->select_account;
        number_of_account -[intent_transition(intent='faq_root')]->faq_root;
        
        dialogue_root -[intent_transition(intent='number_confirmation')]-> number_confirmation;
        number_confirmation -[intent_transition(intent='outstanding_balance')]->outstanding_balance;
        number_confirmation -[intent_transition(intent='number_of_account')]->number_of_account;
        number_confirmation -[intent_transition(intent='faq_root')]->faq_root;
        
        invoice = spawn node::invoice;
        dialogue_root -[intent_transition(intent='invoice')]-> invoice;

        payment_history = spawn node::payment_history;
        dialogue_root -[intent_transition(intent='payment_history')]-> payment_history;


        
    }

}
