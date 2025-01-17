import 'dart:ui';

import 'package:aves_model/aves_model.dart';
import 'package:aves_utils/aves_utils.dart';

class SettingsDefaults {
  // video
  static const enableVideoHardwareAcceleration = true;
  static const videoAutoPlayMode = VideoAutoPlayMode.disabled;
  static const videoBackgroundMode = VideoBackgroundMode.disabled;
  static const videoLoopMode = VideoLoopMode.shortOnly;
  static const videoResumptionMode = VideoResumptionMode.ask;
  static const videoShowRawTimedText = false;
  //static const videoControlActions = [EntryAction.videoTogglePlay];
  // t4y: I prefer such button default, for double click will skip or replay.
  static const videoControlActions = [
    EntryAction.videoShowPreviousFrame,
    EntryAction.videoTogglePlay,
    EntryAction.videoShowNextFrame,
  ];
  static const videoGestureDoubleTapTogglePlay = true;
  static const videoGestureSideDoubleTapSeek = true;
  static const videoGestureVerticalDragBrightnessVolume = true;

  // subtitles
  static const subtitleFontSize = 20.0;
  static const subtitleTextAlignment = TextAlign.center;
  static const subtitleTextPosition = SubtitlePosition.bottom;
  static const subtitleShowOutline = true;
  static const subtitleTextColor = Color(0xFFFFFFFF);
  static const subtitleBackgroundColor = ColorUtils.transparentBlack;
}
