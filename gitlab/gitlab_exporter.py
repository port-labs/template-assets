import requests
import json
import sys
import traceback

PORT_CLIENT_ID = sys.argv[1]
PORT_CLIENT_SECRET = sys.argv[2]
GITLAB_API_TOKEN = sys.argv[3]
GROUPS_TO_REPOS = sys.argv[4]
GITLAB_API_URL = sys.argv[5]
SKIP_WEBHOOK_CREATION = sys.argv[6]

GITLAB_BASE_URL = f"https://gitlab.com/api/v4"

if GITLAB_API_URL != "":
    GITLAB_BASE_URL = GITLAB_API_URL

PORT_API_URL ="https://api.getport.io/v1"
WEBHOOK_URL ="https://ingest.getport.io"

# For Pagination
PAGE_SIZE = 50

# For webhook creation 
root_groups_ids = []

# Group to Projects white list
group_to_projects = {}

# For entities relations
projects_ids_to_names = {}

def process_group_to_projects_config():
    if (GROUPS_TO_REPOS == '*'):
        return
    
    group_to_projects_list_as_string = GROUPS_TO_REPOS.split(';')

    if(GROUPS_TO_REPOS[-1] == ';'):
        group_to_projects_list_as_string = group_to_projects_list_as_string[:-1]
    
    for group_to_projects_string in group_to_projects_list_as_string:
        group_to_projects_string_list = group_to_projects_string.split(':')
        group_name = group_to_projects_string_list[0]
        if (group_to_projects_string_list[1] == '*'):
            group_to_projects[group_name] = '*'
            continue
        projects_names = group_to_projects_string_list[1].split(',')

        group_to_projects[group_name] = projects_names

    print(f"Final group to Projects: {group_to_projects}")

def get_port_api_token():
    """
    Get a Port API access token
    This function uses CLIENT_ID and CLIENT_SECRET from config
    """

    credentials = {'clientId': PORT_CLIENT_ID,
                   'clientSecret': PORT_CLIENT_SECRET}

    token_response = requests.post(
        f"{PORT_API_URL}/auth/access_token", json=credentials)

    if token_response.status_code == 200:
        return token_response.json()['accessToken']
    else:
        print(
            f"Failed to get access token. Status code: {token_response.status_code}, Error: {token_response.json()}")
        return None


def create_webhook(group_id: int):
    gitlab_api_url = f"{GITLAB_BASE_URL}/groups/{group_id}/hooks"
    gitlab_request_headers = {"PRIVATE-TOKEN": GITLAB_API_TOKEN}

    # Checks if webhook already exists
    response = requests.get(
        gitlab_api_url,
        headers=gitlab_request_headers
    )

    print(f"Checks if webhook already exists - Response: {response.text}")

    if response.status_code != 200:
        print(
            f"Failed to get webhooks from GitLab. Status code: {response.status_code}, Error: {response}, exiting...")
        return
    else:
        webhooks = response.json()
        if webhooks.__len__() > 0:
            port_webhook = [
                webhook for webhook in webhooks if webhook['url'].startswith(WEBHOOK_URL)]
            if port_webhook.__len__() > 0:
                print(f"Webhook already exists in group {group_id}, skipping...")
                return

    # Webhook doesn't exist, creating it
    access_token = get_port_api_token()

    port_request_headers = {
        'Authorization': f'Bearer {access_token}'
    }

    response = requests.get(
        f"{PORT_API_URL}/webhooks/gitlabIntegration", headers=port_request_headers)

    if response.status_code != 200:
        print(
            f"Failed to get webhookKey. Status code: {response.status_code}, Error: {response.json()}")
        return

    print(f"Getting webhookKey - Response: {response.text}")

    webhook_data = {
        "url": f"{WEBHOOK_URL}/{response.json()['integration']['webhookKey']}",
        "push_events": True,
        "merge_requests_events": True,
        "issues_events": True,
        "pipeline_events": True,
        "job_events": True
    }

    create_webhook_response = requests.post(
        gitlab_api_url,
        headers=gitlab_request_headers,
        json=webhook_data
    )

    if create_webhook_response.status_code == 201:
        print("Webhook added successfully!")
    else:
        print(
            f"Failed to add webhook. Status code: {create_webhook_response.status_code}, Error: {create_webhook_response.json()}")


def process_data_from_all_groups_from_gitlab():
    gitlab_request_headers = {"PRIVATE-TOKEN": GITLAB_API_TOKEN}
    gitlab_api_url = f"{GITLAB_BASE_URL}/groups"

    try:
        all_groups = request_entities_from_gitlab_using_pagination(gitlab_api_url,
                                                                   gitlab_request_headers,
                                                                   params={'include_subgroups': True})

        root_groups = [group for group in all_groups if group['parent_id'] is None]
        root_groups_ids = [group['id'] for group in root_groups]

        print(f"Found groups: {[g['full_path'] for g in all_groups]}")
        if (group_to_projects == {}):
            configured_groups = [group['full_path'] for group in all_groups]
        else:
            print(f"Configured groups: {group_to_projects.keys()}")
            configured_groups = [group for group in all_groups if group['full_path'] in group_to_projects.keys()]

        print(f"Matching groups: {configured_groups}")

        # Creating webhooks and getting projects for each group
        for group in configured_groups:
            # Create webhook for root groups
            if SKIP_WEBHOOK_CREATION != 'true' and group['id'] in root_groups_ids:
                create_webhook(group['id'])

            get_all_projects_from_gitlab(group['id'], group['full_path'])

    except Exception as e:
        print(f"Failed to process data from GitLab. Error: {e}")
        traceback.print_exc()



def create_entity(blueprint: str, body: json, access_token: str):
    """
    Create new entity for blueprint in Port
    """

    headers = {
        'Authorization': f'Bearer {access_token}',
        'User-Agent': 'gitlab-exporter',
    }

    response = requests.post(
        f"{PORT_API_URL}/blueprints/{blueprint}/entities?upsert=true&merge=true&create_missing_related_entities=true", json=body, headers=headers)

    if not response.ok:
        print(f"Error creating job, status: {response.status_code}, response: {response.text}")

    return response


def request_entities_from_gitlab_using_pagination(api_url: str, headers: dict = None, params: dict = None):
    if headers is None:
        headers = {}
    if params is None:
        params = {}

    current_page = 1
    request_more_entities = True
    entities_from_gitlab = []

    while request_more_entities:
        headers['PRIVATE-TOKEN'] = GITLAB_API_TOKEN
        params['per_page'] = PAGE_SIZE
        params['page'] = current_page

        try:
            response = requests.get(api_url, headers=headers, params=params)

            print(f"Get gitlab entities request - ${api_url}, response - ${response.text}")
            if response.status_code == 200:
                entities = response.json()

                entities_from_gitlab.extend(entities)

                if len(entities) == PAGE_SIZE:
                    # There are more entities to get
                    current_page += 1
                else:
                    request_more_entities = False
            else:
                print(
                    f"Failed to retrieve entities, Page Number: {current_page}, Status code: {response.status_code}")
        except Exception as e:
            print(
                f"Failed to retrieve entities, Page Number: {current_page}, Error: {e}")
            traceback.print_exc()
            
    return entities_from_gitlab


def get_all_projects_from_gitlab(group_id: str, group_name: str):
    created_projects_in_port = 0

    # By default, in gitlab projects a request returns 20 results at a time because the API results are paginated.
    # Archived projects are included by default so we need to exclude them.
    gitlab_group_url = f"{GITLAB_BASE_URL}/groups/{group_id}"

    projects_from_gitlab = request_entities_from_gitlab_using_pagination(
        f"{gitlab_group_url}/projects",
        {},
        {'include_subgroups': True, 'archived': False}
    )

    print(f"Found {len(projects_from_gitlab)} projects in GitLab for group {group_name}")

    # Creates microservices in Port
    if len(projects_from_gitlab) > 0:
        # Filter projects that are not in the white list
        if(group_to_projects != {} and group_to_projects[group_name] != "*"):
            configured_projects = group_to_projects[group_name]
            projects_from_gitlab = [project for project in projects_from_gitlab if project["name"] in configured_projects]

            # Filter project that are not directly in the group
            projects_from_gitlab = [project for project in projects_from_gitlab if project["namespace"]["id"] == group_id]

            print(f"Found {len(projects_from_gitlab)} projects in GitLab for group {group_name} after filtering")

        token = get_port_api_token()

        for project in projects_from_gitlab:
            projects_ids_to_names[project['id']] = project['path_with_namespace'].replace(
                '/', '-').replace(' ', '-').replace('+', '-')

            print(
                f"Creating microservice for {project['path_with_namespace']}")

            entity = {
                'identifier': projects_ids_to_names[project['id']],
                'title': project['name'],
                'properties': {
                    'description': project['description'],
                    'url': project['web_url'],
                    'namespace': project['namespace']['name'],
                    'full_path': project['namespace']['full_path'],
                }
            }

            response = create_entity(
                'microservice', entity, access_token=token)

            if response.status_code == 201:
                created_projects_in_port += 1
            
            get_all_project_merge_requests_from_gitlab(project['id'])
            get_all_project_issues_from_gitlab(project['id'])
            get_all_project_pipelines_from_gitlab(project['id'])
            get_all_project_jobs_from_gitlab(project['id'])

    print(f"Created {created_projects_in_port} microservices in Port for group {group_name}")


def get_all_project_merge_requests_from_gitlab(project_id: str):
    created_merge_requests_in_port = 0

    # Gets all merge requests for this group and its subgroups.
    merge_requests_from_gitlab = request_entities_from_gitlab_using_pagination(
        f"{GITLAB_BASE_URL}/projects/{project_id}/merge_requests"
    )

    print(f"Found {len(merge_requests_from_gitlab)} merge requests in GitLab for project {project_id}")

    if len(merge_requests_from_gitlab) > 0:
        token = get_port_api_token()

        for merge_request in merge_requests_from_gitlab:
            if projects_ids_to_names.get(merge_request['source_project_id']) is None:
                print(
                    f"Skipping merge request {merge_request['title']} because the source project was not imported")
                continue

            print(
                f"Creating merge request for {merge_request['title']} in Port")

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
                    'microservice': projects_ids_to_names[merge_request['source_project_id']],
                }
            }

            response = create_entity(
                'mergeRequest', entity, access_token=token)

            if response.status_code == 201:
                created_merge_requests_in_port += 1

        print(
            f"Created {created_merge_requests_in_port} merge requests in Port for project {project_id}")


def get_all_project_issues_from_gitlab(project_id: str):
    created_issues_in_port = 0

    issues_from_gitlab = request_entities_from_gitlab_using_pagination(
        f"{GITLAB_BASE_URL}/projects/{project_id}/issues")

    print(f"Found {len(issues_from_gitlab)} issues in GitLab for project {project_id}")

    # Creates issues in Port
    if len(issues_from_gitlab) > 0:
        token = get_port_api_token()

        for issue in issues_from_gitlab:
            if projects_ids_to_names.get(issue['project_id']) is None:
                print(
                    f"Skipping issue {issue['title']} because the source project was not imported")
                continue

            print(f"Creating issue for {issue['title']}")

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
                },
                'relations': {
                    'microservice': projects_ids_to_names[issue['project_id']],
                }
            }

            response = create_entity('issue', entity, access_token=token)

            if response.status_code == 201:
                created_issues_in_port += 1

    print(f"Created {created_issues_in_port} issues in Port for project {project_id}")


def get_all_project_pipelines_from_gitlab(project_id: str):
    created_pipelines_in_port = 0
    pipelines_from_gitlab = request_entities_from_gitlab_using_pagination(
            f"{GITLAB_BASE_URL}/projects/{project_id}/pipelines")

    print(f"Found {len(pipelines_from_gitlab)} pipelines in GitLab for project {project_id}")

    # Creates issues in Port
    if len(pipelines_from_gitlab) > 0:
        token = get_port_api_token()

        for pipeline in pipelines_from_gitlab:
            print(f"Creating pipeline for {pipeline['id']}")

            entity = {
                'identifier': str(pipeline['id']),
                'properties': {
                    'createdAt': pipeline['created_at'],
                    'updatedAt': pipeline['updated_at'],
                    'status': pipeline['status'],
                    'link': pipeline['web_url']
                },
                'relations': {
                    'microservice': projects_ids_to_names[pipeline['project_id']],
                }
            }

            response = create_entity('pipeline', entity, access_token=token)

            if response.status_code == 201:
                created_pipelines_in_port += 1

    print(f"Created {created_pipelines_in_port} pipelines in Port for project {project_id}")


def get_all_project_jobs_from_gitlab(project_id: str):
    created_jobs_in_port = 0
    jobs_from_gitlab = request_entities_from_gitlab_using_pagination(
            f"{GITLAB_BASE_URL}/projects/{project_id}/jobs")

    print(f"Found {len(jobs_from_gitlab)} jobs in GitLab for project {project_id}")

    # Creates issues in Port
    if len(jobs_from_gitlab) > 0:
        token = get_port_api_token()

        for job in jobs_from_gitlab:
            print(f"Creating job for {job['name']} {job['id']}")

            entity = {
                'identifier': str(job['id']),
                'title': job['name'],
                'properties': {
                    'createdAt': job['created_at'],
                    'startedAt': job['started_at'],
                    'finishedAt': job['finished_at'],
                    'creator': job['user']['username'],
                    'stage': job['stage'],
                    'status': job['status'],
                },
                'relations': {
                    'pipeline': str(job['pipeline']['id']),
                }
            }

            response = create_entity('job', entity, access_token=token)

            if response.status_code == 201:
                created_jobs_in_port += 1

    print(f"Created {created_jobs_in_port} jobs in Port for project {project_id}")


if __name__ == "__main__":
    try:
        print("Processing group to projects configuration")
        process_group_to_projects_config()
        print("Group to projects configuration processing completed successfully!")
    except Exception as e:
        print(e)
        print("Error processing group to projects configuration")
        traceback.print_exc()
    
    print("Processing data from all groups from GitLab")
    process_data_from_all_groups_from_gitlab()
    print("Data from all groups from GitLab processed successfully!")
