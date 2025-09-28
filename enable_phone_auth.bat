@echo off
echo 🔧 Setting up Phone Authentication for Farm Agro Tech...

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI not found. Installing...
    npm install -g firebase-tools
    if %errorlevel% neq 0 (
        echo ❌ Failed to install Firebase CLI. Please check your npm installation.
        exit /b 1
    )
    REM Verify installation
    firebase --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo ❌ Firebase CLI installation failed. Please install manually.
        exit /b 1
    )
)

REM Login to Firebase (if not already logged in)
echo 🔐 Logging into Firebase...
firebase login
if %errorlevel% neq 0 (
    echo ❌ Failed to login to Firebase. Please check your credentials and try again.
    exit /b 1
)

REM Set the project
echo 📁 Setting Firebase project...
firebase use farmagrotech-7d3a7
if %errorlevel% neq 0 (
    echo ❌ Failed to select project 'farmagrotech-7d3a7'. Please check:
    echo    - Project exists and you have access to it
    echo    - Project ID is correct
    echo    - You are logged in with the correct account
    exit /b 1
)

REM Check current project
echo ✅ Current Firebase project:
firebase projects:list

echo.
echo 🎯 Next Steps:
echo 1. Go to Firebase Console: https://console.firebase.google.com/project/farmagrotech-7d3a7
echo 2. Navigate to Authentication → Sign-in method
echo 3. Find 'Phone' in the providers list
echo 4. Click on 'Phone' and toggle 'Enable' to ON
echo 5. Click 'Save'
echo.
echo 📱 For testing, you can add test phone numbers:
echo - Go to Phone settings in Firebase Console
echo - Add test numbers like: +1234567890
echo - Use verification code: 123456
echo.
echo 🔒 Optional: Configure App Check
echo - Go to Project Settings → App Check
echo - Enable App Check for better security
echo.
echo ✅ After enabling phone auth in console, your app should work!
pause
