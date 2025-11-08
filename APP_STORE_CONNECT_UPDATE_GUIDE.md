# App Store Connect Update Guide

## Complete Step-by-Step Instructions to Fix App Rejection

This guide will help you update your App Store Connect metadata to address the rejection issues from Apple.

---

## 📋 Before You Begin

**You will need:**
- [ ] Access to App Store Connect (https://appstoreconnect.apple.com)
- [ ] Your Apple Developer account credentials
- [ ] The new app description from `AppStoreDescription.md`
- [ ] About 15-20 minutes

**Rejection Issues to Fix:**
1. **Guideline 3.1.2:** Missing Terms of Use link in metadata
2. **Guideline 2.3.2:** App description doesn't clearly indicate subscription required

---

## 🔧 Part 1: Update App Description (Fixes Both Issues)

### Step 1: Log in to App Store Connect
1. Go to https://appstoreconnect.apple.com
2. Sign in with your Apple Developer credentials
3. Click on **"My Apps"**

### Step 2: Select BulkMess
1. Find and click on **BulkMess** in your apps list
2. You should see your app's dashboard

### Step 3: Access the Version Under Review
1. Look for version **1.1** (or the version that was rejected)
2. The status should show "Rejected" or "Developer Rejected"
3. Click on the version number to open it

### Step 4: Update the App Description
1. In the left sidebar, click on **"App Information"** or find the **"Description"** field
2. You'll see a text area with your current app description
3. **IMPORTANT:** Copy the new description from `AppStoreDescription.md`
4. Replace the ENTIRE current description with the new one
5. **Make sure the new description includes:**
   - ✅ "PREMIUM FEATURES (Subscription Required)" section at the top
   - ✅ Clear FREE vs PREMIUM feature breakdown
   - ✅ Subscription pricing clearly stated
   - ✅ Terms of Use link: https://dan1sl6nd.github.io/BulkMess/terms.html
   - ✅ Privacy Policy link: https://dan1sl6nd.github.io/BulkMess/privacy.html

### Step 5: Verify Terms of Use Link
**CRITICAL:** Apple specifically wants to see the Terms of Use link. Make sure these lines are in your description:

```
**Terms of Use:** https://dan1sl6nd.github.io/BulkMess/terms.html
**Privacy Policy:** https://dan1sl6nd.github.io/BulkMess/privacy.html
```

### Step 6: Save Changes
1. Scroll to the bottom of the page
2. Click **"Save"** in the top-right corner
3. Wait for the confirmation message

---

## 🔧 Part 2: Update Privacy Policy URL (Verification)

### Step 1: Go to App Privacy Section
1. In the left sidebar, click on **"App Privacy"**
2. Or look for **"Privacy Policy URL"** field under App Information

### Step 2: Verify/Update Privacy URL
1. Check that the Privacy Policy URL is: `https://dan1sl6nd.github.io/BulkMess/privacy.html`
2. If it's different or empty, update it
3. Click **"Save"**

---

## 🔧 Part 3: Optional - Add Custom EULA (Alternative Method)

**Note:** You only need to do this if you prefer uploading a custom EULA instead of including the link in the description. Since we already added the link to the description (recommended by Apple), you can skip this section.

### If You Want to Add Custom EULA:
1. Go to **"App Information"** in the left sidebar
2. Find the **"License Agreement"** or **"End User License Agreement (EULA)"** section
3. Click **"Add Custom EULA"** or **"Edit"**
4. Copy the entire content from `terms.html` (the text content, not the HTML)
5. Paste it into the EULA field
6. Click **"Save"**

**Recommendation:** Stick with the Terms link in the description (Part 1) - it's simpler and meets Apple's requirements.

---

## 🔧 Part 4: Verify In-App Purchase Configuration

### Step 1: Check Subscription Products
1. In the left sidebar, click on **"In-App Purchases"** or **"Subscriptions"**
2. Verify both subscriptions are properly configured:

#### Weekly Subscription
- **Product ID:** com.bulkmess.weekly
- **Reference Name:** Weekly Plan
- **Subscription Duration:** 1 Week
- **Price:** $9.99 USD (Tier 50)
- **Free Trial:** 3 days (check "Introductory Offer" is enabled)
- **Status:** Ready to Submit or Approved

#### Yearly Subscription
- **Product ID:** com.bulkmess.yearly
- **Reference Name:** Yearly Plan
- **Subscription Duration:** 1 Year
- **Price:** $36.99 USD
- **Status:** Ready to Submit or Approved

### Step 2: Check Subscription Group Information
1. Find your subscription group (should contain both subscriptions)
2. Verify the **"Subscription Group Display Name"** is set (e.g., "BulkMess Premium")
3. Make sure **"App Store Localization"** is filled out

### Step 3: Verify Required Subscription Metadata
For EACH subscription, verify these fields are filled:
- [ ] **Subscription Name** - User-facing name
- [ ] **Description** - What the subscription includes
- [ ] **Review Information** - Optional, but helpful for reviewers

---

## 🔧 Part 5: Update Review Notes

### Step 1: Go to Version Information
1. Click on the version that was rejected (1.1)
2. Scroll down to **"App Review Information"**

### Step 2: Add Notes for Reviewer
Copy and paste this into the **"Notes"** field:

```
Dear App Review Team,

Thank you for your feedback on submission 2d5296b5-7964-48ce-afba-be1071f6aee6.

We have addressed both issues:

**Guideline 3.1.2 - Subscriptions:**
- Terms of Use link is now included in the App Description
- URL: https://dan1sl6nd.github.io/BulkMess/terms.html
- The app binary also includes functional links to Terms of Use and Privacy Policy in the subscription screen (FloatingPurchaseButton in PaywallView.swift)

**Guideline 2.3.2 - Accurate Metadata:**
- App Description now clearly states "Premium subscription required" at the top
- Free vs. Premium features are clearly separated and labeled
- Subscription pricing and terms are prominently displayed
- Users understand what requires purchase before downloading

All required subscription information is displayed in the app binary:
✓ Subscription titles (Weekly Plan, Yearly Plan)
✓ Subscription lengths (1 week, 1 year)
✓ Subscription prices ($9.99/week, $36.99/year)
✓ Functional links to Privacy Policy and Terms of Use

The PaywallView includes:
- Links to "Terms of Use", "Privacy Policy", "Restore", and "Manage" at lines 1020-1048
- Auto-renewal disclosure text at lines 1049-1054
- All subscription details and pricing information

Thank you for your review.

Best regards,
Daniil Mukashev
```

### Step 3: Save
Click **"Save"** at the top-right

---

## 🔧 Part 6: Verify Screenshots (Optional but Recommended)

### Check Your App Screenshots
1. Go to **"App Store"** tab in the left sidebar
2. Look at your app screenshots for all device sizes
3. **Recommended:** Ensure at least one screenshot shows:
   - The subscription/paywall screen
   - Pricing clearly visible
   - "Premium" or subscription indicators

### If Screenshots Need Updating:
1. Take new screenshots showing the paywall with pricing
2. Upload them in the appropriate device size slots
3. Reorder them if needed (subscription screen should be visible in first 2-3 screenshots)

---

## ✅ Part 7: Resubmit for Review

### Step 1: Final Verification Checklist
Before submitting, verify:
- [ ] App Description includes "Subscription Required" language
- [ ] Terms of Use link (https://dan1sl6nd.github.io/BulkMess/terms.html) is in the description
- [ ] Privacy Policy URL is set to https://dan1sl6nd.github.io/BulkMess/privacy.html
- [ ] Both subscriptions (weekly and yearly) are properly configured
- [ ] Review notes explain the fixes made
- [ ] All required fields are filled (you'll see errors if not)

### Step 2: Submit for Review
1. Scroll to the top of the version page
2. Click the **"Submit for Review"** button (top-right)
3. You may be asked to confirm some questions:
   - Export Compliance - Answer based on your app's encryption usage
   - Advertising Identifier - Select "No" if you're not using ad tracking
   - Content Rights - Confirm you have rights to all content
4. Click **"Submit"** to confirm

### Step 3: Confirmation
1. You should see a confirmation message
2. The status will change to **"Waiting for Review"**
3. You'll receive an email confirmation from Apple

---

## 📧 What Happens Next?

### Expected Timeline:
- **Review Time:** Typically 24-48 hours (can be longer)
- **Email Notifications:** Apple will email you at each status change
- **Check Status:** Monitor in App Store Connect under "App Store" > "iOS App" > Version 1.1

### Possible Outcomes:

#### ✅ If Approved:
1. You'll receive an email: "App Status Change - Ready for Sale"
2. App will automatically go live (if you selected "Automatic Release")
3. Or you can manually release it if you selected "Manual Release"

#### ⚠️ If Still Issues Remain:
1. Apple will send another rejection email
2. They'll specify what's still missing
3. Come back to this guide and verify each step
4. Contact support@bulkmessapp.com if you need help

#### 📞 If You Need to Talk to Apple:
In the rejection email, Apple offers:
- **Reply in App Store Connect:** Ask clarifying questions
- **Request Phone Call:** Apple can call you within 3-5 business days
- **App Review Appointment:** Meet with Apple on Tuesdays/Thursdays

---

## 🆘 Troubleshooting

### Issue: Can't find "App Description" field
**Solution:**
- Try clicking "App Information" in the left sidebar
- Or go to the version tab and look for "Description" under "What's New"
- Description might be under "App Store" > "iOS App" section

### Issue: Terms of Use link not clickable in description
**Solution:**
- App Store Connect automatically converts URLs to clickable links
- Make sure the URL is properly formatted: `https://dan1sl6nd.github.io/BulkMess/terms.html`
- Include the full `https://` prefix

### Issue: Can't save changes
**Solution:**
- Check for error messages at the top of the page
- Ensure all required fields are filled
- Make sure you're not exceeding character limits (4,000 for description)
- Try refreshing the page and signing in again

### Issue: Subscription products not showing
**Solution:**
- Go to "Features" > "In-App Purchases" in the left sidebar
- Or try "Subscriptions" if that's a separate menu item
- Make sure subscriptions were created and approved

---

## 📞 Need Help?

If you encounter any issues during this process:

1. **Check Apple's Documentation:**
   - https://developer.apple.com/app-store/review/
   - https://developer.apple.com/app-store/subscriptions/

2. **Contact Apple Developer Support:**
   - https://developer.apple.com/contact/
   - Phone: 1-800-633-2152 (US)

3. **App Store Connect Help:**
   - Click the "?" icon in the top-right of App Store Connect
   - Access guided tutorials and documentation

4. **Reply to Apple Directly:**
   - In App Store Connect, go to your app's version
   - Click "App Review" in the left sidebar
   - Use "Resolution Center" to reply to reviewers

---

## ✨ Success Checklist

After completing all steps, you should have:
- ✅ Updated app description with subscription disclosure
- ✅ Terms of Use link visible in app description
- ✅ Privacy Policy URL configured
- ✅ Subscription products properly configured
- ✅ Review notes explaining your fixes
- ✅ App resubmitted for review

**Expected Result:** App approval within 24-48 hours! 🎉

---

**Document Version:** 1.0
**Last Updated:** October 2, 2025
**For:** BulkMess v1.1 Resubmission
