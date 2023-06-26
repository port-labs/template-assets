# CircleCI template

Insert template explanation here

---

Follow these steps to report your CircleCI workflow runs to Port:
1. Create a CircleCI [context](https://circleci.com/docs/contexts/), to pass your Port Credentials to your CircleCI workflows. In your context, create the following environment variables:
```
PORT_CLIENT_ID: ""
PORT_CLIENT_SECRET: ""
```

2. Add the following to your requirements.txt in the wanted branch:
```
requests>=2.28.2
giturlparse>=0.1.0
```


3. Create the following Python script in the branch of the workflow you would like to report to Port:

**report_workflow_to_port.py**
```python 
import os
import requests
from giturlparse import parse
import json

# Env vars passed by the CircleCI context
CLIENT_ID = os.environ['PORT_CLIENT_ID']
CLIENT_SECRET = os.environ['PORT_CLIENT_SECRET']
API_URL = 'https://api.getport.io/v1'
RUN_STATUS = os.environ['RUN_STATUS']

if os.path.isfile('requirements.txt'):
    packages = [] 
    with open('requirements.txt') as f:
        packages = [line.strip().replace('==', '-').replace('>=','-').replace('<=', '-') for line in f if line.strip()]
        language = "Python"

if os.path.isfile('package.json'):
    language="Node"
    packages = []
    with open('package.json') as f:
        package_json = json.load(f)
        for dep in package_json['dependencies']:
            print(f"{dep.replace('/','-')}-{package_json['dependencies'][dep].replace('^','')}")
            packages.append(f"{dep.replace('/','-')}-{package_json['dependencies'][dep].replace('^','')}")
        
credentials = {
    'clientId': CLIENT_ID,
    'clientSecret': CLIENT_SECRET
}

token_response = requests.post(f"{API_URL}/auth/access_token", json=credentials)

# use this access token + header for all http requests to Port
access_token = token_response.json()['accessToken']
headers = {
    'Authorization': f'Bearer {access_token}'
}

# Create packages passed from env var
package_id = []
for package in packages:
  package_json = {
  "identifier": f"{package}",
  "properties": {
    "version": f"{package.split('-')[1]}",
    "language": f"{language}"
  },
  "relations": {}
  }
  package_id.append(package_json["identifier"])
  requests.post(f'{API_URL}/blueprints/package/entities?upsert=true', json=package_json, headers=headers)  

print(package_id)

p = parse(f"{os.environ['CIRCLE_REPOSITORY_URL']}")
repo_url = f"{p.host}/{p.owner}/{p.repo}"

file_path = "README.md"
if os.path.exists(file_path):
    with open(file_path, "r") as f:
        readme_content = f.read()
    print(f"README.md contents: {readme_content}")
else:
    print("README.md file not found!")

microservice_entity_json = {
  "identifier": f"{os.environ['CIRCLE_PROJECT_REPONAME']}",
  "properties": {
    "gitUrl": f"{p.url2https}",
    "language": f"{language}",
    "readme": f"{readme_content}"
  },
  "relations": {
    "packages": package_id
  }
}
requests.post(f'{API_URL}/blueprints/microservice/entities?upsert=true', json=microservice_entity_json, headers=headers)

deployment_run_entity_json = {
  "identifier": f"{os.environ['CIRCLE_PROJECT_REPONAME']}-{os.environ['CIRCLE_BRANCH']}-{os.environ['CIRCLE_WORKFLOW_ID']}",
  "properties": {
    "committedBy": os.environ['CIRCLE_USERNAME'],
    "commitHash": os.environ['CIRCLE_SHA1'],
    "runLink": os.environ['CIRCLE_BUILD_URL'],
    "triggeredBranchUrl": f"https://{repo_url}/tree/{os.environ['CIRCLE_BRANCH']}",
    # Can be 'Successful', 'Failed', or 'Running' as per configured in the 'workflowRun' Blueprint
    "runStatus": f"{RUN_STATUS}"
  },
  "relations": {
    "microservice": f"{os.environ['CIRCLE_PROJECT_REPONAME']}"
  }
}
requests.post(f'{API_URL}/blueprints/deployment/entities?upsert=true', json=deployment_run_entity_json, headers=headers)
```


4. Add the following job to the end of your your CircleCI workflow `config.yaml`:

``` yaml
jobs:
# Other jobs
  report-to-port:
    docker:
      - image: cimg/python:3.11
    environment:
      API_URL: https://api.getport.io
      # Can be 'Successful', 'Failed', or 'Running' as per configured in the 'workflowRun' Blueprint
      RUN_STATUS: "Successful" 
    steps:
      - checkout
      - run: pip install -r requirements.txt
      - run: python report_workflow_to_port.py
```

5. Call the `report-to-port` job in your workflows:
```yaml
workflows:
  workflow-run:
    jobs:
    # More jobs
      - report-to-port:
          context:
            # the CircleCI context name of the Port credentials
            - port
```