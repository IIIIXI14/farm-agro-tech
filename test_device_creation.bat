@echo off
echo Starting Flutter app with debug output...
echo.
echo Watch for these debug messages:
echo - AddDeviceConfigScreen: Current user: [user_id]
echo - AddDeviceConfigScreen: User is authenticated, proceeding with device creation
echo - AddDeviceConfigScreen: Testing database connection...
echo - FirebaseDatabaseService: Connection test successful
echo - AddDeviceConfigScreen: Database connection test passed
echo - FirebaseDatabaseService: Creating device [device_id] for user [user_id]
echo - FirebaseDatabaseService: Device [device_id] created successfully
echo.
echo If you see any errors, they will help identify the issue.
echo.
flutter run --debug
