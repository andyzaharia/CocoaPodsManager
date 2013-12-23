CocoaPodsManager
================

A simple tool for managing your project pods. 

This app was created because we just wanted a simple, 
clean GUI(not that the non gui version isnt good :D, ) app to quickly be able to edit and manage your pods.

The current version is really in an early stage development and it doesnt support all the cocoapods features. 
Check the TODO section for features that are not implemented.

WARNING: If you use the more advanced features of CocoaPods please make sure you check the TODOs section
to see if they are implemented. CocoaPods Manager will rewrite your Pod file and you will find that other 
parts of the pod file are deleted. 

The Code is by far not the cleanest one, and a lot of optimizations are required. Heck this is even my first OSX app.

If you dont want to mess with the code you can just get the latest compiled version from here:

![Pods Window](https://dl.dropboxusercontent.com/u/9337037/CocoaPodsManager/Screenshot%202013-12-23%2018.04.15.png "")
![XCode Plugin](https://dl.dropboxusercontent.com/u/9337037/CocoaPodsManager/Screenshot%202013-12-23%2017.58.18.png "")
![Standalone app](https://dl.dropboxusercontent.com/u/9337037/CocoaPodsManager/Screenshot%202013-12-23%2018.05.53.png "")

## Requirements

- Latest CocoaPods version already installed (works with 0.23 and up, but it might work with older versions).
- Must be able to execute pod commands without using sudo from terminal.

Because we where not able to find a clean solution for getting the elevated privileges feature to 
work we decided to leave it as it is right now. We most likely will look into this in the future.

## How To Get Started

Just copy the CocoaPods Manager app into your Applications folder. Start it,
and it should be pretty straight forward to work with it.

## TODOs

Here it is, the long list of the features that must be implemented.

Dependencies

- [ ] target
- [ ] podspec

Target configuration

- [ ] link_with 
- [ ] xcodeproj

Workspace

- [ ] workspace
- [ ] generate_bridge_support
- [ ] set_arc_compatibility_flag!

Hooks

- [ ] pre_install 
- [ ] post_install

## Creators

CocoaPods Manager was created by [Andrei Zaharia](https://github.com/andyzaharia/)

## Credits

Special thanks to [Eloy Durán](https://github.com/alloy/) and [Fabio Pelosin](https://github.com/irrationalfab).

Many thanks goes to the CocoaPods community and to everyone who supports this amazing project !

## Contact

Follow me on Twitter ([@andyzaharia](https://twitter.com/andyzaharia))

## License

CocoaPods Manager is available under the MIT license.
