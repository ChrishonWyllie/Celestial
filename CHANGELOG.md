## [Version 0.8.61](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.8.61) 
### New
* N/A

### Improvements
* Replaced uses of `count == 0` or `counf > 0` with simply checking if an array `isEmpty`. According to sources, this is a more efficient approach

### Bug fixes
* N/A

## [Version 0.8.57](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.8.57) 
### New
* Added looping to URLVideoPlayerView. Can now start looping videos, with completion handler for each loop.
* Added asynchronous thumbnail generation to URLVideoPlayerView

### Improvements
* Added extension to String class to validate URL strings before initializing the URL object
* Refactored private functions for acquiring images and videos by replacing the urlString parameter with  a validated URL

### Bug fixes
* Fixed issue where using the loadVideo(…) function with completion handler would not call the completion block if the video was already cached

## [Version 0.8.46](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.8.46) 
### New
* Added Boolean for determining if `URLVideoPlayerView` is currently playing
* Made the function for setting inMemory cache item costs, public

### Improvements
* Added link to more documentation
* Added `@discardableResult` for deleting items from file system cache

### Bug fixes
* N/A

## [Version 0.8.36](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.8.36) 
### New
* N/A

### Improvements
* N/A

### Bug fixes
* Committing podspec. Failed to do so in previous new version update

## [Version 0.8.33](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.8.33) 
### New
* N/A

### Improvements
* Updated README to include documention on the `URLVideoPlayerView` as well as provided updated documentation on `URLImageView`

### Bug fixes
* N/A

## [Version 0.8.25](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.8.25) 
### New
* N/A

### Improvements
* Downgraded minimum iOS deployment target from iOS 11.0 to iOS 10.0

### Bug fixes
* N/A

## [Version 0.8.21](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.8.21) 
### New
* N/A

### Improvements
* Moved the `URLImageView` `VideoPlayerView` and `URLVideoPlayerView` and all of their relevant supplementary classes to a combined folder called views

### Bug fixes
* N/A

## [Version 0.8.18](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.8.18) 
### New
* Made the `URLImageView` `VideoPlayerView` and `URLVideoPlayerView` IBDesignable

### Improvements
* The `URLImageView` `VideoPlayerView` and `URLVideoPlayerView` can now be used in Storyboard

### Bug fixes
* N/A

## [Version 0.8.13](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.8.13) 
### New
* Committing `Podfile.lock` as suggessted by cocoapods.org

### Improvements
* N/A

### Bug fixes
* N/A

## [Version 0.8.10](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.8.10) 
### New
* Added .none case to CacheLocation to deprecate the CachePolicy enum

### Improvements
* Added relevant properties of DownloadTaskRequest to encodable/decodable functions
* Deprecated the CachePolicy enum in favor of just using CacheLocation

### Bug fixes
* N/A

## [Version 0.8.0](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.8.0) 
### New
* Created `CachedResourceIdentifierContext` to separate concerns of identifying resources
* Created `DownloadManagerContext` to separate concerns of identifying pending downloads
* Added functions for cancelling, pausing and resuming all available download tasks
* Implemented `didCompleteWithError` function for handling when downloads fail with error or finish without creating file URL
* Implemented URLSession background function to handle when downloads complete while app is in background
* Added a reset function to `URLVideoPlayerView` to perform clean up and revert to initial state
* Created internal `CachedResourceIdentifier` struct to keep track of cached resources and their location, whether in memory or file system.
* Added utility function for getting info on files cached to the file system such as file size
* Added functions for handling prefetch APIs such as pre-starting resources, cancelling and pausing downloads of external resources
* Created the `ObservableAVPlayer` class to observe when a player reaches readyToPlayStatus. The URLVideoPlayer is then notified
* Added functions to `URLVideoPlayerView` for playing video instead of accessing the player directly

### Improvements
* Cleaner code in `Celestial` class
* Cleaner code in `DownloadTaskManager` class
* Deprecated the `GenericDownloadModel` class in favor using only the `DownloadTaskRequest`, results in cleaner code
* Addressed Data race (reader/writers issue) by using synchronous and barrier requests 
* Downloads may complete while app is in background
* Improved on searching for videos in file storage by not using prefix/suffix during search. Videos are not saved by size/resolution at this time.
* Renamed functions to be more obvious with their purpose. 
* Moved a variety of structs, enums and protocols to more generic places, improving code readability
* Addressed risk of reference cycles
* Moved most functions for beginning downloads, etc. off the main thread and onto the background and userInitiated threads where applicable
* Proper observation of when a video is ready to play
* Playing videos with `URLVideoPlayerView’s` play function will observe when the player has been initialized and ready to play. Results in being able to essentially “play a video when it is ready”

### Bug fixes
* Fixed Data race (reader/writers issue)
* Fixed issue where `localUniqueFileName` would unexpectedly contain its own file extension in the file name
* Addressed reference cycles by specifying weak self in various closures
* Fixed issue where the play() function could be called on a `URLVideoPlayerView’s` `AVPlayer` before it exists, resulting in a blank view.

## [Version 0.7.38](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.7.38) 
### New
* Added custom Celestial related errors to provide more information on failed tasks
* Added URL and String extension for creating a unique local file name

### Improvements
* Improved scroll performance when downloading and displaying images in UIScrollView cells by performing UIImage resizing on another thread.
* Provided a less error-prone method of identifying cached resources by using the original SourceURL as the key. This works for both inMemory and FileSystem stored items by reconfiguring the SourceURL to be compatible with both. Improves upon handling URLs with unexpected forward slashes.

### Bug fixes
* Downloading and displaying images in UIScrollView cells no longer hangs up the main thread

## [Version 0.7.35](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.7.35) 
### New
* Downgraded minimum target from iOS 13 to iOS 11
* Added support for pre-downloading, pausing and resuming tasks. To be used with Prefetching APIs

### Improvements
* Added resource existence state check which allows for checking various states of a resource such as currently downloading, finished but uncached, cached etc. This expansion of states allows for more flexibility when handing downloading resources in UIScrollViews
* Exposure of pre-downloads allows for Prefetching APIs to begin downloads before UIScrollView cells appear on screen. Contributes to less time waiting for download
* Moved AVURLAsset.loadKeys to extension to avoid duplicated code
* Removed video resolution from file names as it serves little purpose. Cleaner code
* Used Concurrent queue to initiate downloads. 

### Bug fixes
* Use of concurrent queue to access current downloads fixes possible reader-writers crash when accessing the dictionary

## [Version 0.7.0](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.7.0) 
### New
* Added caching videos
* Added caching to file system. Option of caching to memory still available
* Added functionality to pause and resume download of external resources

### Improvements
* Added option of caching to file system fixes issue of NSCache releasing data at inopportune times.
* Prevented UI-blocking by preparing images and videos on background thread and displaying on main thread only when ready. Improves scrolling performance in UITableView and UICollectionView
* Added superclass `URLCachableView` and `URLCachableViewDelegate` to help with subclass conformance and removal of redundant delegate receivers. Latter reduces code on developer's end.

### Bug fixes
* Fixed issue of scrolling performance taking a hit when disaplying images and videos

## [Version 0.6.0](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.6.0)  

### New
* Added `VideoPlayerView` for conveniently allowing for playing videos in a UIView that maintains and auto resizes its own AVPlayerLayer. Also contains getter/setter for AVPlayer

### Improvements
N/A

### Bug fixes
N/A

## [Version 0.5.26](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.5.26)  

### New
N/A

### Improvements
N/A

### Bug fixes
* Made the setCacheCostLimit function public

## [Version 0.5.20](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.5.20)  

### New
* Added a "debug mode" to optionally print information to the console
* Added NSCacheDelegate to observe when items are about to be evicted
* Updated example code to showcase new cachable videos within UICollectionView
* Added more code examples to README

### Improvements
* Resizes downloaded images on background thread (within URLImageView downloadTask) to match the size of the URLImageView, resulting in smaller image files. This also made scrolling cells with images faster and removed visible stutter.

### Bug fixes
* Fix scroll stutter due to handling large images on main thread

## [Version 0.5.6](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.5.6)  

### New
* Implemented new URLImageView function for observing progress, completion and errors all from within the same function using closures instead of delegation.
* Implemented DownloadTaskHandler struct to assist with closure-related download function
* Updated example code to showcase new function

### Improvements
N/A

### Bug fixes
N/A

## [Version 0.5.0](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.5.0)  

### New
* Added initial usage descriptions to the README. Examples include how to initialize/use:
-  CachableAVPlayerItem for caching and playing videos
- URLimageView for caching and displaying images
- Loading cachable images in UICollectionView / UITableView cells
- Additionally, code examples show the use delegation functions

### Improvements
N/A

### Bug fixes
N/A

## [Version 0.4.0](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.4.0)  

### New
    * Created this CHANGELOG file

### Improvements
N/A

### Bug fixes
N/A

## [Version 0.3.1](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.3.1)  

### New


### Improvements
  * Added documentation to the various classes, structs, functions and properties

### Bug fixes
N/A

## [Version 0.2.5](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.2.5)  

### New

## [Version 0.2.8](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.2.8)  

### New


### Improvements
  * Changed the access modifier on the CachableAVPlayerItem and the URLImageView from public to open, in order to allow subclassing.

### Bug fixes
N/A

## [Version 0.2.5](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.2.5)  

### New


### Improvements
  * Created a convenience initializer for URLImageView that automatically loads the image from the url
  * Added two delegate functions for setting cache cost limit and count limit to Celestial

### Bug fixes
N/A

## [Version 0.2.1](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.2.1)  

### New
N/A

### Improvements
  * Latest release with video caching and image caching implemented

### Bug fixes
N/A

## [Version 0.2.0](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.2.0)  

### New
  * Implemented video caching
  * Implemented the CachableAVPlayerItem class, which is a subclass of the AVPlayerItem that allows Data(NSData) from a downloaded video to be cached.
  * Implemented the internal ResourceLoaderDelegate class, to assist with caching video data

### Improvements
N/A

### Bug fixes
N/A

## [Version 0.1.11](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.1.11)  

### New
N/A

### Improvements
  * Refactored the Image cache to be more modular

### Bug fixes
N/A

## [Version 0.1.0](https://github.com/ChrishonWyllie/Celestial/releases/tag/0.1.0)  

### New
  * First commit
  * Implemented Image caching and URLImageView which loads images from external URLs 

### Improvements
N/A

### Bug fixes
N/A
