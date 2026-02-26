# ButterflyMX iOS SDK — Demo App

This app demonstrates how to integrate the [ButterflyMX iOS SDK](https://github.com/runslikebutter/butterflymx-sdk-ios) into a partner application. It covers authentication, user data, door release, and incoming video calls.

## Requirements

- Xcode 14+
- iOS 13+
- A ButterflyMX `client_id` (and optionally a `client_secret` for legacy flows)

> Contact [support@butterflymx.com](mailto:support@butterflymx.com) to obtain credentials.

## Getting Started

For a full walkthrough, see the [Getting Started guide](https://github.com/runslikebutter/ios-demo-app/wiki/Getting-Started-with-ButterflyMX-iOS-SDK-Demo-App).

### 1. Clone and open the project

```bash
git clone https://github.com/runslikebutter/ios-demo-app.git
cd ios-demo-app
open "ButterflyMX Demo.xcodeproj"
```

The SDK is pulled automatically via Swift Package Manager when you open the project — no additional setup required.

### 2. Add your credentials to Info.plist

Open `ButterflyMX Demo/Info.plist` and fill in the keys for the environment(s) you want to test:

| Key | Description |
|---|---|
| `butterflymxClientIdTest` | `client_id` for the development environment |
| `butterflymxSecretTest` | `client_secret` for development (leave empty to use PKCE) |
| `butterflymxClientIdSandbox` | `client_id` for sandbox |
| `butterflymxSecretSandbox` | `client_secret` for sandbox (leave empty to use PKCE) |
| `butterflymxClientIdProd` | `client_id` for production |
| `butterflymxSecretProd` | `client_secret` for production (leave empty to use PKCE) |

**PKCE vs legacy:** If you leave a `client_secret` key empty, the app automatically uses the PKCE flow — no secret is sent over the wire. If you fill it in, the legacy flow is used instead. Both work without any code changes.

### 3. Build and run

Select a simulator or device and press **Run**. Use the environment toggle on the login screen to switch between development, sandbox, and production.

## What the demo covers

| Feature | Where to look |
|---|---|
| SDK configuration | `AppDelegate.swift` |
| Authentication (PKCE + legacy) | `LoginViewController.swift` |
| User & tenant data | `AccountTableViewController.swift` |
| Door release | `DoorsTableViewController.swift` |
| Incoming video call UI | `IncomingCallViewController.swift` |
| CallKit integration | `CallKitManager.swift` |

## Auth flow reference

The login screen calls `BMXCoreKit.shared.authorize(withAuthProvider:callbackURL:viewController:)`. `LoginViewController` builds the `BMXAuthProvider` like this:

```swift
// PKCE — no secret needed (recommended for new integrations)
let authProvider = BMXAuthProvider(clientID: clientId)

// Legacy — secret present in Info.plist
let authProvider = BMXAuthProvider(secret: secret, clientID: clientId)
```

The demo picks the right initializer automatically based on whether a secret is configured.

## License

Copyright 2024–present ButterflyMX. Licensed under the Apache License, Version 2.0.
