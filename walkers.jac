import {*} with './edges.jac';
import {*} with './nodes.jac';

walker ingest_faq {
    has kb_file;

    root: take --> node::dialogue_root;
    dialogue_root{
        take --> node::faq_root;
    }
    faq_root {
        kb = file.load_json(global.faq_path);
        for faq in kb {
            answer = faq["answer"];
            spawn here --> node::faq_state(answer=answer);

        }
    }
}


walker maintainer {
    has prev_state;
    has dialogue_context;
    root: take --> node::user;
}

