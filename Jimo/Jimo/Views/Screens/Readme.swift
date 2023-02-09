//
//  Readme.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/7/23.
//

// MARK: - Description
// Each Screen has:
// - its own view model that is passed to child views
// - a navigation destination modifier
// Child views:
// - cannot instantiate view models, can only pass them forward
// - cannot have any navigation links
// Questions: is Feed a screen? What about for you feed? Or are they one screen?
// I'd say they're two screens since they are two separate tabs

// We currently have 45 StateObjects, need that to be way lower
// - not necessarily only 1 per screen but no duplicates
//   (e.g., PostVM is duplicated and re-instantiated in a bunch of places)

// MARK: - Strategy
// Top down (screen -> component)? Bottom up? Mix of both?
// Start with ViewPost or PlaceDetails and work down
// Then work up (strategy subject to change)

// MARK: - AuthedScreens
// - Feed
//   - Listen to post updates
//   - Listen to place save updates

// - For you feed
//   - Listen to post updates
//   - Listen to place save updates

// - NotificationFeed
//   - Listen to post updates
//   - Listen to place save updates

// SearchUsers
//  - Doesn't listen to anything

// - Map
//   - Doesn't listen to anything

// - PlaceDetails
//   - Listen to post updates
//   - Listen to place save updates

// - CreatePost (no navigation though since it's kinda broken on sheets)
//   - Doesn't listen, no server state

// - View post
//   - Listen to post updates
//   - Listen to place save updates

// - Profile
//   - Listen to post updates
//   - Listen to place save updates
//   - Listen to user updates

// Settings etc. (don't really care about settings will just leave as is)

// MARK: - Example: CommentItem
// CommentItem has a StateObject to CRUD comments, this should either be an ObservedObject
// passed in by parent views or we should just pass in data directly along with modifier
// functions. CommentItem is always a child of ViewPost, so we could have ViewPost have a
// StateObject for comments (along with an ObservedObject for the post that is passed in from
// the parent view).

// MARK: Updating + syncing state
// When we like a post, we want the view to update everywhere. Example: liking a post on profile
// should update feed and all navigation destination views as well.
// When liking a post, it can publish a like event that all Screens can catch
// All Screens can implemenet/have something like a PostPlaceListener to enforce implementation of
// all listenable events. Maybe a generic AppStateObserver class

// MARK: - UnauthedScreens
// - Basically already done, just move them to folder
