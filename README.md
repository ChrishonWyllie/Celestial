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
        <img style="display: inline; margin: 0 5px;" src="Github Images/Celestial-icon.png" width=300 height=300 />
    </p>
</div>

##### Table of Contents  
[Usage](#usage)
<br />
[Cache Videos](#cache_videos)
<br />
[Cache Images](#cache_images)

<a name="usage"/>

## Usage

<a name="cache_videos" />

## Cache videos automatically

For caching videos, use the `CachableAVPlayerItem` which is a subclass of the default `AVPlayerItem` . It has three arguments in its primary (recommended) initializer:
- url: The `URL` of the video that you want to download, play and possibly cache for later.
- delegate: The `CachableAVPlayerItemDelegate` offers 5 delegate functions shown below.
- cachePolicy: The `MultimediaCachePolicy` is an <b>optional</b> argument that is set to `.allow` by default. This handles the behavior of whether the video file will be automatically cached once download completes.
```swift

// Video

let urlString = <Your URL string>
guard let url = URL(string: urlString) else {
    return
}

let playerItem = CachableAVPlayerItem(url: url, 
                                      delegate: self, 
                                      cachePolicy: .allow) // Remember, this is an default parameter. You can exclude this one if you want caching to be set to .allow.

// Initialize and play your video as usual...
let player = AVPlayer(playerItem: playerItem)
player.automaticallyWaitsToMinimizeStalling = false
let playerLayer = AVPlayerLayer(player: player)

playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
playerLayer.frame = UIScreen.main.bounds
self.view.layer.addSublayer(playerLayer)
player.play()

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
