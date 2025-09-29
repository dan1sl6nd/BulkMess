# BulkMess Automated Integration Setup Guide

This guide will help you set up automated integration to automatically cancel follow-ups when contacts respond to your campaigns.

## Overview

BulkMess provides several integration methods to automatically detect message responses and cancel scheduled follow-ups:

1. **iOS Shortcuts Integration** - Automatically detect responses using iOS Shortcuts
2. **URL Scheme Integration** - Use URL schemes for external app integrations
3. **Webhook/API Integration** - Receive notifications from external services
4. **Notification Actions** - Quick response marking from notifications

## 1. iOS Shortcuts Integration

### Setup Steps:

1. **Configure URL Scheme** (First time setup):
   - Open your BulkMess project in Xcode
   - Go to Project Settings → Info tab → URL Types
   - Add new URL Type with:
     - Identifier: `com.bulkmess.urlscheme`
     - URL Schemes: `bulkmess`

2. **Create Response Detection Shortcut**:

```json
{
  "name": "BulkMess Auto Response",
  "actions": [
    {
      "type": "Get Messages",
      "parameters": {
        "filter": "unread"
      }
    },
    {
      "type": "Text Processing",
      "parameters": {
        "extract": "phone_number"
      }
    },
    {
      "type": "Open URL",
      "parameters": {
        "url": "bulkmess://record-response?phone={{phone}}&message={{content}}"
      }
    }
  ]
}
```

3. **Set Up Automation**:
   - Open iOS Shortcuts app
   - Create new Automation: "When I receive a message"
   - Add action: "Run Shortcut" → Select "BulkMess Auto Response"

### URL Scheme Usage:

```
# Record a response
bulkmess://record-response?phone=+1234567890&message=Thanks!

# Cancel follow-ups
bulkmess://cancel-followup?phone=+1234567890

# Check all campaigns for responses
bulkmess://check-responses
```

## 2. Notification Actions

### Features:
- **Send Now** - Send the follow-up immediately
- **They Responded** - Mark contact as responded (cancels future follow-ups)
- **Cancel** - Cancel this specific follow-up

### Setup:
No setup required - notification actions are automatically enabled when you schedule follow-ups.

## 3. Webhook/API Integration

### Starting the Webhook Server:

```swift
// In your app code
let webhookService = WebhookService(messageMonitoringService: messageMonitoringService)
webhookService.startWebhookServer() // Starts server on port 8080
```

### API Endpoints:

#### Record Message Response
```bash
POST http://localhost:8080/webhook/message-received
Content-Type: application/json

{
  "phoneNumber": "+1234567890",
  "messageContent": "Thanks for the message!",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### Cancel Follow-ups
```bash
POST http://localhost:8080/webhook/cancel-followup
Content-Type: application/json

{
  "phoneNumber": "+1234567890"
}
```

#### Trigger Response Check
```bash
POST http://localhost:8080/webhook/check-responses
Content-Type: application/json

{}
```

### Example Integrations:

#### Zapier Integration:
1. Create new Zap: "When SMS received in [SMS Service]"
2. Add action: "Webhooks by Zapier"
3. Method: POST
4. URL: `http://your-server:8080/webhook/message-received`
5. Data: Map phone number and message content

#### Third-party SMS Services:
Most SMS services support webhooks. Configure them to send POST requests to your webhook endpoint when messages are received.

## 4. Manual Response Management

### Using the App Interface:

1. **Contact Detail View**:
   - Open any contact
   - Scroll to "Message Activity" section
   - Tap "Mark as Responded" to cancel follow-ups

2. **Campaign Management**:
   - Open campaign details
   - Tap "Response Tracking" section
   - Use "Manage Responses" to bulk manage contact responses

3. **Pending Follow-ups View**:
   - View all scheduled follow-ups
   - Manually cancel individual follow-ups
   - Track response rates

## 5. Testing Your Integration

### Test URL Scheme Integration:
```bash
# Open this URL in Safari or use simulator
bulkmess://record-response?phone=%2B1234567890&message=Test%20response
```

### Test Webhook Integration:
```bash
curl -X POST http://localhost:8080/webhook/message-received \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+1234567890", "messageContent": "Test response"}'
```

### Test Notification Actions:
1. Create a campaign with follow-ups scheduled for immediate delivery
2. Wait for notification to appear
3. Long-press notification to see action buttons
4. Test each action: "Send Now", "They Responded", "Cancel"

## 6. Troubleshooting

### Common Issues:

**URL Scheme not working:**
- Ensure URL scheme is properly configured in Xcode
- Check that the scheme is `bulkmess` (lowercase)
- Verify parameters are URL-encoded

**Webhook server not receiving requests:**
- Check if server is running: Look for "Webhook server started" message
- Verify port 8080 is not blocked by firewall
- Test with localhost first before external connections

**Notification actions not appearing:**
- Check notification permissions are granted
- Ensure notification categories are registered
- Verify follow-up notifications have correct category

**Responses not cancelling follow-ups:**
- Check contact phone numbers match exactly
- Verify MessageMonitoringService is properly initialized
- Look for console logs indicating successful response recording

### Debug Logs:

Enable debug logging to troubleshoot:
```swift
// Add to your app delegate
print("Webhook server status: \(webhookService.isListening)")
print("Received webhooks: \(webhookService.receivedWebhooks.count)")
```

## 7. Best Practices

1. **Phone Number Formatting**: Ensure consistent phone number formatting across all integrations (e.g., always use +1234567890 format)

2. **Response Deduplication**: The system automatically handles duplicate responses for the same contact

3. **Error Handling**: Always include error handling in your integration code

4. **Security**: If using webhooks over the internet, implement proper authentication

5. **Testing**: Test all integration methods in development before deploying

## 8. Advanced Configurations

### Custom Response Processing:
```swift
// Extend MessageMonitoringService for custom logic
extension MessageMonitoringService {
    func processCustomResponse(phoneNumber: String, content: String) {
        // Add custom business logic here
        if content.contains("STOP") {
            // Handle unsubscribe requests
        } else if content.contains("MORE") {
            // Handle requests for more information
        }

        // Record the response
        recordIncomingMessage(fromPhoneNumber: phoneNumber, content: content)
    }
}
```

### Webhook Authentication:
```swift
// Add authentication to webhook service
private func validateWebhookAuth(headers: [String: String]) -> Bool {
    guard let auth = headers["Authorization"],
          auth == "Bearer your-secret-token" else {
        return false
    }
    return true
}
```

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review console logs for error messages
3. Test with simplified examples first
4. Verify all dependencies are properly configured

## Integration Checklist

- [ ] URL scheme configured in Xcode
- [ ] iOS Shortcuts automation created
- [ ] Notification permissions granted
- [ ] Webhook server tested locally
- [ ] Third-party service webhooks configured
- [ ] Manual response management tested
- [ ] Integration thoroughly tested with sample data

Your automated integration setup is now complete! The system will automatically cancel follow-ups when contacts respond to your campaigns.