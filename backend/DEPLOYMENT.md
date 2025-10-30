# QuickServe Backend Deployment

## Files to Upload to Your Hosting:

1. **Upload to public_html directory:**
   - All files from the `backend` folder
   - Make sure `.env` file is included
   - Set Node.js version to 18+ in hosting control panel

## Environment Setup:

Your hosting should support:
- Node.js 18+
- MongoDB Atlas connection
- HTTPS/SSL (already configured)

## Post-Upload Steps:

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Start the application:**
   ```bash
   npm start
   ```

3. **Test endpoints:**
   - https://getquickserves.com/ (should show API status)
   - https://getquickserves.com/auth/register/customer (for registration)

## Email Configuration:

The system will send verification emails to Gmail addresses using your configured SMTP.

## Testing:

Once deployed, test with these credentials:
- Email: your-gmail@gmail.com
- Password: any password (create account first)
- The app will send verification email to your Gmail

## Control Panel Access:
- URL: https://da22.host-ww.net:2222/
- Username: getquick  
- Password: b1Y[1oBN:wUz89