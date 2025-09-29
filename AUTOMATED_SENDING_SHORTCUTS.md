# BulkMess Automated Sending Shortcuts Guide

This guide covers the automated message sending shortcuts that eliminate the need for manual approval of each message.

## 🎯 Available Automated Shortcuts

### 1. **BulkMess Auto Send**
- **Purpose**: Send all messages automatically without any manual approval
- **Best for**: Small to medium campaigns (up to 100 messages)
- **Key Features**:
  - Zero manual intervention required
  - Reads message data from clipboard
  - 1-second delay between messages
  - Completion notification

### 2. **BulkMess Batch Processor**
- **Purpose**: Advanced batch processing with configurable delays and error handling
- **Best for**: Large campaigns (100+ messages)
- **Key Features**:
  - Configurable batch sizes
  - Custom delays between batches
  - Error counting and reporting
  - Rate limiting protection

## 🚀 Quick Setup

### Step 1: Install the Shortcuts
1. Open BulkMess app
2. Go to **Settings** → **Automated Integration** → **iOS Shortcuts**
3. Tap **"Install All Shortcuts"**
4. Or install individually:
   - Tap on **"BulkMess Auto Send"** → **Install**
   - Tap on **"BulkMess Batch Processor"** → **Install**

### Step 2: Configure iOS Settings
1. Open **iOS Settings** → **Shortcuts** → **Advanced**
2. Enable these settings:
   - ✅ **Allow Running Scripts**
   - ✅ **Allow Sharing Large Amounts of Data**
   - ✅ **Allow Untrusted Shortcuts** (if needed)

### Step 3: Configure Shortcut Settings
1. Open **iOS Shortcuts app**
2. Find **"BulkMess Auto Send"** shortcut
3. Tap the **⚙️ Settings** icon
4. **IMPORTANT**: Turn **OFF** "Ask Before Running"
5. Turn **ON** "Use with Siri" (optional)
6. Repeat for **"BulkMess Batch Processor"**

## 📱 How to Use

### Method 1: From BulkMess App (Recommended)

**When creating/sending a campaign:**
1. Create your campaign normally in BulkMess
2. Instead of "Send Campaign", look for **"Send via Auto Shortcut"** button
3. Choose your preferred method:
   - **"Auto Send"** - Simple automatic sending
   - **"Batch Processor"** - Advanced batch sending
4. The shortcut will run automatically and send all messages

### Method 2: Manual Execution

**For Auto Send:**
1. Copy this JSON format to clipboard:
```json
{
  "messages": [
    {"phone": "+1234567890", "message": "Hello John!"},
    {"phone": "+0987654321", "message": "Hello Jane!"}
  ]
}
```
2. Run "BulkMess Auto Send" shortcut
3. Messages send automatically

**For Batch Processor:**
1. Copy this JSON format to clipboard:
```json
{
  "messages": [
    {"phone": "+1234567890", "message": "Hello John!"},
    {"phone": "+0987654321", "message": "Hello Jane!"}
  ],
  "batchSize": 10,
  "delaySeconds": 2
}
```
2. Run "BulkMess Batch Processor" shortcut
3. Messages send in batches with delays

## ⚙️ Configuration Options

### Auto Send Settings
- **Delay between messages**: 1 second (fixed)
- **Error handling**: Basic (continues on error)
- **Best for**: Up to 100 messages

### Batch Processor Settings
- **batchSize**: Number of messages per batch (default: 10)
- **delaySeconds**: Delay between batches (default: 2 seconds)
- **Error handling**: Advanced (counts and reports errors)
- **Best for**: 100+ messages

## 🔧 Advanced Configuration

### Custom JSON Payload Examples

**Simple campaign:**
```json
{
  "messages": [
    {"phone": "+1234567890", "message": "Hi! This is a test message."},
    {"phone": "+1987654321", "message": "Hi! This is a test message."}
  ]
}
```

**Large campaign with custom settings:**
```json
{
  "messages": [
    {"phone": "+1234567890", "message": "Personalized message for John"},
    {"phone": "+1987654321", "message": "Personalized message for Jane"}
  ],
  "batchSize": 5,
  "delaySeconds": 3
}
```

**Template variables (process in BulkMess first):**
```json
{
  "messages": [
    {"phone": "+1234567890", "message": "Hello {{firstName}}! Your order is ready."},
    {"phone": "+1987654321", "message": "Hello {{firstName}}! Your order is ready."}
  ]
}
```

## 🛡️ Safety Features

### Rate Limiting Protection
- **Auto Send**: 1-second delays prevent rate limiting
- **Batch Processor**: Configurable delays between batches
- **Error Handling**: Continues sending even if some messages fail

### Privacy & Security
- Messages are processed locally on your device
- No data sent to external servers
- Uses iOS's native message sending
- Clipboard data is automatically cleared after use

## 🐛 Troubleshooting

### Common Issues & Solutions

**"Ask Before Running" still appears:**
1. Open iOS Shortcuts app
2. Find your shortcut → Tap settings (⚙️)
3. Turn OFF "Ask Before Running"
4. Save settings

**Messages not sending:**
1. Check iOS Settings → Shortcuts → Advanced settings
2. Ensure "Allow Running Scripts" is enabled
3. Verify your device can send SMS messages
4. Check clipboard contains valid JSON

**Shortcut not found:**
1. Make sure shortcut is installed in iOS Shortcuts app
2. Check shortcut name matches exactly: "BulkMess Auto Send"
3. Reinstall shortcut from BulkMess app

**Batch processing stopping:**
1. Increase delay between batches (try 3-5 seconds)
2. Reduce batch size (try 5-8 messages per batch)
3. Check for network connectivity issues

### JSON Format Validation

**Valid JSON format:**
```json
{
  "messages": [
    {"phone": "+1234567890", "message": "Text here"}
  ]
}
```

**Invalid formats to avoid:**
```json
// ❌ Missing quotes around keys
{messages: [{phone: "+1234567890", message: "Text"}]}

// ❌ Single quotes instead of double quotes
{'messages': [{'phone': '+1234567890', 'message': 'Text'}]}

// ❌ Trailing commas
{
  "messages": [
    {"phone": "+1234567890", "message": "Text"},
  ],
}
```

## 📊 Performance Guidelines

### Message Volume Recommendations

| Campaign Size | Recommended Method | Batch Size | Delay |
|--------------|-------------------|------------|--------|
| 1-50 messages | Auto Send | N/A | 1 sec |
| 51-200 messages | Batch Processor | 10 | 2 sec |
| 201-500 messages | Batch Processor | 8 | 3 sec |
| 500+ messages | Batch Processor | 5 | 5 sec |

### Optimal Settings by Use Case

**Marketing campaigns (non-urgent):**
- Batch size: 5-8 messages
- Delay: 3-5 seconds
- Best time: Off-peak hours

**Urgent notifications:**
- Use Auto Send for immediate delivery
- Maximum 100 messages at once
- Consider follow-up batches for larger lists

**Customer service follow-ups:**
- Batch size: 10 messages
- Delay: 2 seconds
- Include personalization

## 🎯 Best Practices

1. **Test First**: Always test with 1-2 messages before running large campaigns
2. **Use Templates**: Process templates in BulkMess before sending to shortcuts
3. **Monitor Results**: Check completion notifications for success/error counts
4. **Respect Limits**: Don't exceed your carrier's sending limits
5. **Time Appropriately**: Send during business hours for better engagement
6. **Personalize Messages**: Use contact names and relevant information
7. **Follow Regulations**: Comply with SMS marketing laws and regulations

## 🆘 Support

If you encounter issues:
1. Check this troubleshooting guide first
2. Verify your iOS Settings → Shortcuts configuration
3. Test with a simple 2-message campaign
4. Check iOS Shortcuts app for error messages
5. Ensure BulkMess app is updated to latest version

## 🔄 Updates & Maintenance

**Keep shortcuts updated:**
1. Reinstall shortcuts when BulkMess app updates
2. Check iOS Settings after iOS updates
3. Test shortcuts after major iOS updates
4. Backup your shortcut configurations

Your automated sending setup is now complete! You can send bulk messages without any manual approval for each message. 🎉