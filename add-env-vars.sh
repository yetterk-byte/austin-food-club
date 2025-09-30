#!/bin/bash

# Script to add missing environment variables to .env file
# Run this script to add the Twilio configuration

echo "Adding Twilio environment variables to .env file..."

# Check if .env file exists
if [ ! -f "server/.env" ]; then
    echo "❌ .env file not found in server directory"
    exit 1
fi

# Add Twilio variables if they don't exist
if ! grep -q "TWILIO_ACCOUNT_SID" server/.env; then
    echo "" >> server/.env
    echo "# Twilio Configuration (replace with your actual values)" >> server/.env
    echo "TWILIO_ACCOUNT_SID=\"your_twilio_account_sid_here\"" >> server/.env
    echo "TWILIO_AUTH_TOKEN=\"your_twilio_auth_token_here\"" >> server/.env
    echo "TWILIO_PHONE_NUMBER=\"your_twilio_phone_number_here\"" >> server/.env
    echo "✅ Added Twilio environment variables to .env file"
else
    echo "✅ Twilio environment variables already exist in .env file"
fi

echo ""
echo "📝 Next steps:"
echo "1. Get your Twilio credentials from https://console.twilio.com/"
echo "2. Replace the placeholder values in server/.env with your actual credentials:"
echo "   - TWILIO_ACCOUNT_SID: Your Account SID"
echo "   - TWILIO_AUTH_TOKEN: Your Auth Token" 
echo "   - TWILIO_PHONE_NUMBER: Your Twilio phone number (e.g., +15551234567)"
echo "3. Get a Yelp API key from https://www.yelp.com/developers/"
echo "4. Replace 'your_yelp_api_key_here' in server/.env with your actual Yelp API key"
echo ""
echo "🔗 Useful links:"
echo "- Twilio Console: https://console.twilio.com/"
echo "- Yelp for Developers: https://www.yelp.com/developers/"

