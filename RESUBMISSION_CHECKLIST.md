# BulkMess App Store Resubmission Checklist

## Quick Reference Guide for Fixing Rejection Issues

**Version:** 1.1
**Submission ID:** 2d5296b5-7964-48ce-afba-be1071f6aee6
**Review Date:** October 01, 2025
**Today's Date:** October 02, 2025

---

## 📋 Issues to Fix

### Issue 1: Guideline 3.1.2 - Missing Terms of Use (EULA) Link
**Problem:** App Store Connect metadata doesn't include a functional link to Terms of Use
**Solution:** Add Terms of Use link to App Description in App Store Connect

### Issue 2: Guideline 2.3.2 - Unclear Paid Content
**Problem:** App description doesn't clearly indicate that a subscription is required
**Solution:** Update app description to clearly label free vs. premium features

---

## ✅ Pre-Resubmission Checklist

### Phase 1: Documentation Review
- [x] Read the complete rejection email from Apple
- [x] Review `AppStoreDescription.md` - New compliant app description
- [x] Review `APP_STORE_CONNECT_UPDATE_GUIDE.md` - Step-by-step instructions
- [x] Review `PAYWALL_COMPLIANCE_VERIFICATION.md` - Binary compliance confirmation
- [x] Understand both rejection issues and their solutions

**Status:** ✅ All documentation created and ready

---

### Phase 2: Verify Technical Compliance

#### App Binary Compliance (No Changes Needed)
- [x] ✅ Subscription titles displayed in app ("Weekly Plan", "Yearly Plan")
- [x] ✅ Subscription lengths shown (1 week, 1 year)
- [x] ✅ Prices clearly displayed ($9.99/week, $36.99/year)
- [x] ✅ Functional link to Terms of Use in PaywallView (line 1022)
- [x] ✅ Functional link to Privacy Policy in PaywallView (line 1037)
- [x] ✅ Auto-renewal disclosure text present (lines 1049-1054)

**Binary Status:** ✅ FULLY COMPLIANT - No code changes required

#### External Links Verification
- [x] ✅ Terms of Use URL accessible: https://dan1sl6nd.github.io/BulkMess/terms.html
- [x] ✅ Privacy Policy URL accessible: https://dan1sl6nd.github.io/BulkMess/privacy.html
- [x] ✅ Support page accessible: https://dan1sl6nd.github.io/BulkMess/support.html
- [x] ✅ All pages have professional design and dark mode support
- [x] ✅ Links verified working on October 2, 2025

**Links Status:** ✅ ALL FUNCTIONAL

---

### Phase 3: App Store Connect Updates

Complete these steps in App Store Connect:

#### 3.1: Update App Description
- [ ] Log in to https://appstoreconnect.apple.com
- [ ] Navigate to BulkMess app
- [ ] Click on version 1.1 (rejected version)
- [ ] Go to "App Information" or find "Description" field
- [ ] Copy new description from `AppStoreDescription.md`
- [ ] Replace entire current description
- [ ] **Verify these are included in the new description:**
  - [ ] "PREMIUM FEATURES (Subscription Required)" section
  - [ ] "FREE FEATURES" section clearly separated
  - [ ] "$9.99/week" and "$36.99/year" pricing clearly stated
  - [ ] "Terms of Use: https://dan1sl6nd.github.io/BulkMess/terms.html"
  - [ ] "Privacy Policy: https://dan1sl6nd.github.io/BulkMess/privacy.html"
  - [ ] Auto-renewal terms and cancellation policy
- [ ] Click "Save"
- [ ] ✅ Confirm save was successful

**Fixes:** Guideline 3.1.2 (Terms link) + Guideline 2.3.2 (Paid content disclosure)

#### 3.2: Verify Privacy Policy URL
- [ ] Go to "App Privacy" or "Privacy Policy URL" section
- [ ] Verify URL is: `https://dan1sl6nd.github.io/BulkMess/privacy.html`
- [ ] If different, update it
- [ ] Click "Save"
- [ ] ✅ Confirm save was successful

#### 3.3: Verify Subscription Configuration
- [ ] Go to "In-App Purchases" or "Subscriptions"
- [ ] Verify **Weekly Plan** subscription:
  - [ ] Product ID: `com.bulkmess.weekly`
  - [ ] Duration: 1 Week
  - [ ] Price: $9.99
  - [ ] Free trial: 3 days enabled
  - [ ] Status: Ready to Submit or Approved
- [ ] Verify **Yearly Plan** subscription:
  - [ ] Product ID: `com.bulkmess.yearly`
  - [ ] Duration: 1 Year
  - [ ] Price: $36.99
  - [ ] Status: Ready to Submit or Approved
- [ ] Verify subscription group is properly configured
- [ ] ✅ All subscriptions configured correctly

#### 3.4: Update App Review Notes
- [ ] Go to version 1.1 page
- [ ] Scroll to "App Review Information"
- [ ] Copy review notes from `AppStoreDescription.md` (bottom section)
- [ ] Paste into "Notes" field
- [ ] **Verify notes explain:**
  - [ ] How Guideline 3.1.2 was fixed (Terms link added)
  - [ ] How Guideline 2.3.2 was fixed (Subscription disclosure added)
  - [ ] Where to find subscription info in the binary (PaywallView)
  - [ ] Reference to line numbers in PaywallView.swift
- [ ] Click "Save"
- [ ] ✅ Confirm save was successful

#### 3.5: Optional - Update Screenshots
- [ ] Review current app screenshots
- [ ] Verify at least one screenshot shows subscription/paywall screen
- [ ] If needed, add new screenshots showing pricing
- [ ] Recommended: Show paywall in first 2-3 screenshots
- [ ] Click "Save" if any changes made

---

### Phase 4: Final Verification Before Submission

#### Required Fields Check
Run through this final verification:

**App Description:**
- [ ] ✅ Contains "subscription required" language
- [ ] ✅ Separates free features from premium features
- [ ] ✅ Shows pricing ($9.99/week, $36.99/year)
- [ ] ✅ Includes Terms of Use link
- [ ] ✅ Includes Privacy Policy link
- [ ] ✅ Mentions 3-day free trial for weekly plan
- [ ] ✅ Explains auto-renewal and cancellation

**App Information:**
- [ ] ✅ Privacy Policy URL is set
- [ ] ✅ Contact information is correct
- [ ] ✅ Copyright is correct (© 2024 Daniil Mukashev)

**Subscriptions:**
- [ ] ✅ Both subscriptions (weekly & yearly) are configured
- [ ] ✅ Free trial is enabled on weekly subscription
- [ ] ✅ Pricing matches what's in the app description

**Review Information:**
- [ ] ✅ Review notes explain the fixes made
- [ ] ✅ Contact information for reviewers is correct
- [ ] ✅ Demo account info provided (if applicable)

**Screenshots:**
- [ ] ✅ Screenshots uploaded for all required device sizes
- [ ] ✅ At least one screenshot shows subscription screen (recommended)

---

### Phase 5: Submit for Review

#### Final Steps:
1. [ ] Double-check all items above are complete
2. [ ] Go to version 1.1 page in App Store Connect
3. [ ] Click "Submit for Review" button (top-right)
4. [ ] Answer pre-submission questions:
   - [ ] Export Compliance (usually "No" for apps without encryption)
   - [ ] Advertising Identifier (usually "No" if not using ads)
   - [ ] Content Rights (confirm you own all content)
5. [ ] Review summary of changes
6. [ ] Click final "Submit" button
7. [ ] ✅ Confirm submission successful

#### Confirmation:
- [ ] Received email confirmation from Apple
- [ ] Status changed to "Waiting for Review" in App Store Connect
- [ ] Noted submission time: __________________

---

## 🎯 What to Expect

### Timeline:
- **Review Duration:** Typically 24-48 hours
- **Could take longer:** Up to 5-7 days during busy periods
- **Status updates:** You'll receive email notifications

### Possible Outcomes:

#### ✅ **Approved** (Expected Result)
You'll receive an email: "App Status Change - Ready for Sale"

**What to do:**
- ✅ Celebrate! 🎉
- Check that the app is live on the App Store
- Share the App Store link
- Monitor initial reviews and ratings

#### ⚠️ **Additional Issues Found**
Apple finds other problems not caught before

**What to do:**
1. Read the new rejection email carefully
2. Identify what's still needed
3. Update this checklist with new items
4. Make the necessary changes
5. Resubmit

#### ❓ **Need Clarification**
Apple asks for more information

**What to do:**
1. Go to App Store Connect > App Review > Resolution Center
2. Reply to their questions
3. Provide requested information or screenshots
4. Wait for their response

---

## 📞 Getting Help

### If You Need to Contact Apple:

**Method 1: Reply in Resolution Center**
- Go to App Store Connect
- Navigate to your app > App Review
- Use the Resolution Center to ask questions
- Response time: Usually 1-2 business days

**Method 2: Request a Phone Call**
- In the rejection email, click "Request a phone call"
- Apple will call you within 3-5 business days
- Prepare your questions beforehand

**Method 3: Schedule an Appointment**
- Request an "App Review Appointment"
- Available on Tuesdays and Thursdays
- Discuss your specific issues with Apple engineers
- Subject to availability

### Apple Resources:
- **App Store Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/
- **Subscription Guidelines:** https://developer.apple.com/app-store/subscriptions/
- **Developer Support:** https://developer.apple.com/contact/
- **Phone Support:** 1-800-633-2152 (US)

### Your Support Resources:
- **Email:** support@bulkmessapp.com
- **Support Page:** https://dan1sl6nd.github.io/BulkMess/support.html

---

## 🔍 Common Mistakes to Avoid

### ❌ Don't:
- Submit without updating the App Description
- Forget to save changes in App Store Connect
- Submit without verifying all links work
- Leave out the Terms of Use link in the description
- Upload screenshots that don't show subscription pricing
- Forget to include "subscription required" language

### ✅ Do:
- Complete every item in this checklist
- Test all links before submitting
- Include specific line numbers in review notes
- Be clear about what was fixed
- Save changes frequently in App Store Connect
- Keep copies of your submission details

---

## 📊 Submission Summary

### Issue Resolution Summary:

| Guideline | Issue | Fix Applied | Status |
|-----------|-------|-------------|--------|
| 3.1.2 | Missing Terms of Use link | Added link to App Description | ✅ |
| 2.3.2 | Unclear paid content | Updated description with subscription disclosure | ✅ |

### Binary Compliance:
- **Required subscription info in app:** ✅ ALL PRESENT
- **Functional links to policies:** ✅ VERIFIED WORKING
- **Auto-renewal disclosure:** ✅ INCLUDED

### Metadata Updates:
- **App Description:** ✅ Updated with subscription disclosure
- **Terms of Use link:** ✅ Added to description
- **Privacy Policy URL:** ✅ Verified correct
- **Review notes:** ✅ Explains all fixes

---

## ✨ Final Checklist

Before clicking "Submit for Review", verify:

- [ ] ✅ I have updated the App Description
- [ ] ✅ The description includes "subscription required" disclosure
- [ ] ✅ Terms of Use link is in the description
- [ ] ✅ Privacy Policy URL is configured
- [ ] ✅ Both subscriptions are properly set up
- [ ] ✅ Review notes explain the fixes
- [ ] ✅ All external links are verified working
- [ ] ✅ I have read and understood both rejection issues
- [ ] ✅ I am confident the issues are resolved

**If all items above are checked, you're ready to submit!** 🚀

---

## 📝 Notes Section

Use this space to track your submission:

**Submission Date:** __________________

**Submission Time:** __________________

**Expected Review Completion:** __________________ (Add 48 hours)

**Issues Encountered:**
-
-
-

**Changes Made:**
-
-
-

**Apple's Response:**
-
-
-

---

**Good luck with your resubmission!** 🍀

---

**Document Version:** 1.0
**Created:** October 2, 2025
**For:** BulkMess v1.1 App Store Resubmission
**Previous Submission ID:** 2d5296b5-7964-48ce-afba-be1071f6aee6
