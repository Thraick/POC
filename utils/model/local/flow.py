import random
from jaseci.actions.live_actions import jaseci_action  # step 1
import json
import os


dir_path = os.path.dirname(os.path.realpath(__file__))


# response = selected response
# my_dict = info json

# @jaseci_action(act_group=["flow"], allow_remote=True)
# def gen_response(response: str, my_dict: dict):
#     answer = ""
#     if "{{" in response:
#         l1 = response.replace('{{', '{')
#         l2 = l1.replace('}}', '}')
#         answer = l2.format(**my_dict)
#     else:

#         answer = response

#     return answer


# state_ext_item = state item to be extracted with response
# state_response = response for state
# dial_context = extracted item to info json or dial context

# return name of response and response

@jaseci_action(act_group=["flow"], allow_remote=True)
def select_response(state_ext_item: dict, state_response: list, dial_context: dict):
# def select_response(state_ext_item: dict, state_response: list, dial_context: dict, info_response:dict):

    response_name = ""
    response = ""
    # if (info_response):
    #     for item in info_response:
    #         response_name = item
    #         response = random.choice(info_response[item])
    if (state_ext_item):
        context_key = list(dial_context.keys())
        for item in state_ext_item:
            if item not in context_key:
                response_name = item
                response = random.choice(state_ext_item[item])
                break
    if response == "":
        response = random.choice(state_response)
    return [response_name, response]


# info_file = name of info file
# dial_context = extracted item
# info_items = items to return info about

# return a dict of info

# @jaseci_action(act_group=["flow"], allow_remote=True)
# def info_json(info_file: str, dial_context: dict, info_items):
#     # open_json = str(dir_path)+'/data/'+info_file
#     open_json = info_file

#     my_dict = {}
#     info_id = info_items[0]

#     for item in dial_context:
#         my_dict[item] = dial_context[item][0]

#     if (info_file):
#         with open(open_json) as f:
#             data_set = json.load(f)
#         for data in data_set:
#             if data[info_id] in dial_context[info_id]:
#                 for item in info_items:
#                     my_dict[item] = data[item]
#     return my_dict



@jaseci_action(act_group=["flow"], allow_remote=True)
def info_json(info_file: str, dial_context: dict, info_items):
    # open_json = str(dir_path)+'/data/'+info_file
    open_json = info_file

    my_dict = {}
    info_id = info_items[0]
    my_list = []

    for item in dial_context:
        my_dict[item] = dial_context[item][0]

    # print("my_dic\n\n")
    # print(my_dic)
    if (info_file):
        with open(open_json) as f:
            data_set = json.load(f)
        for data in data_set:
            if data[info_id] in dial_context[info_id]:
                my_dic = {}
                for item in info_items:
                    my_dic[item] = data[item]
                my_list.append(my_dic)
    
    # print("my_dict\n\n")
    # print(my_dic)
    print(info_id)
    print(my_list)
    my_dict["info_json"]= my_list
    return my_dict



@jaseci_action(act_group=["flow"], allow_remote=True)
def collect_info(collect_info: dict, my_dict: dict):

    dict_key = list(my_dict.keys())


    for key, value in collect_info.items():
        if key not in dict_key:
            return [key, value]
    
    return ["",""]



@jaseci_action(act_group=["flow"], allow_remote=True)
def gen_response(response: str, my_dict: dict, info_items:list):
    
    
    answer = ""

    # if(type(info_items) == list and "{{" in response):
    #     my_lis = []
    #     item = info_items[-1]

    #     for a in my_dict['info_json']:
    #         my_lis.append(a[item])
        
    #     lis1 =', '.join(map(str, my_lis[:-1]))
    #     lis2 = my_lis[-1]

    #     new_dict= my_dict.copy()
    #     new_dict["first_"+item]=lis1
    #     new_dict["last_"+item]=lis2
    #     new_dict["num_"+item]= len(my_dict['info_json'])+1
    #     print('new dict\n')
    #     print(response)
    #     print(new_dict)


    #     l1 = response.replace('{{', '{')
    #     l2 = l1.replace('}}', '}')
    #     answer = l2.format(**new_dict)
    #     # answer = 'test'

    
    if "{{" in response:
        l1 = response.replace('{{', '{')
        l2 = l1.replace('}}', '}')
        answer = l2.format(**my_dict)
    else:

        answer = response

    return answer


@jaseci_action(act_group=["flow"], allow_remote=True)
def select_options(response: str, my_dict: dict, info_items:list):
    
    my_lis = []
    item = info_items[-1]

    for a in my_dict['info_json']:
        my_lis.append(a[item])
    
    lis1 =', '.join(map(str, my_lis[:-1]))
    lis2 = my_lis[-1]

    new_dict= my_dict.copy()
    new_dict["first_"+item]=lis1
    new_dict["last_"+item]=lis2
    new_dict["num_"+item]= len(my_dict['info_json'])
    print('new dict\n')
    print(response)
    print(new_dict)


    l1 = response.replace('{{', '{')
    l2 = l1.replace('}}', '}')
    answer = l2.format(**new_dict)

    return answer
