import requests
import json 
import sys

GITLAB_URL = "https://gitlab.com/api/v4"
PORT_API_URL = "http://localhost:3000/v1" # "https://api.getport.io/v1"
WEBHOOK_URL = "https://smee.getport.io/SNzcBJlHUFfzHDO" 

PORT_CLIENT_ID = sys.argv[0] # "60EsooJtOqimlekxrNh7nfr2iOgTcyLZ"; # "YOUR_PORT_CLIENT_ID"
PORT_CLIENT_SECRET = sys.argv[1] # "3qhzxVQYf2GTrCeXooW6o53vWWqoy3IvnhGIlZJULf6D95RasYVBQyuXB5S3DIry" # "YOUR_PORT_CLIENT_SECRET"
GITLAB_API_TOKEN = sys.argv[2] # "glpat-Rsy5UQmx8yunyC2x935y" # "YOUR_API_TOKEN"
GROUP_ID = sys.argv[3] # 66136652 # "YOUR_GROUP_ID"


def create_webhook():
    api_url = f"{GITLAB_URL}/groups/{GROUP_ID}/hooks"

    webhook_data = {
        "url": WEBHOOK_URL,
        "push_events": True,
        "merge_requests_events": True,
        "issues_events": True,
    }

    response = requests.post(
        api_url,
        headers={"PRIVATE-TOKEN": GITLAB_API_TOKEN},
        json=webhook_data
    )

    if response.status_code == 201:
        print("Webhook added successfully!")
    else:
        print(f"Failed to add webhook. Status code: {response.status_code}")

def get_port_api_token():
    """
    Get a Port API access token
    This function uses CLIENT_ID and CLIENT_SECRET from config
    """

    credentials = {'clientId': PORT_CLIENT_ID, 'clientSecret': PORT_CLIENT_SECRET}

    token_response = requests.post(f"{PORT_API_URL}/auth/access_token", json=credentials)

    return token_response.json()['accessToken']

def create_entity(blueprint: str, body: json, access_token: str):
    """
    Create new entity for blueprint in Port
    """
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'User-Agent': 'gitlab-exporter',
    }

    response = requests.post(f"{PORT_API_URL}/blueprints/{blueprint}/entities?upsert=true&merge=true",json=body, headers=headers)

    return response

def get_all_merge_requests_from_gitlab(token: str):
    merge_requests_url = f"{GITLAB_URL}/groups/{GROUP_ID}/merge_requests"

    response = requests.get(
        merge_requests_url,
        headers={"PRIVATE-TOKEN": GITLAB_API_TOKEN},
    )  

    if response.status_code == 200:
        merge_requests = response.json()

        for merge_request in merge_requests:
            entity = {
                'identifier': str(merge_request['id']),
                'title': merge_request['title'],
                'properties': {
                    'creator': merge_request['author']['username'],
                    'status': merge_request['state'],
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
    else:
        print(f"Failed to get merge requests. Status code: {response.status_code}")


def get_all_entities_from_gitlab():
    # Gets all projects from GitLab and create a microservice for each one
    # Foreach project gets all merge requests from GitLab and create a merge request for each one

    # membership=true will return only the projects that the user is a member of (and not all public projects)
    api_url = f"{GITLAB_URL}/groups/{GROUP_ID}/projects"

    response = requests.get(
        api_url,
        headers={"PRIVATE-TOKEN": GITLAB_API_TOKEN},
    )  

    if response.status_code == 200:
        projects = response.json()

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
            get_all_merge_requests_from_gitlab(token)
    else:
        print(f"Failed to retrieve projects. Status code: {response.status_code}") 

if __name__ == "__main__":
    create_webhook()
    get_all_entities_from_gitlab()
