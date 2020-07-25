# Celestial

[![CI Status](https://img.shields.io/travis/ChrishonWyllie/Celestial.svg?style=flat)](https://travis-ci.org/ChrishonWyllie/Celestial)
[![Version](https://img.shields.io/cocoapods/v/Celestial.svg?style=flat)](https://cocoapods.org/pods/Celestial)
[![License](https://img.shields.io/cocoapods/l/Celestial.svg?style=flat)](https://cocoapods.org/pods/Celestial)
[![Platform](https://img.shields.io/cocoapods/p/Celestial.svg?style=flat)](https://cocoapods.org/pods/Celestial)

`Celestial` is an in-app cache manager that allows you to easily cache both videos and images. You can use built-in UIViews `URLImageView` and `URLVideoPlayerView` to quickly display cached images and videos respectively. 
These two UIView classes provide flexible options such as determing where the cached image or video will be stored: in memory or in the local file system.

<br />
<br />
<div id="images">
    <h3 align="center">
    In this small demonstration, scrolling through requires each image to constantly be re-fetched, 
    which results in redundant API calls and UI issues with flickering cells</h3>
    <p align="center">
        <img style="display: inline; margin: 0 5px;" src="Github Images/celestial-app-demo-without-caching.gif" width=300 height=600 />
        <img style="display: inline; margin: 0 5px;" src="Github Images/celestial-app-demo-with-caching.gif" width=300 height=600 />
    </p>
</div>

### Table of Contents  
* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Usage](#usage)
    * [Cache Images](#cache_images)
        * [Caching in cells](#cache_images_in_cells)
        * [Observing progress](#observing_image_download_progress)
    * [Cache Videos](#cache_videos)
* [Example App](#example-app)
<br />

<a name="prerequisites"/>

## Prerequisites

<ul>
    <li>Xcode 8.0 or higher</li>
    <li>iOS 10.0 or higher</li>
</ul>

<a name="installation"/>

## Installation

Celestial is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Celestial'
```

<a name="usage"/>

## Usage

<a name="cache_images" />

## Caching images

For caching images, use the `URLImageView` which is a subclass of the default `UIImageView` . The URLImageView can be initialized with a URL pointing to the image or this image can be manually loaded.

The first initializer accepts a `sourceURLString: String` which is the absoluteString of the URL at which the image file is located.
Both initializers share 2 arguments:
- delegate: The `URLCachableViewDelegate` notifies the receiver of events such as download completion, progress, errors, etc.
- cacheLocation: The `ResourceCacheLocation` determines where the downloaded image will be stored upon completion. By default, images are stored `inMemory`. Images or videos stored with this setting are <b>not persisted across app sessions and are subject to automatic removal by the system if memory is strained</b>. Storing with `.fileSystem` will persist the images across app sessions until manually deleted. However, for images, caching to memory is often sufficient. Set to `.none` for no caching

```swift
import Celestial

let sourceURLString = <your URL string>
let imageView = URLImageView(sourceURLString: sourceURLString, delegate: nil, cacheLocation: .inMemory)

// Will automatically load the image from the sourceURLString, and cache the downloaded image
// in a local NSCache, for reuse later

```


<br />
<br />
<br />

<a name="cache_images_in_cells" />

## Caching images in cells...

Caching images in UICollectionViewCells and UITableViewCells is slightly different. 
In such cases, the `URLImageView` needs to be initialized first and the urlString will likely be provided some time later as the cell is dequeued.

In such cases, use the `func loadImageFrom(urlString:)` function:

```swift

struct CellModel {
    let urlString: String
}

class ImageCell: UICollectionViewCell {

    // Initialize the URLImageView within the cell as a variable.
    // NOTE: The second initializer is used which does NOT have the urlString argument.
    private var imageView: URLImageView = {
        let img = URLImageView(delegate: nil, cacheLocation: .inMemory)
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        
        // Handle layout...
    }
    
    // This function is called during the cell dequeue process and will load the image
    // using the `CellModel` struct. However, this would be replaced with your method.
    public func configureCell(someCellModel: CellModel) {
        imageView.loadImageFrom(urlString: someCellModel.urlString)
    }

}
```

<a name="observing_image_download_progress"/>

## Observing download events

There are three possible events that occur when downloading images and videos: 
* The download completes successfully
* The download is currently in progress
* An error occurred whil downloading the image or video

Both `URLImageView` and `URLVideoPlayerView` offer different ways to observe these events:

### With delegation:

Extend the `URLCachableViewDelegate` to be notified of such events

```swift

let sourceURLString = <your URL string>
let imageView = URLImageView(sourceURLString: sourceURLString, delegate: self, cacheLocation: .inMemory)

...


extension ViewController: URLCachableViewDelegate {
    
    func urlCachableView(_ view: URLCachableView, didFinishDownloading media: Any) {
        // Image has finished downloading and will be cached to specified cache location
    }
    
    func urlCachableView(_ view: URLCachableView, downloadFailedWith error: Error) {
        // Investigate download error
    }
    
    func urlCachableView(_ view: URLCachableView, downloadProgress progress: Float, humanReadableProgress: String) {
        // Update UI with download progress if necessary
    }
}

```

### With completion blocks

The other option is receive these events using in-line completion blocks


```swift

let imageView = URLImageView(delegate: nil, cacheLocation: .inMemory, defaultImage: nil)

let sourceURLString = <your URL string>

imageView.loadImageFrom(urlString: sourceURLString,
progressHandler: { (progress) in
    print("current downlod progress: \(progress)")
}, completion: {
    print("Image has finished loading")
}) { (error) in
    print("Error loading image: \(error)")
}
```

<br />
<br />
<br />




<a name="cache_videos" />

## Caching videos

Similar to caching and displaying images, the `URLVideoPlayerView` will display videos and cache them later for reuse.
It encapsulates the usually tedious process or creating instances of `AVAsset`, `AVPlayerItem`, `AVPlayerLayer` and `AVPlayer` . Instead, all you need to do is provide a URL for it play.

If you have read the [Caching Images](#cache_images) section, the initializers and functions are virtually identical between `URLImageView` and `URLVideoPlayerView`

```swift

let sourceURLString = <your URL string>
let videoView = URLVideoPlyerView(sourceURLString: sourceURLString, delegate: nil, cacheLocation: .fileSystem)

```

In this example, the video will be played and cached to the local file system. <b>NOTE</b> Caching to the local system will persist the image or video across app sessions until manually deleted.

### Caching videos in cells

As previously mentioned, the functions provided in `URLVideoPlayerView` are virtually identical to those of  `URLImageView`

```swift

public func configureCell(someCellModel: CellModel) {
    playerView.loadVideoFrom(urlString: someCellModel.urlString)
}

struct CellModel {
    let urlString: String
}

class VideoCell: UICollectionViewCell {

    private var playerView: URLVideoPlayerView = {
        // Observe events with delegation...
        let v = URLVideoPlayerView(delegate: self, cacheLocation: .fileSystem)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return v
    }()
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(playerView)
        
        // Handle layout...
    }
    
    // This function is called during the cell dequeue process and will load the image
    // using the `CellModel` struct. However, this would be replaced with your method.
    public func configureCell(someCellModel: CellModel) {
        
        // Or with completion handlers...
        
        playerView.loadVideoFrom(urlString: someCellModel.urlString, 
        progressHandler: { (progress) in
            print("current downlod progress: \(progress)")
        }, completion: {
            print("Video has finished loading")
        }) { (error) in
            print("Error loading video")=
        }
    }
}

```

<a name="example-app"/>

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Author

ChrishonWyllie, chrishon595@yahoo.com

## License

Celestial is available under the MIT license. See the LICENSE file for more info.
