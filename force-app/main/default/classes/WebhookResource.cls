@RestResource(urlMapping='/webhook/*')
global without sharing class WebhookResource {
    
    @HttpPost
    global static ResponseWrapper doPost() {
        RestRequest request = RestContext.request;
        try {
            WebhookFactory.processWebhook(getWebhookTypeFromPath(request.requestURI), request);
            return new ResponseWrapper('success', 'successfully processed request');
        } catch (Exception e) {
            return new ResponseWrapper('error', e.getMessage());
        }
    }
    
    private static String getWebhookTypeFromPath(String path) {
        System.debug('getWebhookTypeFromPath: ' + path);
        // Expected formats: /webhook/jira or /services/apexrest/webhook/jira
        if (path == null) {
            return '';
        }
        
        // Look for the webhook segment in the path
        Integer webhookIndex = path.indexOf('/webhook/');
        
        if (webhookIndex >= 0) {
            // Extract the part after /webhook/
            String remaining = path.substring(webhookIndex + 9);
            System.debug('remaining: ' + remaining);
            
            // If there are additional slashes, only take the first segment
            Integer nextSlash = remaining.indexOf('/');
            if (nextSlash > 0) {
                System.debug('nextSlash: ' + nextSlash);
                return remaining.substring(0, nextSlash).toLowerCase();
            }
            
            return remaining.toLowerCase();
        }
        
        return '';
    }
    
    global class ResponseWrapper {
        public String status;
        public String message;
        
        public ResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message;
        }
    }
} 