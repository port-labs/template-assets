# CircleCI template

Insert template explanation here

---

Follow these steps to report your CircleCI workflow runs to Port:
1. Create a CircleCI [context](https://circleci.com/docs/contexts/), to pass your Port Credentials to your CircleCI workflows. In your context, create the following environment variables:
```
PORT_CLIENT_ID: ""
PORT_CLIENT_SECRET: ""
```

2. Create the following Python script in the branch of the workflow you would like to report to Port:

**report_workflow_to_port.py**
```python 
import os
import requests
import datetime
from giturlparse import parse

# Env vars passed by the CircleCI context
CLIENT_ID = os.environ['PORT_CLIENT_ID']
CLIENT_SECRET = os.environ['PORT_CLIENT_SECRET']
API_URL = 'https://api.getport.io/v1'

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

p = parse(f"{os.environ['CIRCLE_REPOSITORY_URL']}")
repo_url = f"{p.host}/{p.owner}/{p.repo}"

repo_entity_json = {
  "identifier": f"{os.environ['CIRCLE_PROJECT_REPONAME']}",
  "properties": {
    "gitUrl": f"{p.url2https}",
  },
  "relations": {}
}
requests.post(f'{API_URL}/blueprints/git_repo/entities?upsert=true', json=repo_entity_json, headers=headers)

print(f"{repo_url}/tree/{os.environ['CIRCLE_BRANCH']}")
workflow_entity_json = {
  "identifier": f"{os.environ['CIRCLE_PROJECT_REPONAME']}-{os.environ['CIRCLE_BRANCH']}",
  "properties": {
    "workflowBranch": os.environ['CIRCLE_BRANCH'],
    "branchUrl": f"https://{repo_url}/tree/{os.environ['CIRCLE_BRANCH']}"
  },
  "relations": {
    "projectRepo": os.environ['CIRCLE_PROJECT_REPONAME']
  }
}

print(workflow_entity_json)

response = requests.post(f'{API_URL}/blueprints/workflow/entities?upsert=true', json=workflow_entity_json, headers=headers)


workflow_run_entity_json = {
  "identifier": f"{os.environ['CIRCLE_PROJECT_REPONAME']}-{os.environ['CIRCLE_BRANCH']}-{os.environ['CIRCLE_WORKFLOW_ID']}",
  "properties": {
    "committedBy": os.environ['CIRCLE_USERNAME'],
    "commitHash": os.environ['CIRCLE_SHA1'],
    "repoPushedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "runLink": os.environ['CIRCLE_BUILD_URL']
  },
  "relations": {
    "workflowBranch": f"{os.environ['CIRCLE_PROJECT_REPONAME']}-{os.environ['CIRCLE_BRANCH']}"
  }
}

response = requests.post(f'{API_URL}/blueprints/workflowRun/entities?upsert=true', json=workflow_run_entity_json, headers=headers)
```


3. Add the following to your requirements.txt in the wanted branch:
```
requests>=2.28.2
giturlparse>=0.1.0
```

4. Add the following job to your CircleCI `config.yaml`:

``` yaml
jobs:
# Other jobs
  report-to-port:
    docker:
      - image: cimg/python:3.11
    environment:
      API_URL: https://api.getport.io
    steps:
      - checkout
      - run: pip install -r port_requirements.txt
      - run: python report_workflow_to_port.py
```

5. Call the job in your workflow:
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