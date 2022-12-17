### Entity 

-month: march, december
-number: 2315555, 2316666
-account: gtt, dsl, landline

### Intent

-Faqs
-Outstanding Balance
-Invoice
-Payment History



Example 

## Faqs

How do I setup Voicemail
Where can I pay my bill
How to change my wifi password
How do I transfer my account to a different owner or address?
How do I activate roaming?

## Outstanding Balance

I would like to check my outstanding Balance
my number is 2315555
I would like to check my gtt account
or
I would like to check my balance. my number is 2316666

## Invoice
i would like to check my invoice for march


## Payment History
I would like to check my bill for december




**** Change ****

utils/data/state.json // response
utils/data/state/accounts.json // outstanding balance
utils/data/state/invoice.json // invoice
utils/data/state/payment_history.json // payment history

utils/data/bi_train.json // bi_encoder
utils/data/tfm_train.json // tfm_ner
utils/data/faq.json // faq_answer

// update globals.jac if you change tfm_ner or the path

utils/model/local/twilio_bot.py // follow instruction at the bottom of file


Jsserv makemigrations base
Jsserv migrate
Jsserv runserver 0.0.0.0:8008

Jsserv createsuperuser

login http://0.0.0.0:8008/

actions load module jaseci_ai_kit.use_qa
actions load module jaseci_ai_kit.bi_enc
actions load module jaseci_ai_kit.tfm_ner

actions load local utils/model/local/flow.py
actions load local utils/model/local/twilio_bot.py

// graph delete active:graph
jac build main.jac
graph create -set_active true
sentinel register -set_active true -mode ir main.jir

walker run init



### bi_enc
walker run bi_enc_train -ctx "{\"train_file\": \"utils/data/bi_train.json\"}"
walker run bi_enc_infer -ctx "{\"labels\": [\"faq_root\", \"greetings\", \"payment due\", \"invoice\", \"payment_history\"]}"
walker run bi_enc_save_model -ctx "{\"model_path\": \"bi_enc_model\"}"
walker run bi_enc_load_model -ctx "{\"model_path\": \"bi_enc_model\"}"
walker run bi_enc_delete


### tfm_ner
walker run tfm_ner_train -ctx "{\"train_file\": \"utils/data/tfm_train.json\"}"
walker run tfm_ner_infer -ctx "{\"labels\": [\"number\",\"accountname\",\"month\"]}"
walker run tfm_ner_save_model -ctx "{\"model_path\": \"tfm_ner_model\"}"
walker run tfm_ner_load_model -ctx "{\"model_path\": \"tfm_ner_model\"}"
walker run tfm_ner_delete



