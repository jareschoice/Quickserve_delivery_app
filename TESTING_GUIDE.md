# QuickServe - Testing Guide

## 🧪 Testing Flow

### 1. Splash Screen Test
1. Open browser and navigate to `http://localhost:3000/index.html`
2. ✅ Should see orange gradient background
3. ✅ Should see large "Q" icon in gold
4. ✅ Should see "QuickServe" text in gold
5. ✅ Should see "FAST FOOD DELIVERY" tagline
6. ✅ Should see 3 animated loading dots
7. ✅ After 3 seconds, should automatically redirect to home.html

### 2. Home Page Test
1. Should land on `home.html` after splash screen
2. ✅ Top header should have orange gradient background
3. ✅ Should see QuickServe logo/text
4. ✅ Should see cart icon with badge
5. ✅ **Subscription Carousel:**
   - Should see 3 slides (Basic, Standard, Premium)
   - Basic: Green gradient, ₦25,000/month
   - Standard: Blue gradient, ₦50,000/month (with "Recommended" badge)
   - Premium: Purple gradient, ₦75,000/month
   - Should auto-slide every few seconds
   - Each has "Subscribe Now" button
6. ✅ Category grid should display 6 categories with icons
7. ✅ Explore section should show vendor avatars with orange borders
8. ✅ Featured section should show food cards
9. ✅ Bottom navigation should show 5 items (Home active in orange)
10. ✅ Profile avatar should show initials if logged in

### 3. Guest Mode Test
1. From home page, click profile icon (bottom right)
2. ✅ Should show guest view (not logged in)
3. ✅ Should see "Welcome!" message
4. ✅ Should see orange "Create Account" button
5. ✅ Should see gray "Sign In" button
6. ✅ Should see "Continue as Guest" option
7. Click "Continue as Guest"
8. ✅ Should redirect to home.html
9. ✅ Can browse vendors and add to cart without login

### 4. Sign Up Test
1. Click profile icon → "Create Account" button
2. ✅ Should redirect to `signup.html`
3. ✅ Should see orange gradient background
4. ✅ Form fields: Full Name, Email, Password, Phone, Seat Number
5. Fill in details:
   - Name: John Doe
   - Email: john@test.com
   - Password: test123
   - Phone: 08012345678
   - Seat: A-101 (optional)
6. Click "Create Account"
7. ✅ Should show loading state ("Creating Account...")
8. ✅ Should show success message: "Account created! Please check your email..."
9. ✅ Should show alert about verification link
10. ✅ Should redirect to `signin.html` after 2 seconds
11. **Check email inbox:**
    - ✅ Should receive verification email
    - ✅ Click verification link in email
    - ✅ Should see "Email verified successfully" message

### 5. Sign In Test (Without Verification)
1. Try to sign in without verifying email
2. Enter email and password
3. ✅ Should show error: "Please verify your email before signing in"

### 6. Sign In Test (After Verification)
1. After verifying email, go to `signin.html`
2. ✅ Should see orange gradient background
3. Enter credentials:
   - Email: john@test.com
   - Password: test123
4. Click "Sign In"
5. ✅ Should show loading state ("Signing In...")
6. ✅ Should show success message
7. ✅ Token should be stored in localStorage (check DevTools)
8. ✅ User data should be stored in localStorage
9. ✅ Should redirect to `home.html`
10. ✅ Profile avatar should now show initials "JD"

### 7. Auto-Login Test
1. After successful login, close browser completely
2. Reopen browser and go to `http://localhost:3000/home.html`
3. ✅ Should automatically show logged-in state
4. ✅ Profile avatar should show initials
5. Click profile icon
6. ✅ Should show logged-in view with user details
7. ✅ Should see "My Orders", "Edit Profile", "My Seat", "Support", "Sign Out"

### 8. Profile Page Test (Logged In)
1. From home page, click profile icon
2. ✅ Should show orange gradient header
3. ✅ Should show profile avatar with initials in white circle
4. ✅ Should show user name "John Doe"
5. ✅ Should show email "john@test.com"
6. ✅ Menu items should have orange icons (#FFE8D6 background)
7. ✅ "My Orders" - green icon
8. ✅ "Edit Profile" - blue icon
9. ✅ "My Seat" - purple icon, shows seat "A-101"
10. ✅ "Support" - orange icon
11. ✅ "Sign Out" button at bottom (red background)

### 9. Subscription Test (Not Logged In)
1. Log out or open in incognito
2. Go to home page
3. Click "Subscribe Now" on any subscription plan
4. ✅ Should show alert: "You need to sign in to subscribe..."
5. ✅ Should redirect to signup.html if user confirms

### 10. Subscription Test (Logged In)
1. Ensure you're logged in
2. Click "Subscribe Now" on Basic plan in carousel
3. ✅ Should redirect to `subscription.html?plan=basic`
4. ✅ Should auto-scroll to Basic plan card
5. ✅ Basic plan card should have orange border highlight
6. ✅ Should see detailed plan features
7. Click "Subscribe to Basic"
8. ✅ Should show confirmation dialog with plan details
9. Confirm subscription
10. ✅ Should call backend API `/api/subscription/initialize`
11. ✅ Should redirect to Paystack payment page (if backend is running)

### 11. Subscription Page Test
1. Navigate to `subscription.html` directly
2. ✅ Should see orange gradient header
3. ✅ Should see "Meal Subscriptions" title in gold
4. ✅ Should see 3 plan cards in responsive grid
5. **Basic Plan:**
   - ✅ Green badge and button
   - ✅ ₦25,000/month
   - ✅ 5 features listed
   - ✅ Breakfast & Lunch details
6. **Standard Plan:**
   - ✅ Blue badge and button
   - ✅ "⭐ Recommended" badge in top-right
   - ✅ ₦50,000/month
   - ✅ 6 features listed
   - ✅ All 3 meals + weekends
7. **Premium Plan:**
   - ✅ Purple badge and button
   - ✅ ₦75,000/month
   - ✅ 7 features listed
   - ✅ Gourmet + snacks details
8. ✅ Should see "Daily Meal Schedule" section
9. ✅ Should show 3 time slots (Breakfast, Lunch, Dinner)

### 12. Logout Test
1. Go to profile page
2. Click "Sign Out" button
3. ✅ Should show confirmation dialog
4. Confirm logout
5. ✅ Token should be removed from localStorage
6. ✅ User data should be removed from localStorage
7. ✅ Page should reload
8. ✅ Should show guest view

### 13. Navigation Test
1. Test bottom navigation bar on all pages
2. ✅ Home icon should navigate to home.html
3. ✅ Active page should be highlighted in orange
4. ✅ Orders icon should navigate to checkout.html
5. ✅ Profile icon should navigate to profile.html
6. ✅ Back buttons should work (window.history.back())

### 14. Cart Test (Guest User)
1. Without logging in, browse vendors
2. Add items to cart
3. ✅ Cart badge should update with item count
4. ✅ Should see orange badge with number
5. Go to checkout
6. ✅ Should be able to place order as guest
7. ✅ Should manually enter phone and seat number

### 15. Cart Test (Logged In User)
1. Log in with verified account
2. Add items to cart
3. Go to checkout
4. ✅ Phone and seat number should be pre-filled
5. ✅ Should show user name
6. ✅ Can proceed with order faster

## 🔧 Backend Testing

### Prerequisites:
1. Backend server should be running on `http://localhost:5000`
2. MongoDB should be connected
3. Email service should be configured (for verification emails)
4. Paystack keys should be set in environment variables

### API Endpoints to Test:

#### 1. Register Endpoint
```bash
POST http://localhost:5000/api/auth/register
Content-Type: application/json

{
  "name": "Test User",
  "email": "test@example.com",
  "password": "test123",
  "phone": "08012345678",
  "seatNumber": "A-101",
  "role": "customer"
}
```
**Expected Response:**
- Status: 201
- Message: "Registration successful. Please verify your email."
- Should send verification email

#### 2. Login Endpoint (Unverified)
```bash
POST http://localhost:5000/api/auth/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "test123"
}
```
**Expected Response:**
- Status: 403
- Message: "Please verify your email first"

#### 3. Login Endpoint (Verified)
After clicking verification link in email:
```bash
POST http://localhost:5000/api/auth/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "test123"
}
```
**Expected Response:**
- Status: 200
- Body: { "token": "jwt_token_here", "user": {...} }

#### 4. Me Endpoint (Auto-Login)
```bash
GET http://localhost:5000/api/auth/me
Authorization: Bearer {jwt_token}
```
**Expected Response:**
- Status: 200
- Body: { "user": { "name": "Test User", "email": "test@example.com", ... } }

#### 5. Vendors Endpoint
```bash
GET http://localhost:5000/api/event/vendors
```
**Expected Response:**
- Status: 200
- Body: Array of vendor objects

## 🐛 Common Issues & Fixes

### Issue 1: "API_BASE_URL is not defined"
**Solution:** Check that `js/config.js` exists and exports API_BASE_URL
```javascript
export const API_BASE_URL = 'http://localhost:5000';
```

### Issue 2: CORS Error
**Solution:** Backend should have CORS enabled:
```javascript
app.use(cors({
  origin: ['http://localhost:3000', 'http://127.0.0.1:3000'],
  credentials: true
}));
```

### Issue 3: Email Not Received
**Solution:** 
- Check backend email configuration
- Check spam folder
- Verify email service credentials in .env file

### Issue 4: Auto-Login Not Working
**Solution:**
- Check if token is stored in localStorage (DevTools → Application → Local Storage)
- Verify `/api/auth/me` endpoint is working
- Check if token is expired

### Issue 5: Subscription Payment Fails
**Solution:**
- Verify Paystack API keys in backend .env
- Check if subscription endpoint exists: `/api/subscription/initialize`
- Ensure user is logged in (token present)

## ✅ Checklist

### Visual/UI Tests:
- [ ] Splash screen displays correctly
- [ ] Orange/gold branding consistent across all pages
- [ ] Subscription carousel auto-slides
- [ ] Profile avatar shows initials when logged in
- [ ] Cart badge updates correctly
- [ ] Bottom navigation active states work
- [ ] All buttons have orange color
- [ ] Responsive design works on mobile

### Functionality Tests:
- [ ] Sign up creates account
- [ ] Email verification link works
- [ ] Sign in authenticates user
- [ ] Auto-login persists across sessions
- [ ] Logout clears session
- [ ] Guest mode allows browsing without login
- [ ] Subscription redirects to payment
- [ ] Cart stores items correctly

### Backend Integration Tests:
- [ ] `/api/auth/register` works
- [ ] `/api/auth/login` works
- [ ] `/api/auth/me` works
- [ ] `/api/event/vendors` works
- [ ] Email service sends verification emails
- [ ] JWT tokens are valid and expire correctly

## 🚀 Testing Commands

### Start Backend:
```bash
cd backend
npm install
npm start
# Should run on http://localhost:5000
```

### Start Frontend (if using a local server):
```bash
cd event-frontend
# Option 1: Use Live Server (VS Code extension)
# Right-click index.html → Open with Live Server

# Option 2: Use Python
python -m http.server 3000

# Option 3: Use Node http-server
npx http-server -p 3000
```

### Open in Browser:
```
http://localhost:3000/index.html
```

## 📝 Test Results Template

```
Date: ___________
Tester: ___________

[ ] Splash Screen Test - PASS/FAIL
[ ] Home Page Test - PASS/FAIL
[ ] Guest Mode Test - PASS/FAIL
[ ] Sign Up Test - PASS/FAIL
[ ] Email Verification Test - PASS/FAIL
[ ] Sign In Test - PASS/FAIL
[ ] Auto-Login Test - PASS/FAIL
[ ] Profile Page Test - PASS/FAIL
[ ] Subscription Test - PASS/FAIL
[ ] Logout Test - PASS/FAIL
[ ] Navigation Test - PASS/FAIL
[ ] Cart Test (Guest) - PASS/FAIL
[ ] Cart Test (Logged In) - PASS/FAIL

Issues Found:
1. ___________________________
2. ___________________________
3. ___________________________

Overall Status: PASS/FAIL
```

## 🎉 Success Criteria

The implementation is successful if:
1. ✅ Splash screen displays for 3 seconds then redirects
2. ✅ All pages use orange (#FF6B00) and gold (#FFD700) colors
3. ✅ Subscription carousel shows all 3 plans
4. ✅ Users can sign up and receive verification email
5. ✅ Users can sign in after verification
6. ✅ Auto-login works after first login
7. ✅ Profile page shows user details correctly
8. ✅ Guest users can browse without signing up
9. ✅ Subscription page displays and redirects to payment
10. ✅ All navigation works correctly

Happy Testing! 🚀
