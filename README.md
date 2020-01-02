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












// Image

let urlString = <your URL string>
// NOTE: The delegate is optional
let imageView = URLImageView(urlString: urlString, delegate: self)


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
