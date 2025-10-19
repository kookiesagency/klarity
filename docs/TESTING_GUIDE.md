# Klarity Finance Tracking - Testing Guide

## Overview
This guide provides comprehensive testing scenarios for the Klarity Finance Tracking app before app store submission.

---

## 1. Authentication & Security Testing

### 1.1 Sign Up Flow
- [ ] Create new account with email and password
- [ ] Verify email validation (valid format)
- [ ] Verify password strength requirements
- [ ] Verify full name is required
- [ ] Test with invalid credentials
- [ ] Verify auto-creation of "Personal" profile

### 1.2 Login Flow
- [ ] Login with correct credentials
- [ ] Login with incorrect password
- [ ] Login with non-existent email
- [ ] Verify "Forgot Password" flow

### 1.3 PIN Setup & Unlock
- [ ] Set up 4-digit PIN after first login
- [ ] Verify PIN confirmation matches
- [ ] Test PIN unlock on app launch
- [ ] Test incorrect PIN entry (should retry)
- [ ] Verify auto-lock after backgrounding (configurable duration)

### 1.4 Biometric Authentication
- [ ] Enable biometric authentication (if device supports)
- [ ] Unlock with fingerprint/Face ID
- [ ] Test biometric failure fallback to PIN
- [ ] Disable biometric authentication
- [ ] Verify biometric settings persistence

### 1.5 Session Management
- [ ] Verify session persists after app restart
- [ ] Test auto-lock functionality (immediate, 30s, 1m, 5m, 10m, 30m)
- [ ] Verify back button doesn't trigger PIN screen
- [ ] Test navigation doesn't trigger auto-lock
- [ ] Verify notification shade doesn't trigger auto-lock

---

## 2. Profile Management Testing

### 2.1 Profile Creation & Switching
- [ ] Create additional profiles (e.g., "Company", "Family")
- [ ] Switch between profiles
- [ ] Verify data separation between profiles
- [ ] Edit profile name
- [ ] Delete profile (should show confirmation)

### 2.2 Profile Data Isolation
- [ ] Add accounts in Profile A
- [ ] Switch to Profile B
- [ ] Verify Profile A accounts don't show in Profile B
- [ ] Add transactions in Profile B
- [ ] Verify Profile A transactions don't show in Profile B

---

## 3. Account Management Testing

### 3.1 Create Accounts
- [ ] Create Savings account with opening balance
- [ ] Create Current account with opening balance
- [ ] Create Credit Card with negative opening balance
- [ ] Verify opening balance is not editable after creation
- [ ] Verify account name can be edited

### 3.2 Account Operations
- [ ] View account balance
- [ ] Edit account name
- [ ] Delete account (swipe to delete)
- [ ] Verify deletion confirmation
- [ ] Create 10+ accounts (test scrollable bottom sheet)

---

## 4. Category Management Testing

### 4.1 Default Categories
- [ ] Verify 10 default expense categories auto-created
- [ ] Verify 5 default income categories auto-created
- [ ] Edit default category (name, icon, color)
- [ ] Delete default category
- [ ] Verify category deletion confirmation

### 4.2 Custom Categories
- [ ] Create custom expense category
- [ ] Create custom income category
- [ ] Select different icons (emojis)
- [ ] Select different colors
- [ ] View categories in tabs (Expense/Income)

---

## 5. Transaction Testing

### 5.1 Create Transactions
- [ ] Create expense transaction
- [ ] Create income transaction
- [ ] Select category from bottom sheet
- [ ] Select account from bottom sheet
- [ ] Pick date (past, today, future)
- [ ] Add description
- [ ] Verify balance updates immediately

### 5.2 Transaction List
- [ ] View transactions grouped by date
- [ ] Filter by date range (Today, Week, Month, Year, Custom)
- [ ] Filter by category
- [ ] Filter by account
- [ ] Filter by type (Income/Expense)
- [ ] Verify sorting (newest first)

### 5.3 Edit & Delete Transactions
- [ ] Edit transaction details
- [ ] Delete transaction (swipe to delete)
- [ ] Verify balance recalculation after edit
- [ ] Verify balance recalculation after delete
- [ ] Test locked transaction (cannot edit/delete)
- [ ] Unlock transaction on-demand

### 5.4 Bulk Operations
- [ ] Long press to enter selection mode
- [ ] Select multiple transactions
- [ ] Select all transactions
- [ ] Bulk delete with confirmation
- [ ] Bulk change category
- [ ] Bulk change account

### 5.5 Transaction Locking
- [ ] Verify transactions older than 2 months auto-lock
- [ ] View lock icon on locked transactions
- [ ] Unlock transaction when editing
- [ ] Unlock transaction when deleting
- [ ] Verify lock icon in rounded badge (top right corner)

---

## 6. Transfer Testing

### 6.1 Create Transfers
- [ ] Bank to Bank transfer
- [ ] Bank to Credit Card transfer
- [ ] Credit Card to Bank transfer
- [ ] Verify "Swap" button works
- [ ] Verify balance validation (sufficient funds)
- [ ] Add transfer description
- [ ] Select transfer date

### 6.2 Transfer Verification
- [ ] Verify both transactions created (OUT from source, IN to destination)
- [ ] Verify balances update correctly
- [ ] Edit transfer
- [ ] Delete transfer
- [ ] Verify both linked transactions update/delete

---

## 7. Recurring Transactions Testing

### 7.1 Create Recurring Transactions
- [ ] Create recurring expense (daily, weekly, monthly, yearly)
- [ ] Create recurring income
- [ ] Set start date and end date
- [ ] View next due date
- [ ] Enable/disable auto-creation

### 7.2 Recurring Transaction List
- [ ] View active recurring transactions
- [ ] View inactive recurring transactions
- [ ] Filter by account
- [ ] Edit recurring transaction
- [ ] Pause recurring transaction
- [ ] Delete recurring transaction

### 7.3 Auto-Creation
- [ ] Wait for due date to pass (or manually change system date)
- [ ] Verify transaction auto-created
- [ ] Verify next due date updated
- [ ] Check transaction linked to recurring template

---

## 8. Scheduled Payments Testing

### 8.1 Create Scheduled Payments
- [ ] Create scheduled expense payment
- [ ] Create scheduled income payment
- [ ] Set payee name
- [ ] Set due date and reminder date
- [ ] Enable partial payment option
- [ ] Enable auto-creation option

### 8.2 Scheduled Payments List
- [ ] View Pending tab
- [ ] View Partial tab
- [ ] View Completed tab
- [ ] Verify IN/OUT badges
- [ ] Verify status badges (color-coded)
- [ ] Verify overdue detection
- [ ] Verify progress bars for partial payments
- [ ] Check compact card design (date left, status right)

### 8.3 Partial Payments
- [ ] Record partial payment
- [ ] View payment history
- [ ] Verify progress bar updates
- [ ] Verify status changes (pending → partial → completed)
- [ ] Mark as paid (full amount)
- [ ] Verify auto-completion on full payment

### 8.4 Scheduled Payment Details
- [ ] View payment details
- [ ] View payment history
- [ ] Edit scheduled payment
- [ ] Delete scheduled payment
- [ ] Verify navigation back refreshes list

---

## 9. EMI Tracking Testing

### 9.1 Create EMI
- [ ] Create new EMI with total amount
- [ ] Set monthly payment amount
- [ ] Set payment day of month (1-31)
- [ ] Set start date
- [ ] Link to account
- [ ] Link to category
- [ ] Add historical installments (already paid)

### 9.2 EMI List
- [ ] View Active EMIs
- [ ] View Inactive EMIs
- [ ] Filter by account (verify totals recalculated)
- [ ] View progress indicators
- [ ] Check overdue badges
- [ ] Swipe to delete EMI

### 9.3 EMI Details & Payments
- [ ] View EMI detail screen
- [ ] View payment history
- [ ] View next payment date
- [ ] Delete individual payment
- [ ] Verify balance recalculation
- [ ] Check overdue indicators
- [ ] Verify completed status display

### 9.4 Auto-Payment Processing
- [ ] Go to Settings → EMI Auto Payment
- [ ] Click "Process Now" button
- [ ] Verify due payments processed
- [ ] Check expense transactions created
- [ ] Verify EMI installments marked as paid
- [ ] Verify remaining count updated

---

## 10. Budget Management Testing

### 10.1 Set Budgets
- [ ] Set monthly budget for expense category
- [ ] Set daily budget for expense category
- [ ] Set weekly budget for expense category
- [ ] Set yearly budget for expense category
- [ ] Set alert threshold (60%, 70%, 80%, 90%)
- [ ] Enable/disable budget

### 10.2 Budget Monitoring
- [ ] Add expense transaction in budgeted category
- [ ] Verify budget status updates
- [ ] Check progress bar color (green → orange → red)
- [ ] View budget alerts on home screen (top 3)
- [ ] Verify alert levels (safe, warning, critical, over-budget)

### 10.3 Budget Warning in Transaction Form
- [ ] Create transaction that exceeds budget
- [ ] Verify warning card appears
- [ ] Check warning shows budget amount, spent, and exceed amount
- [ ] Verify color coding (orange/red)
- [ ] Proceed with transaction (soft limit)

### 10.4 Budget vs Actual Chart
- [ ] Go to Analytics → Budgets tab
- [ ] View Budget vs Actual comparison chart
- [ ] Verify top 5 categories displayed
- [ ] Check bar colors (blue for budget, color-coded for actual)
- [ ] Tap bars to see tooltips
- [ ] Verify chart respects date range filter

### 10.5 Budget Period Selector
- [ ] Edit category with budget
- [ ] Open budget period selector
- [ ] Select Daily period
- [ ] Select Weekly period
- [ ] Select Monthly period
- [ ] Select Yearly period
- [ ] Verify period displays in UI
- [ ] Save and verify period persists

---

## 11. Analytics Testing

### 11.1 Overview Tab
- [ ] View balance trend chart (last 30 days)
- [ ] Check income/expense summary cards
- [ ] Verify monthly spending overview
- [ ] View category breakdown pie chart
- [ ] Check top 5 categories bar chart
- [ ] View spending trends line chart

### 11.2 Categories Tab
- [ ] View all categories with spending
- [ ] Check progress bars for each category
- [ ] Verify transaction counts
- [ ] Tap category to see details

### 11.3 Budgets Tab
- [ ] View Budget vs Actual chart
- [ ] View budget overview cards
- [ ] Check progress bars for budgets
- [ ] Tap budget card to navigate to category detail

### 11.4 Date Range Filtering
- [ ] Select "Today" range
- [ ] Select "This Week" range
- [ ] Select "This Month" range
- [ ] Select "This Year" range
- [ ] Select "Custom" range and pick dates
- [ ] Verify all charts update based on selection

---

## 12. Home Screen Testing

### 12.1 Balance Card
- [ ] View total balance (all accounts)
- [ ] Switch to specific account
- [ ] Verify balance updates based on account filter
- [ ] Verify balance persists after app restart

### 12.2 Quick Actions
- [ ] Add Income quick action
- [ ] Add Expense quick action
- [ ] Create Transfer quick action

### 12.3 Budget Alerts Widget
- [ ] View top 3 categories approaching/over budget
- [ ] Check color-coded alert cards (orange/red)
- [ ] Verify percentage or over-budget amount shown
- [ ] Tap "See All" → navigates to Categories screen
- [ ] Widget only shows when budgets have warnings

### 12.4 Recent Transactions
- [ ] View last 5 transactions
- [ ] Check date grouping
- [ ] Tap "See All" → navigates to Transactions screen

### 12.5 Upcoming Recurring
- [ ] View next 3 upcoming recurring transactions
- [ ] Verify sorting by due date (soonest first)
- [ ] Check correct window (next 30 days)
- [ ] Tap "See All" → navigates to Recurring Transactions screen

### 12.6 EMI Tracker
- [ ] View active EMIs count
- [ ] View total monthly payment amount
- [ ] View total remaining amount
- [ ] Verify account filter affects EMI totals
- [ ] Tap "Manage EMIs" → navigates to EMIs screen

---

## 13. Settings Testing

### 13.1 Profile Settings
- [ ] Update full name
- [ ] Update phone number
- [ ] Set low balance threshold
- [ ] Verify low balance alerts trigger
- [ ] Update profile picture (if implemented)

### 13.2 Security Settings
- [ ] Change PIN
- [ ] Enable/disable biometric
- [ ] Set auto-lock duration
- [ ] Test auto-lock after selected duration

### 13.3 Theme Settings
- [ ] Switch to Light mode
- [ ] Switch to Dark mode
- [ ] Set System default theme
- [ ] Verify theme persists after app restart

### 13.4 Navigation
- [ ] Account Management
- [ ] Category Management
- [ ] Scheduled Payments
- [ ] EMI Auto Payment Settings

---

## 14. Edge Cases & Error Handling

### 14.1 Network Errors
- [ ] Turn off internet
- [ ] Try to login (should show error)
- [ ] Try to add transaction (should use cache/offline mode)
- [ ] Turn on internet
- [ ] Verify sync when back online

### 14.2 Validation Errors
- [ ] Create transaction with 0 amount
- [ ] Create transaction without category
- [ ] Create transaction without account
- [ ] Create transfer with insufficient funds
- [ ] Set budget with negative amount

### 14.3 Data Limits
- [ ] Create 100+ transactions
- [ ] Create 50+ categories
- [ ] Create 20+ accounts
- [ ] Create 30+ recurring transactions
- [ ] Verify app performance with large datasets

### 14.4 Concurrent Operations
- [ ] Create transaction while another is saving
- [ ] Delete account with transactions (should prevent)
- [ ] Delete category with transactions (should prevent)
- [ ] Delete profile with data (should show warning)

---

## 15. UI/UX Testing

### 15.1 Responsive Design
- [ ] Test on small phone (iPhone SE, Android small)
- [ ] Test on large phone (iPhone Pro Max, Android large)
- [ ] Test on tablet (iPad)
- [ ] Verify bottom sheets scroll when content overflows
- [ ] Check text doesn't overflow

### 15.2 Animations & Transitions
- [ ] Smooth tab transitions
- [ ] Smooth bottom sheet animations
- [ ] Loading states display correctly
- [ ] Pull to refresh works
- [ ] Swipe actions are responsive

### 15.3 Accessibility
- [ ] Test with large text sizes
- [ ] Test color contrast (dark mode)
- [ ] Test screen reader compatibility
- [ ] Verify tap targets are adequate size (minimum 44x44)

### 15.4 Performance
- [ ] App launches in < 2 seconds
- [ ] Transactions load quickly (< 1 second)
- [ ] Analytics charts render smoothly
- [ ] No lag when scrolling lists
- [ ] No memory leaks (test for 30+ minutes)

---

## 16. Platform-Specific Testing

### 16.1 iOS Specific
- [ ] Test on iOS 14, 15, 16, 17
- [ ] Verify app icon displays correctly
- [ ] Test Face ID/Touch ID
- [ ] Verify app doesn't crash on background
- [ ] Test notifications (if implemented)

### 16.2 Android Specific
- [ ] Test on Android 10, 11, 12, 13, 14
- [ ] Verify fingerprint unlock
- [ ] Test back button behavior
- [ ] Verify app lifecycle (minimize, restore)
- [ ] Test on different screen sizes/resolutions

---

## 17. Final Checklist

### Pre-Release
- [ ] All critical bugs fixed
- [ ] All features working as expected
- [ ] No crashes in normal usage
- [ ] Performance is acceptable
- [ ] UI/UX is polished
- [ ] Data persists correctly
- [ ] Offline mode works (if applicable)

### Documentation
- [ ] README.md updated
- [ ] CHANGELOG.md created
- [ ] Privacy Policy created
- [ ] Terms of Service created (if required)

### App Store Prep
- [ ] App icon (1024x1024 for iOS, various sizes for Android)
- [ ] Screenshots (all required sizes)
- [ ] App description written
- [ ] Keywords selected
- [ ] Age rating determined
- [ ] Privacy information filled
- [ ] Build uploaded to stores

---

## Testing Tips

1. **Use Real Data**: Test with realistic amounts and dates
2. **Test Edge Cases**: Try negative amounts, large amounts, extreme dates
3. **Test on Multiple Devices**: Don't just test on one phone
4. **Test Both Platforms**: iOS and Android may behave differently
5. **Test with Fresh Install**: Clear app data and test from scratch
6. **Test Upgrades**: If you have existing users, test data migration
7. **Get Beta Testers**: Ask friends/family to test and provide feedback

---

## Bug Reporting Template

When you find a bug, document it with:

```
**Bug Title**: Clear, descriptive title

**Steps to Reproduce**:
1. Step one
2. Step two
3. Step three

**Expected Behavior**: What should happen

**Actual Behavior**: What actually happens

**Device**: iPhone 14 Pro / Samsung Galaxy S23
**OS Version**: iOS 17.1 / Android 14
**App Version**: 1.0.0

**Screenshots/Videos**: Attach if applicable

**Additional Context**: Any other relevant information
```

---

## Success Criteria

The app is ready for release when:
- ✅ All critical bugs are fixed
- ✅ All features in roadmap work correctly
- ✅ No crashes in normal usage
- ✅ Performance is smooth (60fps)
- ✅ UI/UX is polished and consistent
- ✅ Data integrity is maintained
- ✅ Security is properly implemented
- ✅ Tested on multiple devices
- ✅ Beta testing feedback addressed
- ✅ App store materials prepared

---

Good luck with testing! 🎉
