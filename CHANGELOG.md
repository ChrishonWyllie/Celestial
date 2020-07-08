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
