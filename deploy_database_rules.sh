#!/bin/bash
echo "Deploying Realtime Database rules..."
firebase deploy --only database
echo "Database rules deployed successfully!"
