# BulkMess - App Store Description

## App Store Connect Description

### Short Description (Max 170 characters)
Professional SMS campaign manager with smart templates, bulk messaging, and automated delivery. Premium subscription required for unlimited campaigns.

---

### Full Description

Transform your communication with BulkMess - the professional SMS campaign manager designed for businesses, event coordinators, and anyone who needs to reach multiple contacts efficiently.

**IMPORTANT: BulkMess requires a paid subscription to access premium features including unlimited campaigns, bulk messaging, and advanced automation.**

## ✨ PREMIUM FEATURES (Subscription Required)

**Unlimited Campaigns**
• Send messages to hundreds of contacts instantly
• Bulk SMS campaigns with intelligent batching
• Automated follow-up sequences
• Response-based messaging

**Custom Templates**
• Personalized messages with {{firstName}}, {{lastName}} placeholders
• Dynamic message templates for different audiences
• Template library management

**Advanced Analytics**
• Real-time campaign progress tracking
• Delivery success rates and failure analysis
• Response rate monitoring
• Export capabilities for reporting

**iOS Shortcuts Integration**
• True automation with system-level integration
• Automated response-based messaging
• Webhook support for enterprise integrations

## 📱 FREE FEATURES

• Contact management and organization
• Basic message creation
• Campaign preview and testing
• iOS Messages integration
• Secure local data storage

## 💰 SUBSCRIPTION PRICING

**Weekly Plan** - $9.99/week
• 3-day free trial
• Cancel anytime
• Full access to all premium features

**Yearly Plan** - $36.99/year (BEST VALUE)
• Save 69% compared to weekly plan
• Just $3.08/month
• Full access to all premium features

**Auto-Renewal Terms:**
• Payment charged to Apple ID at confirmation of purchase
• Subscription automatically renews unless cancelled at least 24 hours before period ends
• Manage and cancel subscriptions in App Store account settings
• No refunds for unused portion of subscription

## 🔒 PRIVACY & SECURITY

• All contacts and messages stored locally on your device
• No cloud storage of personal data
• Industry-standard encryption
• No third-party data sharing

## 📚 DOCUMENTATION & SUPPORT

• Comprehensive in-app tutorials
• 24-48 hour support response time
• Active community support

**Terms of Use:** https://dan1sl6nd.github.io/BulkMess/terms.html
**Privacy Policy:** https://dan1sl6nd.github.io/BulkMess/privacy.html
**Support:** support@bulkmessapp.com

## ⚡ REQUIREMENTS

• iOS 14.0 or later
• iPhone with cellular capability
• Active cellular service
• iOS Messages app access

---

## 🎯 WHO IS BULKMESS FOR?

**Business Communications**
Reach customers with personalized bulk messages, promotional campaigns, and announcements.

**Event Coordination**
Send event invitations, updates, and reminders to large groups efficiently.

**Community Management**
Keep your community informed with automated messaging and follow-ups.

**Customer Service**
Manage customer communications at scale with templates and tracking.

---

**Download BulkMess today and transform your messaging workflow!**

*Premium subscription required for unlimited campaigns and advanced features. Free trial available.*

---

## App Store Connect Settings Checklist

### Category
- **Primary Category:** Productivity
- **Secondary Category:** Business

### Age Rating
- 4+ (No objectionable content)

### Copyright
- © 2024 Daniil Mukashev

### Privacy Policy URL
- https://dan1sl6nd.github.io/BulkMess/privacy.html

### Terms of Use (EULA)
**Option 1:** Add to App Description (see above - link included)
**Option 2:** Upload custom EULA in App Store Connect using terms.html content

### App Previews and Screenshots
Ensure screenshots clearly show:
- Subscription screen with pricing
- Premium feature badges/indicators
- "Upgrade to Premium" messaging for locked features

### In-App Purchases
Ensure both subscription products are properly configured:
- com.bulkmess.weekly ($9.99/week, 3-day free trial)
- com.bulkmess.yearly ($36.99/year)

### Promotional Text (Optional, 170 chars max)
NEW: Save 69% with our Yearly Plan! Get unlimited campaigns, custom templates, and advanced analytics. Try free for 3 days!

---

## Keywords (Max 100 characters, comma-separated)
sms,bulk,messaging,campaign,marketing,template,automation,business,group,text

---

## Review Notes for Apple

Dear App Review Team,

Thank you for your feedback on submission 2d5296b5-7964-48ce-afba-be1071f6aee6. We have carefully addressed all three guidelines mentioned in your review:

---

### Guideline 5.0 - Legal Compliance

**Your Concern:** The app contains content that facilitates mass texting, which may not be legal in all locations.

**Our Response:**

BulkMess is designed exclusively for **legitimate business communications** and is not intended for unsolicited mass messaging or spam. The app is specifically built for:

1. **Small business customer communications** - Appointment reminders, order updates, customer service
2. **Event coordination** - Invitations and updates to attendees who have opted in
3. **Community management** - Updates to organization members who have consented
4. **Personal group messaging** - Coordinating with friends, family, or teams

**Important Legal Safeguards:**
- The app integrates with iOS Messages, which inherently limits sending capabilities through Apple's rate limiting
- Users can only message contacts they have manually added or imported from their device
- The app does not provide phone number lists or facilitate unsolicited messaging
- Our Terms of Service explicitly prohibit spam and require users to comply with local laws (TCPA in US, GDPR in EU, etc.)
- We include in-app warnings about compliance with anti-spam regulations

**Comparison to Similar Apps:**
BulkMess functions similarly to other approved bulk messaging apps on the App Store that use iOS Messages integration for legitimate business communications. We comply with all applicable regulations including TCPA, CAN-SPAM Act, and GDPR.

We have also removed "mass" from our keywords to avoid any confusion about the app's legitimate business purpose.

---

### Guideline 2.1 - Information Needed

**Question 1: Will the contacts data be uploaded and stored to any server?**

**Answer:** **NO.** All contacts data is stored exclusively on the user's local device using iOS Core Data. We do NOT upload, store, or transmit contact information to any server or cloud service. This is clearly documented in:
- Our Privacy Policy (Section "Data Storage & Security - Local Storage")
- In-app privacy explanations
- App Store description

**Question 2: What will you do with the contacts data once it is gathered?**

**Answer:** The contacts data is used exclusively for:
1. **Local storage and organization** - Storing contact information in the app's local database
2. **Message personalization** - Applying template variables ({{firstName}}, {{lastName}})
3. **Campaign management** - Organizing contacts into groups for targeted messaging
4. **iOS Messages integration** - Passing phone numbers to iOS Messages app to send SMS (standard iOS behavior)

The data NEVER leaves the user's device except when the user explicitly sends a message through iOS Messages (which is the core functionality). We have no backend servers that collect or process user data.

---

### Guideline 5.1.1 - Privacy - Permission Request

**Your Concern:** The app displays a custom message with a "Grant permission" button before the system permission request.

**Resolution:** ✅ **FIXED**

We have changed the button text from "Grant permission" to "Continue" in the contacts permission view (ContactsView.swift:290). The button now uses appropriate, non-directive language as required by Apple's guidelines.

---

### Additional Information

**Privacy & Data Handling Summary:**
- ✅ All data stored locally using Core Data
- ✅ No backend servers or cloud storage
- ✅ No third-party analytics or tracking
- ✅ Full GDPR, CCPA, and PIPEDA compliance
- ✅ Complete Privacy Policy: https://dan1sl6nd.github.io/BulkMess/privacy.html
- ✅ Terms of Service prohibit spam: https://dan1sl6nd.github.io/BulkMess/terms.html

**Contact Information:**
- Email: support@bulkmessapp.com
- Response time: 24-48 hours

We believe these changes fully address all concerns raised in your review. Thank you for helping us ensure BulkMess meets Apple's high standards for user privacy and legal compliance.

Best regards,
Daniil Mukashev
