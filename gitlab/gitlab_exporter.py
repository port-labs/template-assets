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
    created_merge_requests_in_port = 0

    response = requests.get(
        merge_requests_url,
        headers={"PRIVATE-TOKEN": GITLAB_API_TOKEN},
    )  

    if response.status_code == 200:
        merge_requests = response.json()

        print(f"Found {len(merge_requests)} merge requests in GitLab")

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

            response = create_entity('mergeRequest', entity, access_token=token)

            if response.status_code == 201:
                created_merge_requests_in_port += 1
        
        print(f"Created {created_merge_requests_in_port} merge requests in Port")
    else:
        print(f"Failed to get merge requests. Status code: {response.status_code}")


def get_all_projects_from_gitlab():
    api_url = f"{GITLAB_URL}/projects"
    current_page = 1
    per_page = 10
    request_more_project = True
    projects_from_gitlab = []
    created_projects_in_port = 0

    # Get all projects from GitLab
    while request_more_project:
        response = requests.get(
            api_url,
            headers={"PRIVATE-TOKEN": GITLAB_API_TOKEN},
            # By default, this request returns 20 results at a time because the API results are paginated.
            # Archived projects are included by default so we need to exclude them.
            params={'include_subgroups': True, 'archived': False, 'per_page': per_page, 'page': current_page}
        )  

        if response.status_code == 200:
            projects = response.json()

            projects_from_gitlab.extend(projects)
        
            if len(projects) == per_page:
                # There are more projects to get
                current_page += 1
            else:
                request_more_project = False
                print(f"Found {len(projects_from_gitlab)} projects in GitLab")
        else:
            print(f"Failed to retrieve projects, Page Number: {current_page}, Status code: {response.status_code}") 

    # Creates microservices in Port
    if len(projects_from_gitlab) > 0:
        token = get_port_api_token()
        for project in projects_from_gitlab:
            entity = {
                'identifier': str(project['id']),
                'title': project['name'],
                'properties': {
                    'description': project['description'],
                    'url': project['web_url']
                }
            }

            response = create_entity('microservice', entity, access_token=token)

            if response.status_code == 201:
                created_projects_in_port += 1
    
    print(f"Created {created_projects_in_port} microservices in Port")

def get_all_issues_from_gitlab():
    api_url = f"{GITLAB_URL}/issues"

    response = requests.get(
        api_url,
        headers={"PRIVATE-TOKEN": GITLAB_API_TOKEN},
    )  

    if response.status_code == 200:
        issues = response.json()

        token = get_port_api_token()
        for issue in issues:
            entity = {
                'identifier': str(issue['id']),
                'title': issue['title'],
                'properties': {
                    'description': issue['description'],
                    'link': issue['web_url'],
                    'createdAt': issue['created_at'],
                    'closedAt': issue['closed_at'],
                    'updatedAt': issue['updated_at'],
                    'creator': issue['author']['username'],
                    'status': issue['state'],
                    'labels': issue['labels']
                }
            }

            create_entity('issue', entity, access_token=token)
            
    else:
        print(f"Failed to retrieve projects. Status code: {response.status_code}") 



if __name__ == "__main__":
    create_webhook()
    get_all_projects_from_gitlab()
    get_all_merge_requests_from_gitlab()
    get_all_issues_from_gitlab()

