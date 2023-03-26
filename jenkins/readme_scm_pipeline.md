# Jenkins installation

Insert template explanation here

---

Follow these steps to report your Jenkins pipeline runs to Port:
1. Install the necessary Jenkins plugins:
- [Plain Credentials](https://plugins.jenkins.io/credentials-binding/) (>=143.v1b_df8b_d3b_e48)
- [HTTP Request](https://plugins.jenkins.io/http_request/) (>=1.16)
- [build user vars plugin](https://plugins.jenkins.io/build-user-vars-plugin/) (>=v1.9)

2. Make sure the following methods are [script approved](https://www.jenkins.io/doc/book/managing/script-approval/):

```
new groovy.json.JsonSlurperClassic
method groovy.json.JsonSlurperClassic parseText java.lang.String
staticMethod java.time.OffsetDateTime now
method java.time.OffsetDateTime format java.time.format.DateTimeFormatter
```


3. Add your `PORT_CLIENT_ID` and `PORT_CLIENT_SECRET` as [Jenkins Credentials](https://www.jenkins.io/doc/book/using/using-credentials/) to use them in your CI pipelines.

4. Add the following stage to the end of your deployment pipeline:

```groovy
import java.time.OffsetDateTime
import java.time.format.DateTimeFormatter
import groovy.json.JsonSlurperClassic
      stage('Report Deployment to Port') {
      steps {
          script {
            // load credentials as variables 
          withCredentials([
              string(credentialsId: 'port-client-id', variable: 'PORT_CLIENT_ID'),
              string(credentialsId: 'port-client-secret', variable: 'PORT_CLIENT_SECRET')
              ]){
            def scmVars = checkout scmGit(
                branches: [[name: 'origin/main']],
                userRemoteConfigs: [[url: "${params.GIT_REPO_URL}"]])
            echo "${scmVars.GIT_COMMIT}"
            auth_body = """
                {
                   "clientId": "${PORT_CLIENT_ID}",
                   "clientSecret": "${PORT_CLIENT_SECRET}"
                }
                """
            token_response = httpRequest contentType: 'APPLICATION_JSON',
                httpMode: "POST",
                requestBody: auth_body,
                url: "${API_URL}/v1/auth/access_token"
            def slurped_response = new JsonSlurperClassic().parseText(token_response.content)
            def token = slurped_response.accessToken // Use this token for authentication with Port

            def repo_body = """
                    {
                        "identifier": "${env.JOB_NAME}-repo",
                        "properties": {
                            "gitUrl": "${params.GIT_REPO_URL}"
                        }
                    }
                    """
            // update jenkinsPipeline entity
            pipeline_response = httpRequest contentType: "APPLICATION_JSON", httpMode: "POST",
            url: "${API_URL}/v1/blueprints/gitRepo/entities?upsert=true&validation_only=false&merge=true",
                requestBody: repo_body,
                customHeaders: [
                    [name: "Authorization", value: "Bearer ${token}"],
                ]            

            def pipeline_body = """
                    {
                        "identifier": "${env.JOB_NAME}",
                        "properties": {
                            "jobUrl": "${env.JENKINS_URL}jobs/${env.JOB_NAME}"
                        }
                    }
                    """
            // update jenkinsPipeline entity
            pipeline_response = httpRequest contentType: "APPLICATION_JSON", httpMode: "POST",
            url: "${API_URL}/v1/blueprints/jenkinsPipeline/entities?upsert=true&validation_only=false&merge=true",
                requestBody: pipeline_body,
                customHeaders: [
                    [name: "Authorization", value: "Bearer ${token}"],
                ]            


            // uses the 'build user vars` 
            wrap([$class: 'BuildUser']) {
                def user = env.BUILD_USER_ID
            }
            OffsetDateTime cur_time = OffsetDateTime.now();
            String formatted_time = cur_time.format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ssXXX"));

            def run_entity_body = """
                    {
                        "identifier": "${env.BUILD_TAG}",
                        "properties": {
                            "triggeredBy": "${user}",
                            "runLink": "${env.BUILD_URL}",
                            "jobEndTime": "${formatted_time}",
                            "jobStatus": "Success"
                        },
                        "relations": {
                            "Pipeline": "${env.JOB_NAME}"
                        }
                    }
                    """
            // create jenkinsPipelineRun entity
            run_entity_response = httpRequest contentType: "APPLICATION_JSON", httpMode: "POST",
            url: "${API_URL}/v1/blueprints/jenkinsPipelineRun/entities?upsert=true&validation_only=false&merge=true",
                requestBody: run_entity_body,
                customHeaders: [
                    [name: "Authorization", value: "Bearer ${token}"],
                ]
          }
      }
    }
}
```