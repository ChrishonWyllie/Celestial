# Celestial

[![CI Status](https://img.shields.io/travis/ChrishonWyllie/Celestial.svg?style=flat)](https://travis-ci.org/ChrishonWyllie/Celestial)
[![Version](https://img.shields.io/cocoapods/v/Celestial.svg?style=flat)](https://cocoapods.org/pods/Celestial)
[![License](https://img.shields.io/cocoapods/l/Celestial.svg?style=flat)](https://cocoapods.org/pods/Celestial)
[![Platform](https://img.shields.io/cocoapods/p/Celestial.svg?style=flat)](https://cocoapods.org/pods/Celestial)

<br />
<br />
<div id="images">
<img style="display: inline; margin: 0 5px;" src="Github Images/Celestial-icon.png" width=300 height=300 />
</div>

## Usage

### Video

For caching videos, use the `CachableAVPlayerItem` , which has three arguments in its primary initializer:
- url: The `URL` of the video that you want to download, play and possibly cache for later.
- delegate: The `CachableAVPlayerItemDelegate` offers 5 delegate functions shown below.
- cachePolicy: The `MultimediaCachePolicy` is an <b>optional</b> argument that is set to `.allow` by default. This handles the behavior of whether the video file will be automatically cached once download completes.
```swift

// Video

let urlString = <Your URL string>
guard let url = URL(string: urlString) else {
    return
}
// NOTE: The delegate is optional
let playerItem = CachableAVPlayerItem(url: url, delegate: self, cachePolicy: .allow)

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











### Image

For caching images, the `URLImageView` has two initalizers. One for immediately downloading an image from a URL, and another for manually downloading at a specified time. This is more ideal for UICollectionView and UITableView cell use.
The first initializer accepts a `urlString: String` which is the absoluteString of the URL at which the image file is located.
Both initializers share three arguments:
- delegate: The `URLImageViewDelegate` offers 3 delegate functions shown below.
- cachePolicy: The `MultimediaCachePolicy` is an <b>optional</b> argument that is set to `.allow` by default. This handles the behavior of whether the video file will be automatically cached once download completes.
- defaultImage: This `UIImage` is an <b>optional</b> argument which will set the image to an image of your choosing if an error occurs.
```swift
let urlString = <your URL string>
// NOTE: The delegate is optional
let imageView = URLImageView(urlString: urlString, delegate: self, cachePolicy: .allow, defaultImage: nil)


extension ViewController: URLImageViewDelegate {
    
    func urlImageView(_ view: URLImageView, didFinishDownloading image: UIImage) {
         // Image has finished downloading and will be cached if cachePolicy is set to .allow
    }
    
    func urlImageView(_ view: URLImageView, downloadFailedWith error: Error) {
        // Investigate download error
    }
    
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
