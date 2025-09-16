# Google OAuth Setup Guide

This guide will help you set up Google OAuth for your Austin Food Club application.

## 🎯 **Quick Setup (5 minutes)**

### **Step 1: Google Cloud Console Setup**

1. **Go to Google Cloud Console**
   - Visit [console.cloud.google.com](https://console.cloud.google.com)
   - Sign in with your Google account

2. **Create or Select Project**
   - Click the project dropdown at the top
   - Click "New Project" or select existing project
   - Name: "Austin Food Club" (or your preferred name)

3. **Enable Google+ API**
   - Go to **APIs & Services** → **Library**
   - Search for "Google+ API"
   - Click on it and click "Enable"

### **Step 2: Create OAuth Credentials**

1. **Go to Credentials**
   - Navigate to **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **OAuth 2.0 Client ID**

2. **Configure OAuth Consent Screen**
   - If prompted, click "Configure Consent Screen"
   - Choose "External" user type
   - Fill in required fields:
     - **App name**: Austin Food Club
     - **User support email**: Your email
     - **Developer contact**: Your email
   - Click "Save and Continue" through all steps

3. **Create OAuth Client**
   - Application type: **Web application**
   - Name: "Austin Food Club Web"
   - Authorized redirect URIs:
     ```
     https://your-project-id.supabase.co/auth/v1/callback
     http://localhost:3000/auth/callback
     ```
   - Click "Create"

4. **Copy Credentials**
   - Copy the **Client ID** and **Client Secret**
   - Keep these safe - you'll need them for Supabase

### **Step 3: Configure Supabase**

1. **Go to Supabase Dashboard**
   - Visit [supabase.com](https://supabase.com)
   - Open your Austin Food Club project
   - Go to **Authentication** → **Providers**

2. **Enable Google Provider**
   - Find "Google" in the providers list
   - Toggle it **ON**
   - Enter your credentials:
     - **Client ID**: Paste from Google Cloud Console
     - **Client Secret**: Paste from Google Cloud Console
   - Click "Save"

### **Step 4: Test the Integration**

1. **Test Page**
   - Go to `http://localhost:3000/oauth-test`
   - Click "Continue with Google"
   - Complete the OAuth flow

2. **Test in Main App**
   - Go to `http://localhost:3000/auth`
   - Click "Continue with Google"
   - Verify it works

## 🔧 **Detailed Configuration**

### **OAuth Consent Screen Settings**

For production, you'll want to configure:

- **App logo**: Upload your app logo
- **App domain**: Your production domain
- **Authorized domains**: Add your domains
- **Scopes**: 
  - `email`
  - `profile`
  - `openid`

### **Redirect URIs**

Make sure to add these redirect URIs in Google Cloud Console:

**Development:**
```
http://localhost:3000/auth/callback
```

**Production:**
```
https://yourdomain.com/auth/callback
https://your-project-id.supabase.co/auth/v1/callback
```

### **Supabase Configuration**

In your Supabase project settings:

1. **Site URL**: `http://localhost:3000` (development)
2. **Redirect URLs**: 
   - `http://localhost:3000/auth/callback`
   - `https://yourdomain.com/auth/callback` (production)

## 🧪 **Testing Checklist**

### **Basic OAuth Flow**
- [ ] Google OAuth button appears
- [ ] Clicking button redirects to Google
- [ ] Google sign-in page loads
- [ ] After sign-in, redirects back to app
- [ ] User is authenticated in app
- [ ] User data is available (email, name, etc.)

### **Error Handling**
- [ ] Invalid credentials show error
- [ ] Network errors are handled gracefully
- [ ] User can retry after errors
- [ ] Clear error messages displayed

### **User Experience**
- [ ] Loading states during OAuth
- [ ] Smooth redirects
- [ ] User data displayed correctly
- [ ] Sign out works properly

## 🚀 **Production Deployment**

### **Update Redirect URIs**
1. Add your production domain to Google Cloud Console
2. Update Supabase site URL and redirect URLs
3. Test the production OAuth flow

### **Security Considerations**
- Keep Client Secret secure
- Use environment variables for sensitive data
- Enable HTTPS in production
- Regularly rotate credentials

## 🆘 **Troubleshooting**

### **Common Issues**

#### "redirect_uri_mismatch"
- **Cause**: Redirect URI not configured in Google Cloud Console
- **Fix**: Add the exact redirect URI to Google Cloud Console

#### "invalid_client"
- **Cause**: Wrong Client ID or Client Secret
- **Fix**: Double-check credentials in Supabase

#### "access_denied"
- **Cause**: User denied permission or app not verified
- **Fix**: Check OAuth consent screen configuration

#### "OAuth redirect not working"
- **Cause**: Wrong redirect URL in Supabase
- **Fix**: Ensure redirect URL matches exactly

### **Debug Steps**

1. **Check Browser Console**
   - Look for JavaScript errors
   - Check network requests

2. **Check Supabase Logs**
   - Go to Supabase Dashboard → Logs
   - Look for authentication errors

3. **Test with Different Browsers**
   - Try Chrome, Firefox, Safari
   - Check if issue is browser-specific

4. **Verify URLs**
   - Ensure all URLs match exactly
   - Check for typos in redirect URIs

## 📚 **Additional Resources**

- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [OAuth 2.0 Security Best Practices](https://tools.ietf.org/html/rfc6749)

## ✅ **Success Indicators**

When everything is working correctly, you should see:

1. **OAuth Button**: Google button appears and is clickable
2. **Redirect**: Clicking redirects to Google sign-in
3. **Authentication**: After sign-in, user is logged into your app
4. **User Data**: User's email, name, and other data are available
5. **Session**: User stays logged in across page refreshes

---

**Need help?** Check the troubleshooting section or create an issue in your repository!
