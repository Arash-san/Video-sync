import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:flutter_vlc_player_example/single_tab.dart';

class ControlsOverlay extends StatelessWidget {
  StreamController eventControl;

  ControlsOverlay({Key key, this.controller, this.eventControl}) : super(key: key);

  final VlcPlayerController controller;

  static const double _playButtonIconSize = 40;
  static const double _replayButtonIconSize = 40;
  static const double _seekButtonIconSize = 20;

  static const Duration _seekStepForward = Duration(seconds: 10);
  static const Duration _seekStepBackward = Duration(seconds: -10);

  static const Color _iconColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 50),
      reverseDuration: Duration(milliseconds: 200),
      child: Builder(
        builder: (ctx) {
          if (controller.value.isEnded || controller.value.hasError) {
            return Center(
              child: SizedBox(),
              // fittedbox IconButton(
              //   onPressed: _replay,
              //   color: _iconColor,
              //   iconSize: _replayButtonIconSize,
              //   icon: Icon(Icons.replay),
              // ),
            );
          }

          switch (controller.value.playingState) {
            case PlayingState.initialized:
            case PlayingState.stopped:
            case PlayingState.paused:
              return SizedBox.expand(
                child: Container(
                  color: Colors.black45,
                  child: FittedBox(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          onPressed: () => _seekRelative(_seekStepBackward),
                          color: _iconColor,
                          iconSize: _seekButtonIconSize,
                          icon: Icon(Icons.replay_10),
                        ),
                        IconButton(
                          onPressed: _play,
                          color: _iconColor,
                          iconSize: _playButtonIconSize,
                          icon: Icon(Icons.play_arrow),
                        ),
                        IconButton(
                          onPressed: () => _seekRelative(_seekStepForward),
                          color: _iconColor,
                          iconSize: _seekButtonIconSize,
                          icon: Icon(Icons.forward_10),
                        ),
                      ],
                    ),
                  ),
                ),
              );

            case PlayingState.buffering:
            case PlayingState.playing:
              return GestureDetector(
                onTap: _pause,
                child: Container(
                  color: Colors.transparent,
                ),
              );

            case PlayingState.ended:
            case PlayingState.error:
              return Center(
                child: FittedBox(
                  child: IconButton(
                    onPressed: _replay,
                    color: _iconColor,
                    iconSize: _replayButtonIconSize,
                    icon: Icon(Icons.replay),
                  ),
                ),
              );

            default:
              return SizedBox.shrink();
          }
        },
      ),
    );
  }

  Future<void> _play() {
    print("*play");
    eventControl.sink.add(MyCustomEventType("play|send"));

    return controller.play();
  }

  Future<void> _replay() async {
    print("*replay");
    eventControl.sink.add(MyCustomEventType("replay|send"));
    await controller.stop();
    await controller.play();
  }

  Future<void> _pause() async {
    print("*pause");
    eventControl.sink.add(MyCustomEventType("pause|send"));
    if (controller.value.isPlaying) {
      await controller.pause();
    }
  }

  /// Returns a callback which seeks the video relative to current playing time.
  Future<void> _seekRelative(Duration seekStep) async {
    eventControl.sink.add(MyCustomEventType("seek|${controller.value.position + seekStep}/send"));
    print("*seek to ${controller.value.position + seekStep}");
    if (controller.value.duration != null) {
      await controller.seekTo(controller.value.position + seekStep);
    }
  }
}
