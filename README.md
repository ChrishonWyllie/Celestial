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
let urlString = <YourURL string>
guard let url = URL(string: urlString) else {
    return
}
let playerItem = CachableAVPlayerItem(url: url)
...
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
