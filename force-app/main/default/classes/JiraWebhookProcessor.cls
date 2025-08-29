public without sharing class JiraWebhookProcessor implements IWebhookProcessor {
    
    // Constants for webhook event types
    private static final String EVENT_ISSUE_CREATED = 'jira:issue_created';
    private static final String EVENT_ISSUE_UPDATED = 'jira:issue_updated';
    private static final String EVENT_ISSUE_DELETED = 'jira:issue_deleted';
    private static final String EVENT_PROJECT_CREATED = 'project_created';
    private static final String EVENT_PROJECT_UPDATED = 'project_updated';
    private static final String EVENT_PROJECT_DELETED = 'project_deleted';
    
    public Boolean validate(RestRequest request) {
        try {
            String requestBody = request.requestBody.toString();
            Map<String, Object> payload;
            try {
                payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error deserializing JSON: ' + e.getMessage());
                return false;
            }

            if (!payload.containsKey('webhookEvent')) {
                return false;
            }

            return true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error validating webhook: ' + e.getMessage());
            return false;
        }
    }
    
    public void process(RestRequest request) {
        try {
            String requestBody = request.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            String webhookEvent = (String) payload.get('webhookEvent');
            
            if (webhookEvent == EVENT_ISSUE_CREATED) {
                processIssueCreated(payload);
            } else if (webhookEvent == EVENT_ISSUE_UPDATED) {
                processIssueUpdated(payload);
            } else if (webhookEvent == EVENT_ISSUE_DELETED) {
                processIssueDeleted(payload);
            } else if (webhookEvent == EVENT_PROJECT_CREATED) {
                processProjectCreated(payload);
            } else if (webhookEvent == EVENT_PROJECT_UPDATED) {
                processProjectUpdated(payload);
            } else if (webhookEvent == EVENT_PROJECT_DELETED) {
                processProjectDeleted(payload);
            } else {
                throw new JiraWebhookProcessorException('webhookEvent is not supported');
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing webhook: ' + e.getMessage());
            throw e; // Re-throw to let the caller handle it
        }
    }
    
    private void processIssueCreated(Map<String, Object> payload) {
        try {
            Map<String, Object> issueData = (Map<String, Object>) payload.get('issue');
            Jira_Issue__c newIssue = createIssueRecord(issueData);
            Database.insert(newIssue, AccessLevel.SYSTEM_MODE);

            System.debug('Created Jira issue record: ' + newIssue.Id);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing issue_created event: ' + e.getMessage());
            throw e;
        }
    }
    
    private void processIssueUpdated(Map<String, Object> payload) {
        try {
            Map<String, Object> issueData = (Map<String, Object>) payload.get('issue');
            String issueKey = (String) issueData?.get('key');
            if (String.isBlank(issueKey)) {
                throw new JiraWebhookProcessorException('Jira payload missing Issue Key: ' + issueKey + ', cannot locate record to update.');
            }

            List<Jira_Issue__c> issuesToUpdate = [
                SELECT
                    Id, Description__c, Issue_Type__c, Last_Updated__c, Project_Key__c, Status__c, Summary__c
                FROM
                    Jira_Issue__c
                WHERE
                    Issue_Key__c = :issueKey
                WITH SYSTEM_MODE
                LIMIT 1
            ];

            if (!issuesToUpdate.isEmpty()) {
                // Update Record
                Jira_Issue__c recordToUpdate = updateIssueRecord(issuesToUpdate[0], issueData);
                Database.update(recordToUpdate, AccessLevel.SYSTEM_MODE);
                System.debug('Updated Jira issue record: ' + recordToUpdate.Id);
            } else {
                // Create Record
                processIssueCreated(payload);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing issue_updated event: ' + e.getMessage());
            throw e;
        }
    }
    
    private void processIssueDeleted(Map<String, Object> payload) {
        try {
            Map<String, Object> issueData = (Map<String, Object>) payload.get('issue');
            String issueKey = (String) issueData?.get('key');
            if (String.isBlank(issueKey)) {
                throw new JiraWebhookProcessorException('Jira payload missing Issue Key: ' + issueKey + ', cannot locate record to delete.');
            }

            List<Jira_Issue__c> issuesToDelete = [SELECT Id FROM Jira_Issue__c WHERE Issue_Key__c = :issueKey WITH SYSTEM_MODE];
            System.debug('Deleting ' + issuesToDelete.size() + ' Jira issue records with Issue Key: ' + issueKey);
            Database.delete(issuesToDelete, AccessLevel.SYSTEM_MODE);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing issue_deleted event: ' + e.getMessage());
            throw e;
        }
    }
    
    private void processProjectCreated(Map<String, Object> payload) {
        try {
            Map<String, Object> projectData = (Map<String, Object>) payload.get('project');
            Jira_Project__c newProject = createProjectRecord(projectData);
            Database.insert(newProject, AccessLevel.SYSTEM_MODE);

            System.debug('Created Jira project record: ' + newProject.Id);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing project_created event: ' + e.getMessage());
            throw e;
        }
    }
    
    private void processProjectUpdated(Map<String, Object> payload) {
        try {
            Map<String, Object> projectData = (Map<String, Object>) payload?.get('project');
            String projectKey = (String) projectData?.get('key');
            if (String.isBlank(projectKey)) {
                throw new JiraWebhookProcessorException('Jira payload missing Project Key: ' + projectKey + ', cannot locate record to update.');
            }

            List<Jira_Project__c> projectsToUpdate = [
                SELECT
                    Id, Description__c, Project_ID__c, Project_Key__c, Project_Name__c
                FROM
                    Jira_Project__c
                WHERE
                    Project_Key__c = :projectKey
                WITH SYSTEM_MODE
                LIMIT 1
            ];

            if (!projectsToUpdate.isEmpty()) {
                // Update Record
                Jira_Project__c recordToUpdate = updateProjectRecord(projectsToUpdate[0], projectData);
                Database.update(recordToUpdate, AccessLevel.SYSTEM_MODE);
                System.debug('Updated Jira project record: ' + recordToUpdate.Id);
            } else {
                // Create Record
                processProjectCreated(payload);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing project_updated event: ' + e.getMessage());
            throw e;
        }
    }
    
    private void processProjectDeleted(Map<String, Object> payload) {
        try {
            Map<String, Object> projectData = (Map<String, Object>) payload.get('project');
            String projectKey = (String) projectData?.get('key');
            if (String.isBlank(projectKey)) {
                throw new JiraWebhookProcessorException('Jira payload missing Project Key: ' + projectKey + ', cannot locate record to delete.');
            }

            List<Jira_Project__c> projectsToDelete = [SELECT Id FROM Jira_Project__c WHERE Project_Key__c = :projectKey WITH SYSTEM_MODE];
            System.debug('Deleting ' + projectsToDelete.size() + ' Jira project records with Project Key: ' + projectKey);
            Database.delete(projectsToDelete, AccessLevel.SYSTEM_MODE);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing project_deleted event: ' + e.getMessage());
            throw e;
        }
    }

    private Jira_Issue__c createIssueRecord(Map<String, Object> issueData) {
        Map<String, Object> fields = (Map<String, Object>) issueData?.get('fields');
        Map<String, Object> status = (Map<String, Object>) fields?.get('status');
        Map<String, Object> issueType = (Map<String, Object>) fields?.get('issuetype');
        Map<String, Object> project = (Map<String, Object>) fields?.get('project');

        Jira_Issue__c issue = new Jira_Issue__c();
        // Always set Last_Updated__c since it's never null
        issue.Last_Updated__c = Datetime.now();
        
        String issueDescription = (String) fields?.get('description');
        if (String.isNotBlank(issueDescription)) {
            issue.Description__c = issueDescription;
        }
        
        String issueKey = (String) issueData?.get('key');
        if (String.isNotBlank(issueKey)) {
            issue.Issue_Key__c = issueKey;
        }
        
        String issueTypeName = (String) issueType?.get('name');
        if (String.isNotBlank(issueTypeName)) {
            issue.Issue_Type__c = issueTypeName;
        }
        
        String projectKey = (String) project?.get('key');
        if (String.isNotBlank(projectKey)) {
            issue.Project_Key__c = projectKey;
        }
        
        String issueStatus = (String) status?.get('name');
        if (String.isNotBlank(issueStatus)) {
            issue.Status__c = issueStatus;
        }
        
        String issueSummary = (String) fields?.get('summary');
        if (String.isNotBlank(issueSummary)) {
            issue.Summary__c = issueSummary;
        }
        
        return issue;
    }
    
    private Jira_Issue__c updateIssueRecord(Jira_Issue__c existingIssue, Map<String, Object> issueData) {
        Map<String, Object> fields = (Map<String, Object>) issueData?.get('fields');
        Map<String, Object> status = (Map<String, Object>) fields?.get('status');
        Map<String, Object> issueType = (Map<String, Object>) fields?.get('issuetype');
        Map<String, Object> project = (Map<String, Object>) fields?.get('project');

        // Always set Last_Updated__c since it's never null
        existingIssue.Last_Updated__c = Datetime.now();
        
        String issueDescription = (String) fields?.get('description');
        if (String.isNotBlank(issueDescription)) {
            existingIssue.Description__c = issueDescription;
        }
        
        String issueKey = (String) issueData?.get('key');
        if (String.isNotBlank(issueKey)) {
            existingIssue.Issue_Key__c = issueKey;
        }
        
        String issueTypeName = (String) issueType?.get('name');
        if (String.isNotBlank(issueTypeName)) {
            existingIssue.Issue_Type__c = issueTypeName;
        }
        
        String projectKey = (String) project?.get('key');
        if (String.isNotBlank(projectKey)) {
            existingIssue.Project_Key__c = projectKey;
        }
        
        String issueStatus = (String) status?.get('name');
        if (String.isNotBlank(issueStatus)) {
            existingIssue.Status__c = issueStatus;
        }
        
        String issueSummary = (String) fields?.get('summary');
        if (String.isNotBlank(issueSummary)) {
            existingIssue.Summary__c = issueSummary;
        }

        return existingIssue;
    }
    
    private Jira_Project__c createProjectRecord(Map<String, Object> projectData) {
        Jira_Project__c newProject = new Jira_Project__c();

        String projectDescription = (String) projectData?.get('description');
        if (String.isNotBlank(projectDescription)) {
            newProject.Description__c = projectDescription;
        }

        String projectName = (String) projectData?.get('name');
        if (String.isNotBlank(projectName)) {
            newProject.Name = projectName;
            newProject.Project_Name__c = projectName;
        }

        String projectId = (String) projectData?.get('id');
        if (String.isNotBlank(projectId)) {
            newProject.Project_ID__c = projectId;
        }

        String projectKey = (String) projectData?.get('key');
        if (String.isNotBlank(projectKey)) {
            newProject.Project_Key__c = projectKey;
        }

        return newProject;
    }
    
    private Jira_Project__c updateProjectRecord(Jira_Project__c existingProject, Map<String, Object> projectData) {
        String projectDescription = (String) projectData?.get('description');
        if (String.isNotBlank(projectDescription)) {
            existingProject.Description__c = projectDescription;
        }

        String projectName = (String) projectData?.get('name');
        if (String.isNotBlank(projectName)) {
            existingProject.Name = projectName;
            existingProject.Project_Name__c = projectName;
        }

        String projectId = (String) projectData?.get('id');
        if (String.isNotBlank(projectId)) {
            existingProject.Project_ID__c = projectId;
        }

        String projectKey = (String) projectData?.get('key');
        if (String.isNotBlank(projectKey)) {
            existingProject.Project_Key__c = projectKey;
        }

        return existingProject;
    }

    public class JiraWebhookProcessorException extends Exception {}
} 