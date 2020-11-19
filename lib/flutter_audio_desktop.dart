/* http://github.com/alexmercerind/flutter_audio_desktop */

library flutter_audio_desktop;

import 'package:flutter/services.dart';
import 'dart:io';

final MethodChannel _channel = MethodChannel('flutter_audio_desktop');

class AudioPlayer {
  final int id;
  final bool debug;
  bool isLoaded = false;
  bool isPlaying = false;
  bool isPaused = false;
  bool isStopped = true;
  double volume = .5;
  double waveAmplitude = 0.1;
  double waveFrequency = 440;
  int waveSampleRate = 44800;
  int waveType = 0;
  List<bool> _playerState = [false, false, false, true];

  /// ## Starting Audio Service
  ///
  ///     AudioPlayer audioPlayer = new AudioPlayer();
  ///
  ///  You can optionally pass `debug: true` for extra logging.
  ///
  ///     AudioPlayer audioPlayer = new AudioPlayer(debug: true);
  AudioPlayer({this.debug = false, this.id = 1}) {
    if (this.debug) {
      _channel.invokeMethod('init', {'id': id, 'debug': true});
    } else {
      _channel.invokeMethod('init', {'id': id, 'debug': false});
    }
  }

  /// ## Changing Playback Device
  ///
  ///     await audioPlayer.setDevice(deviceIndex: 0);
  ///
  /// NOTE: This method must be called before [load] method.
  ///
  /// This method might be useful, if your device has more than one available playback devices.
  void setDevice({int deviceIndex = 0}) => _channel
      .invokeMethod('setDevice', {'id': id, 'device_index': deviceIndex});

  /// ## Loading Audio File
  ///
  ///     await audioPlayer.load('/home/alexmercerind/music.mp3');
  ///
  ///  Results in `Future<true>`, if the audio file is successfully loaded.
  ///
  ///  Returns `Future<false>`, if the audio file does not exists.
  ///
  /// NOTE: When providing path as a paramter, it is recommended to use
  /// single forward slashes or double backward slashes only.
  ///
  /// Example of valid paths:
  ///
  /// 1) `"D:\\alexmercerind\\Music\\music.mp3"`
  ///
  /// 2) `"D:/alexmercerind/Music/music.mp3"`
  Future<bool> load(String fileLocation) async {
    File audioFile = File(fileLocation);
    if (this._playerState[1]) {
      await _channel.invokeMethod('pause', {'id': id});
    }
    if (this._playerState[0]) {
      await _channel.invokeMethod('stop', {'id': id});
    }
    if (await audioFile.exists()) {
      this._setPlayerState(true, false, true, true);
      await _channel
          .invokeMethod('load', {'id': id, 'file_location': fileLocation});
      return true;
    } else {
      this._setPlayerState(false, false, false, true);
      return false;
    }
  }

  /// ## Playing Loaded Audio File
  ///
  ///     await audioPlayer.play();
  ///
  ///  Starts playing the loaded audio file & results in `Future<true>`.
  ///
  ///  Returns `Future<false>` if no file is loaded or a file is already playing.
  Future<bool> play() async {
    bool success;
    if (this._playerState[1]) {
      success = false;
    } else {
      if (this._playerState[0]) {
        this._setPlayerState(true, true, false, false);
        await _channel.invokeMethod('play', {'id': id});
        success = true;
      } else {
        success = false;
      }
    }
    return success;
  }

  /// ## Loading Waves
  ///
  ///  Results in `Future<true>`, if the wave is successfully loaded.
  ///
  ///  Returns `Future<false>`, if the wave was not loaded
  ///
  /// Example of valid waves:
  ///
  /// 1) `loadWave(0.2, 200, 0)`
  ///
  /// 2) `"loadWave(0.4, 400, 3)"`
  Future<bool> loadWave(
      double amplitude, double frequency, int waveType) async {
    this._setPlayerState(true, false, true, true);
    bool success;
    if (this._playerState[1]) {
      success = false;
    } else {
      if (this._playerState[0]) {
        waveAmplitude = amplitude;
        waveFrequency = frequency;
        await _channel.invokeMethod('loadWave', {
          'id': id,
          'amplitude': amplitude,
          'frequency': frequency,
          'wave_type': waveType
        });
        success = true;
      } else {
        success = false;
      }
    }
    return success;
  }

  /// ## Pausing Loaded Audio File
  ///
  ///     await audioPlayer.pause();
  ///
  ///  Pauses the loaded audio file & results in `Future<true>`.
  ///
  ///  Returns `Future<false>` if no file is loaded or playback is already paused.
  Future<bool> pause() async {
    if (this._playerState[2]) {
      return false;
    } else {
      if (this._playerState[0]) {
        this._setPlayerState(true, false, true, false);
        await _channel.invokeMethod('pause', {'id': id});
        return true;
      } else {
        return false;
      }
    }
  }

  /// ## Unloading Audio File
  ///
  ///     await audioPlayer.pause();
  ///
  ///  Unloads loaded audio file & results in `Future<true>`.
  ///
  ///  Returns `Future<false>` if no file is loaded or a playback already stopped.
  ///
  ///  Once this method is called, you must call [load] once again.
  ///
  ///     await audioPlayer.load('/home/alexmercerind/music.mp3');
  Future<bool> stop() async {
    if (this._playerState[3]) {
      return false;
    } else {
      if (this._playerState[0]) {
        this._setPlayerState(false, false, false, true);
        await _channel.invokeMethod('pause', {'id': id});
        await _channel.invokeMethod('stop', {'id': id});
        return true;
      } else {
        return false;
      }
    }
  }

  /// ## Getting Audio File Duration
  ///
  ///     Duration audioDuration = await audioPlayer.getDuration();
  ///
  ///  Results in `Future<Duration>`.
  ///
  ///  Returns `Future<false>` if no file is loaded.
  Future<dynamic> getDuration() async {
    if (this._playerState[0]) {
      return Duration(
          milliseconds: await _channel.invokeMethod('getDuration', {'id': id}));
    } else {
      return false;
    }
  }

  /// ## Getting Audio Playback Position
  ///
  ///     Duration audioPosition = await audioPlayer.getPosition();
  ///
  ///  Results in `Future<Duration>`.
  ///
  ///  Returns `Future<false>` if no file is loaded.
  Future<dynamic> getPosition() async {
    if (this._playerState[0] &&
        (this._playerState[1] || this._playerState[2])) {
      return Duration(
          milliseconds: await _channel.invokeMethod('getPosition', {'id': id}));
    }
    if (this._playerState[0]) {
      return Duration(milliseconds: 0);
    } else {
      return false;
    }
  }

  /// ## Setting Audio Playback Position
  ///
  ///     await audioPlayer.setPosition(Duration(seconds: 18));
  ///
  ///  Results in `Future<true>`.
  ///
  ///  Returns `Future<false>` if no file is loaded.
  Future<bool> setPosition(Duration duration) async {
    if (this._playerState[0]) {
      await _channel.invokeMethod(
          'setPosition', {'id': id, 'duration': duration.inMilliseconds});
      return true;
    } else {
      return false;
    }
  }

  /// ## Setting Audio Playback Volume
  ///
  ///     audioPlayer.setVolume(0.25);
  ///
  /// You can access the volume of the player anytime later on.
  ///
  ///     double currentVolume = audioPlayer.volume;
  void setVolume(double volume) {
    _channel.invokeMethod('setVolume', {'id': id, 'volume': volume});
    this.volume = volume;
  }

  void setWaveAmplitude(double amplitude) {
    _channel
        .invokeMethod('setWaveAmplitude', {'id': id, 'amplitude': amplitude});
    this.waveAmplitude = amplitude;
  }

  void setWaveFrequency(double frequency) {
    _channel
        .invokeMethod('setWaveFrequency', {'id': id, 'frequency': frequency});
    this.waveFrequency = frequency;
  }

  void setWaveSampleRate(int sampleRate) {
    _channel.invokeMethod(
        'setWaveSampleRate', {'id': id, 'sample_rate': sampleRate});
    this.waveSampleRate = sampleRate;
  }

  void setWaveType(int waveType) {
    _channel.invokeMethod('setWaveType', {'id': id, 'wave_type': waveType});
    this.waveType = waveType;
  }

  void _setPlayerState(
      bool isLoaded, bool isPlaying, bool isPaused, bool isStopped) {
    this._playerState = [isLoaded, isPlaying, isPaused, isStopped];
    this.isLoaded = isLoaded;
    this.isPlaying = isPlaying;
    this.isPaused = isPaused;
    this.isStopped = isStopped;
  }
}
