# Cloud Code Academy - Integration Developer Program

## Lesson 5: Jira Integration with Salesforce (Part 2)

This assignment focuses on implementing inbound integration from Jira to Salesforce using webhooks, completing the bidirectional synchronization between the two systems.

## 🎯 Learning Objectives

By the end of this lesson, you will be able to:

- Configure and implement a Salesforce webhook endpoint to receive data from Jira
- Set up a Salesforce Site to expose Apex REST endpoints to external systems
- Process incoming webhook payloads from Jira in Salesforce
- Implement robust error handling for inbound integrations
- Maintain data consistency between Salesforce and Jira

## 📋 Assignment Overview

In this assignment, you will be implementing the inbound part of a Jira integration with Salesforce. The application will receive webhook notifications from Jira when projects and issues are created, updated, or deleted, and will update the corresponding Salesforce records.

Your implementation must:

1. Receive webhook notifications from Jira via Apex REST
2. Process different webhook events (create, update, delete) for both projects and issues
3. Update or create corresponding Salesforce records based on the webhook payload
4. Implement proper security measures for the webhook endpoint
5. Handle errors gracefully and log issues for troubleshooting

## 🔨 Prerequisites

1. A Jira Cloud account (sign up at https://www.atlassian.com/software/jira/free)
2. A Salesforce Developer org with the Salesforce custom objects from previous assignment
3. Access to configure a Salesforce Site
4. Properly configured webhook in Jira pointing to your Salesforce endpoint

## ✍️ Assignment Tasks

Your tasks for this assignment include:

1. Implement `JiraWebhookService` class for processing incoming webhook payloads
2. Complete the `JiraWebhookController` class to expose REST endpoints
3. Implement the `JiraWebhookPayloadProcessor` class to handle different webhook events
4. Configure a Salesforce Site to expose the webhook endpoint
5. Configure webhooks in Jira to send notifications to your Salesforce endpoint

## 🏭 Factory Pattern for Webhook Processing

For this implementation, we recommend using the Factory Method design pattern to handle different types of webhook events. The Factory Method pattern is a creational design pattern that provides an interface for creating objects in a superclass, but allows subclasses to alter the type of objects that will be created.

### How the Factory Pattern Works

1. **Define an interface or abstract class** for creating webhook event processors
2. **Create concrete implementations** for each type of webhook event (Project Created, Issue Updated, etc.)
3. **Use a factory method** to instantiate the appropriate processor based on the webhook payload

### Implementation Example

```apex
// Abstract processor interface
public interface WebhookEventProcessor {
    void process(Map<String, Object> payload);
}

// Concrete implementation for Issue Created events
public class IssueCreatedProcessor implements WebhookEventProcessor {
    public void process(Map<String, Object> payload) {
        // Process issue created event
    }
}

// Factory class
public class WebhookProcessorFactory {
    public static WebhookEventProcessor createProcessor(String eventType) {
        switch(eventType) {
            case 'jira:issue_created':
                return new IssueCreatedProcessor();
            case 'jira:project_updated':
                return new ProjectUpdatedProcessor();
            // Additional cases for other event types
            default:
                throw new UnsupportedEventException('Unsupported event type: ' + eventType);
        }
    }
}
```

### Benefits of Using Factory Pattern for Webhooks

1. **Scalability**: As more webhook event types are added (from Jira or other systems), you can simply create new processor classes without modifying existing code
2. **Separation of Concerns**: Each processor class handles only one type of event, making the code cleaner and easier to maintain
3. **Testability**: Individual processor classes can be unit tested in isolation
4. **Open/Closed Principle**: The code is open for extension (adding new processors) but closed for modification (existing processors don't need to change)

For more information on the Factory Method pattern, visit [Refactoring.Guru](https://refactoring.guru/design-patterns/factory-method).

## 🔑 Salesforce Site Setup

To expose your webhook endpoint to Jira, you need to set up a Salesforce Site:

1. Setup > User Interface > Sites and Domains > Sites
2. Register a My Domain if you haven't already (this may take some time to propagate)
3. Once your domain is active, click "New" to create a new site
4. Configure your site with a unique name, label, and active status
5. Make note of the site URL - you'll need this for your Jira webhook configuration

## 🔒 Guest User Profile Configuration

To allow the webhook to create/update records, you need to configure the guest user profile:

1. Go to the Site you created
2. Click on "Public Access Settings"
3. In the Profile page, navigate to "Assigned Apex Classes"
4. Add your webhook classes to the "Enabled Apex Class Access" list
5. Navigate to "Object Settings" and ensure the guest user has proper access to Jira_Project__c and Jira_Issue__c objects

**Note:** For security reasons, in some cases you might need to use "without sharing" in your Apex classes to allow the guest user to access and modify data.

## 🔌 Jira Webhook Configuration

To set up webhooks in Jira:

1. Go to your Jira instance settings (gear icon) > System > Webhooks
2. Click "Create webhook"
3. Enter a name for your webhook
4. For the URL, use your Salesforce Site URL + '/services/apexrest/webhook/jira'
5. For events, select:
   - Issue: created, updated, deleted
   - Project: created, updated, deleted
6. Save your webhook configuration

You can visit this URL to configure your webhooks: https://your-domain.atlassian.net/plugins/servlet/webhooks#

## 🧪 Testing Your Webhook

Before connecting to Jira, you can test your webhook implementation:

1. Use a tool like [Webhook.site](https://webhook.site) to capture and inspect webhooks
2. Configure a test webhook in Jira pointing to your Webhook.site URL
3. Perform actions in Jira and observe the payloads
4. Use these payloads to test your Apex code before exposing your Salesforce endpoint

## 🎯 Success Criteria

Your implementation should:

- Successfully receive webhook notifications from Jira
- Process different webhook events correctly
- Create or update Salesforce records based on Jira changes
- Handle errors gracefully with proper error logging
- Maintain data consistency between Salesforce and Jira

## 💡 Tips

- Review the [Jira Webhook documentation](https://developer.atlassian.com/server/jira/platform/webhooks/)
- Use System Debug logs to troubleshoot webhook processing
- Implement proper security checks in your webhook endpoint
- Test with Webhook.site before connecting to your Salesforce org
- Remember that webhooks need to process quickly (under 10 seconds)

## 📚 Resources

- [Apex REST API Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_rest.htm)
- [Salesforce Sites Documentation](https://help.salesforce.com/articleView?id=sites_overview.htm)
- [Guest User Security Best Practices](https://help.salesforce.com/articleView?id=sf.networks_guest_user_access.htm)
- [Jira Webhook Documentation](https://developer.atlassian.com/server/jira/platform/webhooks/)
- [Testing Webhooks with Webhook.site](https://webhook.site)

## 🏆 Extra Credit - Optional Challenge

Once you've completed the basic implementation, try these challenges:

1. Implement a queueable process for handling webhook events asynchronously
2. Add webhook event logging to track all incoming notifications
3. Create a Lightning component to monitor webhook activity
4. Implement a custom authentication mechanism for your webhook endpoint

## ❓ Support

If you need help:

- Review the Jira webhook documentation
- Check the provided code structure for guidance
- Use Webhook.site to test and debug payloads
- Reach out to your instructor

---

Happy coding! 🚀

_This is part of the Cloud Code Academy Integration Developer certification program._

## Copyright

© 2025 Cloud Code. All rights reserved.

This software is provided under the Cloud Code Developer Kickstart Program License (CCDKPL) Version 1.0.
The software is licensed, not sold, and is intended for personal educational purposes only as part of the Cloud Code Developer Kickstart Program.

See the full license terms in LICENSE.md for more details regarding usage restrictions, ownership, warranties, and limitations of liability.
