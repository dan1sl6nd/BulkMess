# Facebook SDK Setup Guide for BulkMess

## ✅ What's Already Done

I've already set up the following for you:

1. ✅ Created `FacebookAnalyticsService.swift` with tracking methods
2. ✅ Updated `Info.plist` with Facebook configuration (placeholders)
3. ✅ Added Facebook SDK initialization to `BulkMessApp.swift`
4. ✅ Integrated tracking into:
   - Purchase events (subscriptions)
   - Onboarding completion
   - Campaign creation
   - Campaign completion
5. ✅ Set up app activation tracking

---

## 🚀 Steps You Need to Complete

### **Step 1: Install Facebook SDK Package**

1. Open `BulkMess.xcodeproj` in Xcode
2. Select your project in the navigator
3. Select the **BulkMess** target
4. Go to the **"Package Dependencies"** tab
5. Click the **"+"** button
6. Enter this URL:
   ```
   https://github.com/facebook/facebook-ios-sdk
   ```
7. Click **"Add Package"**
8. Select version: **Latest** (recommended)
9. Select these products:
   - ✅ **FacebookCore**
   - ✅ **FacebookBasics**
10. Click **"Add Package"**

---

### **Step 2: Create Facebook App**

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click **"My Apps"** → **"Create App"**
3. Select app type: **"Business"** or **"Consumer"**
4. Fill in details:
   - App Name: **BulkMess**
   - Contact Email: **support@bulkmessapp.com** (or your email)
5. Click **"Create App"**

---

### **Step 3: Get Your Facebook App Credentials**

1. In your Facebook App dashboard, go to **Settings** → **Basic**
2. Find and copy:
   - **App ID** (e.g., `123456789012345`)
   - **App Secret** (click "Show" to reveal)

⚠️ **Keep your App Secret secure! Never commit it to public repositories.**

---

### **Step 4: Update Info.plist with Your App ID**

Open `/Users/dan1sland/Documents/Claude/BulkMess/BulkMess/Info.plist` and replace:

**Replace this:**
```xml
<key>FacebookAppID</key>
<string>YOUR_APP_ID</string>
```

**With your actual App ID:**
```xml
<key>FacebookAppID</key>
<string>123456789012345</string>
```

**Also replace this:**
```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>fbYOUR_APP_ID</string>
</array>
```

**With:**
```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>fb123456789012345</string>
</array>
```

---

### **Step 5: Configure Facebook App Settings**

In your Facebook App dashboard:

#### **5.1 Add iOS Platform**

1. Go to **Settings** → **Basic**
2. Scroll down to **"Add Platform"**
3. Select **"iOS"**
4. Fill in:
   - **Bundle ID**: `com.bulkmess.app` (or your actual bundle ID)
   - **App Store ID**: (leave blank for now, add after App Store approval)

#### **5.2 Configure App Events**

1. Go to **App Events** in the left sidebar
2. Enable these events:
   - ✅ App Installs
   - ✅ Purchases
   - ✅ Custom Events

#### **5.3 Set Up Data Processing Options (Required for iOS 14+)**

1. Go to **Settings** → **Advanced**
2. Enable **"Limited Data Use"** if targeting California users (CCPA compliance)

---

### **Step 6: Test Your Integration**

#### **6.1 Build and Run**

1. Build your app in Xcode (⌘ + B)
2. Fix any compilation errors
3. Run on simulator or device

#### **6.2 Check Facebook Event Manager**

1. Open Facebook Events Manager: https://www.facebook.com/events_manager2/
2. Select your app
3. Go to **"Test Events"**
4. You should see events coming in when you:
   - Open the app → `fb_mobile_activate_app`
   - Complete onboarding → `OnboardingCompleted`
   - Subscribe → `fb_mobile_purchase`
   - Create campaign → `CampaignCreated`

#### **6.3 Verify in Xcode Console**

Look for these log messages:
```
📊 Facebook: App activated
📊 Facebook: Onboarding completed
📊 Facebook: Purchase tracked - weekly ($9.99)
📊 Facebook: Campaign created - 50 recipients
📊 Facebook: Campaign completed - 98% success rate
```

---

### **Step 7: Set Up Facebook Ads (For Advertising)**

#### **7.1 Create Facebook Business Manager Account**

1. Go to [business.facebook.com](https://business.facebook.com)
2. Create a Business Manager account
3. Add your Facebook App to Business Manager

#### **7.2 Create Facebook Ad Account**

1. In Business Manager, go to **Business Settings**
2. Click **Accounts** → **Ad Accounts**
3. Click **Add** → **Create a new ad account**

#### **7.3 Connect Your App**

1. In Business Manager, go to **Business Settings**
2. Click **Data Sources** → **Apps**
3. Click **Add** and select your BulkMess app
4. Verify ownership

#### **7.4 Set Up App Events for Ads**

1. Go to **Events Manager**
2. Select your app
3. Go to **Settings** → **Configure Web Events**
4. Enable these events as **Custom Conversions**:
   - `StartTrial` → Trial Started
   - `fb_mobile_purchase` → Purchase
   - `CampaignCreated` → Engaged User
   - `CampaignCompleted` → Power User

---

### **Step 8: Privacy Compliance (IMPORTANT)**

#### **8.1 Update Privacy Policy**

Add to your privacy policy that you use Facebook Analytics. Example:

```
Analytics & Advertising

We use Facebook Analytics and Facebook Ads to:
- Track app usage and performance
- Measure advertising campaign effectiveness
- Understand user behavior and improve our services

Data shared with Facebook includes:
- App install events
- In-app purchase events
- Custom app events (campaign creation, template usage)

You can opt out of personalized ads in your device settings:
Settings → Privacy → Apple Advertising → Limit Ad Tracking
```

#### **8.2 ATT (App Tracking Transparency) - iOS 14.5+**

The Facebook SDK will automatically request tracking permission when needed. Make sure you have a clear privacy policy.

---

## 📊 Events Currently Tracked

| Event | When Triggered | Purpose |
|-------|---------------|---------|
| `fb_mobile_activate_app` | App opens | Track app installs & opens |
| `OnboardingCompleted` | User finishes onboarding | Measure onboarding funnel |
| `StartTrial` | User starts free trial | Track trial conversions |
| `fb_mobile_purchase` | User subscribes | Track revenue & ROAS |
| `SubscriptionCancelled` | User cancels subscription | Track churn |
| `CampaignCreated` | User creates campaign | Measure engagement |
| `CampaignSent` | Campaign is sent | Track feature usage |
| `CampaignCompleted` | Campaign completes | Measure success |
| `TemplateCreated` | User creates template | Track feature adoption |
| `ContactsAdded` | User adds contacts | Measure onboarding progress |
| `ContactGroupCreated` | User creates group | Track organization usage |
| `ViewAnalytics` | User views analytics | Measure engagement |
| `CampaignScheduled` | User schedules campaign | Track advanced feature usage |

---

## 🔧 Troubleshooting

### **Issue: "No module named 'FacebookCore'"**

**Solution:**
1. Make sure you added the Facebook SDK package (Step 1)
2. Clean build folder: **Product** → **Clean Build Folder** (⇧⌘K)
3. Restart Xcode

### **Issue: "Invalid FacebookAppID"**

**Solution:**
1. Double-check your App ID in `Info.plist`
2. Make sure it's just the numbers, no extra characters
3. Verify the App ID matches your Facebook App dashboard

### **Issue: "Events not showing in Facebook Events Manager"**

**Solution:**
1. Make sure you're looking at **Test Events** not **Live Events**
2. Wait 1-2 minutes for events to appear
3. Check Xcode console for Facebook logs
4. Verify your App ID is correct
5. Make sure you're logged into the correct Facebook account

### **Issue: "App crashes on launch after adding SDK"**

**Solution:**
1. Check that you imported `FacebookCore` in `BulkMessApp.swift`
2. Verify Info.plist is correctly formatted (valid XML)
3. Clean build folder and rebuild

---

## 🎯 Next Steps for Facebook Ads

Once your SDK is set up and tracking events:

1. ✅ Let the SDK collect data for 7-14 days
2. ✅ Aim for 50+ installs before running ads (for optimization)
3. ✅ Create Lookalike Audiences based on:
   - App Installers
   - Trial Starters
   - Purchasers (best performing)
4. ✅ Set up Custom Conversions for ad optimization:
   - Optimize for `StartTrial` (cheaper)
   - Or optimize for `fb_mobile_purchase` (more expensive but higher quality)

---

## 📝 Testing Checklist

Before launching ads, verify:

- [ ] Facebook SDK package installed successfully
- [ ] App builds without errors
- [ ] Facebook App created and configured
- [ ] App ID correctly added to Info.plist
- [ ] URL scheme correctly configured (`fbYOUR_APP_ID`)
- [ ] App opens without crashes
- [ ] Events visible in Facebook Test Events
- [ ] Purchase events tracking correctly (test with free trial)
- [ ] Campaign events tracking correctly
- [ ] Privacy policy updated
- [ ] App approved by Apple App Store (or in TestFlight)

---

## 📚 Additional Resources

- [Facebook SDK for iOS Documentation](https://developers.facebook.com/docs/ios)
- [Facebook App Events Guide](https://developers.facebook.com/docs/app-events)
- [Facebook Ads for Apps](https://www.facebook.com/business/help/1485256981818125)
- [iOS 14.5+ Privacy Changes](https://developers.facebook.com/docs/app-events/ios-14)

---

## 🆘 Need Help?

If you run into issues:

1. Check the Facebook SDK GitHub: https://github.com/facebook/facebook-ios-sdk/issues
2. Facebook Developer Community: https://developers.facebook.com/community
3. Review the implementation in:
   - `BulkMess/Services/FacebookAnalyticsService.swift`
   - `BulkMess/BulkMessApp.swift`
   - `BulkMess/Services/PurchaseService.swift`

---

**Good luck with your Facebook Ads campaign! 🚀**
