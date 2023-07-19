from itertools import combinations
from os.path import join, dirname
import json

SCRIPT_PATH_ABS_PATH = dirname(__file__)
TEMPLATE_LIST_PATH = "../../kubernetes/template_list.json"
LIST_ABS_PATH = join(SCRIPT_PATH_ABS_PATH, TEMPLATE_LIST_PATH)
BASE_CONFIG_PATH = "../../kubernetes/kubernetes_v1_config.yaml"
BASE_CONFIG_ABS_PATH = join(SCRIPT_PATH_ABS_PATH, BASE_CONFIG_PATH)


f = open(LIST_ABS_PATH, "r")
template_list = json.loads(f.read())

list_combinations = list()

for n in range(len(template_list.keys()) + 1):
    list_combinations += list(combinations(sorted(template_list.keys()), n))

for comb in list_combinations:
    template_name = ""
    with open(BASE_CONFIG_ABS_PATH, "r") as f:
        data = f.read()
    for tmpl in comb:
        if "needs" in template_list[tmpl] and template_list[tmpl]["needs"] not in comb:
            continue
        template_path = join(SCRIPT_PATH_ABS_PATH, f"../../kubernetes/{template_list[tmpl]['path']}")
        with open(template_path, "r") as f:
            template_data = f.read()
        template_name += f"{tmpl}-"
        data += "\n"
        data += template_data
    template_file_name = f"{template_name}kubernetes_v1_config.yaml"
    template_file_path = join(SCRIPT_PATH_ABS_PATH, f"../../kubernetes/templates/{template_file_name}")
    with open (template_file_path, "w") as f:
        print(f"Creating: {template_file_path}")
        f.write(data)
        






