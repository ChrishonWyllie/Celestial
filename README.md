# Celestial

[![CI Status](https://img.shields.io/travis/ChrishonWyllie/Celestial.svg?style=flat)](https://travis-ci.org/ChrishonWyllie/Celestial)
[![Version](https://img.shields.io/cocoapods/v/Celestial.svg?style=flat)](https://cocoapods.org/pods/Celestial)
[![License](https://img.shields.io/cocoapods/l/Celestial.svg?style=flat)](https://cocoapods.org/pods/Celestial)
[![Platform](https://img.shields.io/cocoapods/p/Celestial.svg?style=flat)](https://cocoapods.org/pods/Celestial)

`Celestial` is an in-app cache manager that allows you to easily cache both videos and images. You can use built-in subclasses that make this process easier or manually use the caching system.

<br />
<br />
<div id="images">
    <p align="center">
    <img style="display: inline; margin: 0 5px;" src="Github Images/celestial-app-demo-without-caching.gif" width=300 height=600 />
    <img style="display: inline; margin: 0 5px;" src="Github Images/celestial-app-demo-with-caching.gif" width=300 height=600 />
</p>
</div>

##### Table of Contents  
[Usage](#usage)
<br />
[Cache Videos](#cache_videos)
<br />
[Cache Images](#cache_images)
<br />
[Cache Images in cells](#cache_images_in_cells)
<br />
[Observe image download without delegation](#urlimageview_download_task_handlers)

<a name="usage"/>

## Usage

<a name="cache_videos" />

## Cache videos automatically

For caching videos, use the `CachableAVPlayerItem` which is a subclass of the default `AVPlayerItem` . It has three arguments in its primary (recommended) initializer:
- url: The `URL` of the video that you want to download, play and possibly cache for later.
- delegate: The `CachableAVPlayerItemDelegate` offers 5 delegate functions shown below.
- cachePolicy: The `MultimediaCachePolicy` is an <b>optional</b> argument that is set to `.allow` by default. This handles the behavior of whether the video file will be automatically cached once download completes.
```swift

import Celestial

...



let urlString = <Your URL string>
guard let url = URL(string: urlString) else {
    return
}

let playerItem = CachableAVPlayerItem(url: url, 
                                      delegate: self, 
                                      cachePolicy: .allow) // Remember, this is an default parameter. You can exclude this one if you want caching to be set to .allow.

// Initialize AVPlayerLayer and AVPlayer as usual...

...


extension ViewController: CachableAVPlayerItemDelegate {

    func playerItem(_ playerItem: CachableAVPlayerItem, didFinishDownloading data: Data) {
        // Video has finished downloading and will be cached if cachePolicy is set to .allow
    }
    
    func playerItem(_ playerItem: CachableAVPlayerItem, downloadFailedWith error: Error) {
        // Investigate download error 
    }
    
    
    
    // Optional
    
    func playerItem(_ playerItem: CachableAVPlayerItem, downloadProgress progress: CGFloat, humanReadableProgress: String) {
        // Update UI with download progress if necessary
    }

    func playerItemReadyToPlay(_ playerItem: CachableAVPlayerItem) {
        // Video is ready to begin playing
    }

    func playerItemPlaybackStalled(_ playerItem: CachableAVPlayerItem) {
        // Video playback has stalled. Update UI if necessary
    }

}
```




<br />
<br />
<br />





<a name="cache_images" />

## Cache images automatically

For caching images, use the `URLImageView` which is a subclass of the default `UIImageView` and has two initalizers. One for immediately downloading an image from a URL, and another for manually downloading at a specified time. (The second one is more ideal for UICollectionView and UITableView cell use. More on that later)

The first initializer accepts a `urlString: String` which is the absoluteString of the URL at which the image file is located.
Both initializers share three arguments:
- delegate: The `URLImageViewDelegate` offers 3 delegate functions shown below.
- cachePolicy: The `MultimediaCachePolicy` is an <b>optional</b> argument that is set to `.allow` by default. This handles the behavior of whether the video file will be automatically cached once download completes.
- defaultImage: This `UIImage` is an <b>default</b> argument which will set the image to an image of your choosing if an error occurs.
```swift
import Celestial

...


let urlString = <your URL string>
let imageView = URLImageView(urlString: urlString, 
                            delegate: self, 
                            cachePolicy: .allow, // Remember, this is an default parameter. You can exclude this one if you want caching to be set to .allow.
                            defaultImage: nil)   // Remember, this is an default parameter. You can exclude this one unless you want an image to be displayed in case of an unexpected download error.


...


extension ViewController: URLImageViewDelegate {
    
    func urlImageView(_ view: URLImageView, didFinishDownloading image: UIImage) {
         // Image has finished downloading and will be cached if cachePolicy is set to .allow
    }
    
    func urlImageView(_ view: URLImageView, downloadFailedWith error: Error) {
        // Investigate download error
    }
    
    
    // Optional 
    
    func urlImageView(_ view: URLImageView, downloadProgress progress: CGFloat, humanReadableProgress: String) {
        // Update UI with download progress if necessary
    }
}
```


<br />
<br />
<br />

<a name="cache_images_in_cells" />

## Cache images in cells...

Caching images in UICollectionViewCells and UITableViewCells is slightly different. In such cases, the `URLImageView` needs to be initialized first and the urlString will likely be provided some time later as the cell is dequeued.

```swift

struct CellModel {
    let urlString: String
}

class ImageCell: UICollectionViewCell {

    // Initialize the URLImageView within the cell as a variable.
    // NOTE: The second initializer is used which does NOT have the urlString argument.
    private var imageView: URLImageView = {
        let img = URLImageView(delegate: nil, cachePolicy: .allow, defaultImage: nil)
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


<br />
<br />
<br />

<a name="urlimageview_download_task_handlers" />

## Observe image download without delegation

You may prefer to observe three delegation properties: `download completion`, `download progress` and `errors` without using the delegation route (perhaps to keep the swift source file as short as possible).
In such cases, URLImageView provides another function for downloading and caching images from URLs:

```swift
public func loadImageFrom(urlString: String, progressHandler: (DownloadTaskProgressHandler?), completion: (() -> ())?, errorHandler: (DownloadTaskErrorHandler?))
```

which is called like so...

```swift

let imageView = URLImageView(delegate: nil, cachePolicy: .allow, defaultImage: nil)

...

let urlString = <Your URL string>

imageView.loadImageFrom(urlString: urlString, progressHandler: { (progress) in
    print("current downlod progress: \(progress)")
}, completion: {
    print("Image has finished loading")
}) { (error) in
    print("Error loading image: \(error)")
}

```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

Requires iOS 13.0

## Installation

Celestial is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Celestial'
```

## Author

ChrishonWyllie, chrishon595@yahoo.com

## License

Celestial is available under the MIT license. See the LICENSE file for more info.
