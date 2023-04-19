import requests
import json 
import sys

PORT_CLIENT_ID = sys.argv[1]
PORT_CLIENT_SECRET = sys.argv[2] 
GITLAB_API_TOKEN = sys.argv[3]
GROUP_ID = sys.argv[4]
GITLAB_API_URL = sys.argv[5]

GITLAB_URL = f"https://gitlab.com/api/v4/groups/{GROUP_ID}" 

if GITLAB_API_URL != "":
    GITLAB_URL = f"{GITLAB_API_URL}/api/v4/groups/{GROUP_ID}"

PORT_API_URL = "https://api.getport.io/v1"
WEBHOOK_URL = "https://ingest.getport.io"

def get_port_api_token():
    """
    Get a Port API access token
    This function uses CLIENT_ID and CLIENT_SECRET from config
    """

    credentials = {'clientId': PORT_CLIENT_ID, 'clientSecret': PORT_CLIENT_SECRET}

    token_response = requests.post(f"{PORT_API_URL}/auth/access_token", json=credentials)

    return token_response.json()['accessToken']

def create_webhook():
    gitlab_api_url = f"{GITLAB_URL}/hooks"
    gitlab_request_headers = {"PRIVATE-TOKEN": GITLAB_API_TOKEN}

    # Checks if webhook already exists
    response = requests.get(
        gitlab_api_url,
        headers=gitlab_request_headers
    )

    if response.status_code != 200:
        print(f"Failed to get webhooks from GitLab. Status code: {response.status_code}, Error: {response.json()}, exiting...")
        return
    else: 
        webhooks = response.json()
        if webhooks.__len__() > 0 :
            port_webhook = [webhook for webhook in webhooks if webhook['url'].startswith(WEBHOOK_URL)]
            if port_webhook.__len__() > 0:
                print("Webhook already exists, exiting...")
                return

    # Webhook doesn't exist, create it 
    access_token = get_port_api_token()

    port_request_headers = {
        'Authorization': f'Bearer {access_token}'
    }

    response = requests.get(f"{PORT_API_URL}/webhooks/gitlabIntegration", headers=port_request_headers)

    if response.status_code != 200:
        print(f"Failed to get webhookKey. Status code: {response.status_code}, Error: {response.json()}")
        return
    
    webhook_data = {
        "url": f"{WEBHOOK_URL}/{response.json()['integration']['webhookKey']}",
        "push_events": True,
        "merge_requests_events": True,
        "issues_events": True,
    }

    response = requests.post(
        gitlab_api_url,
        headers=gitlab_request_headers,
        json=webhook_data
    )

    if response.status_code == 201:
        print("Webhook added successfully!")
    else:
        print(f"Failed to add webhook. Status code: {response.status_code}, Error: {response.json()}")

def create_entity(blueprint: str, body: json, access_token: str):
    """
    Create new entity for blueprint in Port
    """
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'User-Agent': 'gitlab-exporter',
    }

    response = requests.post(f"{PORT_API_URL}/blueprints/{blueprint}/entities?upsert=true&merge=true&create_missing_related_entities=true",json=body, headers=headers)

    return response

def get_all_merge_requests_from_gitlab():
    # Gets all merge requests for this group and its subgroups.
    merge_requests_url = f"{GITLAB_URL}/merge_requests"

    response = requests.get(
        merge_requests_url,
        headers={"PRIVATE-TOKEN": GITLAB_API_TOKEN},
    )  

    if response.status_code == 200:
        merge_requests = response.json()

        token = get_port_api_token()
        for merge_request in merge_requests:
            entity = {
                'identifier': str(merge_request['id']),
                'title': merge_request['title'],
                'properties': {
                    'creator': merge_request['author']['username'],
                    'status': merge_request['state'], # can be opened, closed, merged or locked.
                    'createdAt': merge_request['created_at'],
                    'updatedAt': merge_request['updated_at'],
                    'description': merge_request['description'],
                    'link': merge_request['web_url']
                },
                'relations': {
                    'microservice': str(merge_request['source_project_id']),
                }
            }

            create_entity('mergeRequest', entity, access_token=token)
        
        print(f"Created {merge_requests.__len__()} merge requests")
    else:
        print(f"Failed to get merge requests. Status code: {response.status_code}")


def get_all_entities_from_gitlab():
    # Gets all projects from GitLab and create a microservice for each one
    # Gets all merge requests from GitLab and create a merge request for each one
    api_url = f"{GITLAB_URL}/projects"

    response = requests.get(
        api_url,
        headers={"PRIVATE-TOKEN": GITLAB_API_TOKEN},
        # By default, this request returns 20 results at a time because the API results are paginated.
        # Archived projects are included by default so we need to exclude them.
        params={'include_subgroups': True, 'archived': False, 'per_page': 100}
    )  

    if response.status_code == 200:
        projects = response.json()

        # Creates microservices
        token = get_port_api_token()
        for project in projects:
            entity = {
                'identifier': str(project['id']),
                'title': project['name'],
                'properties': {
                    'description': project['description'],
                    'url': project['web_url']
                }
            }

            create_entity('microservice', entity, access_token=token)
        
        print(f"Created {projects.__len__()} microservices")

        # Creates merge requests of projects that already exist in Port
        if projects.__len__() > 0:
            get_all_merge_requests_from_gitlab()
            
    else:
        print(f"Failed to retrieve projects. Status code: {response.status_code}") 

if __name__ == "__main__":
    create_webhook()
    get_all_entities_from_gitlab()

