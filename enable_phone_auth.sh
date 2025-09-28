#!/bin/bash

# Phone Authentication Setup Script
echo "🔧 Setting up Phone Authentication for Farm Agro Tech..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    if ! npm install -g firebase-tools; then
        echo "❌ Failed to install Firebase CLI. Please check your npm installation." >&2
        exit 1
    fi
    # Verify installation
    if ! command -v firebase &> /dev/null; then
        echo "❌ Firebase CLI installation failed. Please install manually." >&2
        exit 1
    fi
fi

# Login to Firebase (if not already logged in)
echo "🔐 Logging into Firebase..."
if ! firebase login; then
    echo "❌ Failed to login to Firebase. Please check your credentials and try again." >&2
    exit 1
fi

# Set the project
echo "📁 Setting Firebase project..."
if ! firebase use farmagrotech-7d3a7; then
    echo "❌ Failed to select project 'farmagrotech-7d3a7'. Please check:" >&2
    echo "   - Project exists and you have access to it" >&2
    echo "   - Project ID is correct" >&2
    echo "   - You are logged in with the correct account" >&2
    exit 1
fi

# Check current project
echo "✅ Current Firebase project:"
firebase projects:list

echo ""
echo "🎯 Next Steps:"
echo "1. Go to Firebase Console: https://console.firebase.google.com/project/farmagrotech-7d3a7"
echo "2. Navigate to Authentication → Sign-in method"
echo "3. Find 'Phone' in the providers list"
echo "4. Click on 'Phone' and toggle 'Enable' to ON"
echo "5. Click 'Save'"
echo ""
echo "📱 For testing, you can add test phone numbers:"
echo "- Go to Phone settings in Firebase Console"
echo "- Add test numbers like: +1234567890"
echo "- Use verification code: 123456"
echo ""
echo "🔒 Optional: Configure App Check"
echo "- Go to Project Settings → App Check"
echo "- Enable App Check for better security"
echo ""
echo "✅ After enabling phone auth in console, your app should work!"
