
# Video sync

An application that synchronizes video playback between android devices on the same network. You can download the app [here](https://github.com/Arash-san/Video-sync/releases/tag/alpha)

This app is made with flutter. [flutter_vlc_player](https://pub.dev/packages/flutter_vlc_player) is used for the player.

This app can also be used over the internet by connecting devices using ZeroTier One or Tailscale.


## Limitations

- Currently only two devices can be connected to eachother at the same time. This will change in the upcomming versions
- Every time the user selects a video, this app will copy the video into the cache. This is due to the fact that [flutter can't directly access the video and its absolute path](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ). But before opening another video, the cache will be cleared.


