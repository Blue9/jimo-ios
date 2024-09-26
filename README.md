# Jimo iOS

Jimo is an open-source social map app built in SwiftUI.
It lets you save and share your favorite restaurants, activities, attractions, places to stay, shops, and more with friends.
- Map: Easily see what trusted recs are near you or explore recs from across the globe in an interactive map view. Access a business’s phone number, website, and directions.
- Feed: Stay up to date with your friends’ latest recommendations. Like posts and find inspiration for new places to visit.
- Post: Save and share your favorite restaurants, activities, attractions, places to stay and shops. Include an optional note or photo.
- Discover: Discover the latest places in a feed populated with posts by other Jimo users. Search for friends and other trustworthy accounts to follow.
- Profile: Access all of your recs in one place or view somebody else’s profile to see all of their favorite spots.


## Overview

The iOS app is built using SwiftUI. It has gone through many changes as new SwiftUI versions have come out and old ones have been deprecated, so some cruft in the codebase is expected.

We use MapKit for all map features, including for getting our place information. The benefit of this is it avoids extra dependencies and is free.

We speak to the [Jimo server](https://github.com/Blue9/jimo-server) for all app-related requests, and these are all standard HTTP requests.

## Screenshots

<img src="https://github.com/user-attachments/assets/6d6b693f-4417-4ec3-a987-b4020ba9d607" width="19%" />
<img src="https://github.com/user-attachments/assets/ed2d14f2-f496-44eb-ade6-30831e6392c7" width="19%" />
<img src="https://github.com/user-attachments/assets/3f75b99a-3063-4226-aec9-349b80bb96b1" width="19%" />
<img src="https://github.com/user-attachments/assets/7e5fd2e4-1e75-4518-a493-207f511f48e9" width="19%" />
<img src="https://github.com/user-attachments/assets/ecb8d96f-88fb-4c14-871a-dfb89fb2c624" width="19%" />

## Getting started

This project requires Xcode to build and run. Start by opening the Jimo.xcodeproj project file to set up your project.

Note: This project uses Firebase for authentication and analytics. Right now it comes with a `GoogleService-Info.plist` that points to the production Firebase config, but if you're testing with a local server you may want to change that for better control over your authentication.

## Running

To run the app, simply run from Xcode. The project uses SwiftPM for package management so the dependencies will be managed for you.

To change the server URL, edit `Core/Networking/APIClient.swift`. If you're running a localhost URL (presumably non-HTTPS), you'll have to set the port to 80 instead of 443 as well.

## Contributing

While the app is no longer officially maintained, issues, feature requests, and contributions are welcome!

## Notes

There is some dead code in this code base as a result of adding and removing features over the years. If you come across any, feel free to delete.
