# 🚀 HOW TO START AND TEST YOUR BACKEND

## ⚠️ IMPORTANT: Keep Backend Running!

Your backend server **MUST stay running** in its own terminal while you test the signup page.

## 📋 STEP-BY-STEP INSTRUCTIONS:

### Step 1: Open a NEW Terminal for Backend
1. In VS Code, click **Terminal → New Terminal**
2. Or press `` Ctrl + Shift + ` `` to open a new terminal
3. This terminal will run your backend server

### Step 2: Start the Backend
In the NEW terminal, run:
```powershell
cd C:\Users\HP-PC\Desktop\quickserve\backend
node server.js
```

You should see:
```
🚀 QuickServe API running on http://0.0.0.0:5555
📱 Access from phone: http://192.168.61.104:5555
✅ MongoDB Atlas connected successfully!
```

**⚠️ LEAVE THIS TERMINAL OPEN! DO NOT CLOSE IT!**

### Step 3: Test the Signup (Choose ONE method)

#### **Method A: Open Signup Page in Browser (RECOMMENDED)**

1. **Install Live Server Extension** (if not already installed):
   - Press `Ctrl + Shift + X`
   - Search for "Live Server"
   - Install it

2. **Open signup page**:
   - Right-click on `event-frontend/signup.html`
   - Select "Open with Live Server"
   - Page will open at: `http://127.0.0.1:5500/event-frontend/signup.html`

3. **Fill the form and test**:
   - Name: Your Name
   - Email: yourtest@email.com
   - Password: test123456
   - Phone: 08012345678
   - Seat Number: A-101
   - Click "Create Account"

4. **Check backend terminal** - you should see:
   ```
   📥 Registration request: {...}
   ✅ User registered: yourtest@email.com | Role: customer
   ```

#### **Method B: Test with PowerShell (For Advanced Testing)**

1. **Open a SECOND terminal** (keep backend running in first!)
2. Run this command:
```powershell
$body = @{
    name = 'Test User'
    email = "test$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
    password = 'test123456'
    phone = '08012345678'
    seatNumber = 'A-101'
    role = 'customer'
} | ConvertTo-Json

Invoke-RestMethod -Uri 'http://127.0.0.1:5555/api/auth/register' `
    -Method Post `
    -Body $body `
    -ContentType 'application/json'
```

3. **You should get a response** like:
```json
{
  "ok": true,
  "message": "Account created successfully!",
  "user": {...},
  "token": "..."
}
```

#### **Method C: Use the Test HTML Page**

1. **Start a simple HTTP server**:
```powershell
# Open a NEW terminal (not the backend one!)
cd C:\Users\HP-PC\Desktop\quickserve
python -m http.server 8000
```

2. **Open in browser**:
   - Go to: `http://localhost:8000/test-signup.html`
   - Click "Test Health Check" - should show green ✅
   - Click "Test Signup" - should create a user

## ✅ HOW TO KNOW IT'S WORKING:

### In Browser:
- ✅ Success message appears
- ✅ Page redirects to signin.html
- ✅ Browser console (F12) shows: `Status: 200 OK`

### In Backend Terminal:
- ✅ See: `📥 Registration request: {...}`
- ✅ See: `✅ User registered: email@example.com`

## 🐛 COMMON MISTAKES:

### ❌ "Connection refused"
**Problem:** Backend is not running
**Solution:** Start backend in a separate terminal (see Step 1 & 2 above)

### ❌ "Failed to fetch" or CORS error
**Problem:** Accessing page as `file://` instead of `http://`
**Solution:** Use Live Server or a local web server

### ❌ Backend stops when I run a command
**Problem:** Running commands in the same terminal as backend
**Solution:** Open a NEW terminal for testing commands

## 📊 TERMINAL SETUP:

You should have **TWO terminals**:

**Terminal 1 (Backend Server):**
```
C:\Users\HP-PC\Desktop\quickserve\backend> node server.js
🚀 QuickServe API running on http://0.0.0.0:5555
✅ MongoDB Atlas connected successfully!
[KEEP THIS RUNNING - DO NOT CLOSE]
```

**Terminal 2 (For Testing):**
```
C:\Users\HP-PC\Desktop\quickserve> [your test commands here]
```

## 🎯 QUICK START SCRIPT:

I've created a helper script: `START-BACKEND.ps1`

To use it:
```powershell
cd C:\Users\HP-PC\Desktop\quickserve
.\START-BACKEND.ps1
```

This will start your backend server.

## 📝 SUMMARY:

1. ✅ Backend MUST run in its own terminal
2. ✅ Keep backend running while testing
3. ✅ Use Live Server to open signup.html
4. ✅ Or use a second terminal for curl/PowerShell tests
5. ✅ Watch backend terminal for registration logs

Your signup is ready to work - just keep the backend running! 🎉
