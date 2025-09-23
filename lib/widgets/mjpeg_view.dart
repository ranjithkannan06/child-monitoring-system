import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MjpegView extends StatefulWidget {
  final String streamUrl;
  final BoxFit fit;

  const MjpegView({Key? key, required this.streamUrl, this.fit = BoxFit.contain}) : super(key: key);

  @override
  State<MjpegView> createState() => _MjpegViewState();
}

class _MjpegViewState extends State<MjpegView> {
  StreamSubscription<List<int>>? _subscription;
  Uint8List? _lastFrame;
  bool _connecting = true;

  @override
  void initState() {
    super.initState();
    _openStream();
  }

  @override
  void didUpdateWidget(covariant MjpegView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _closeStream();
      _openStream();
    }
  }

  @override
  void dispose() {
    _closeStream();
    super.dispose();
  }

  Future<void> _openStream() async {
    setState(() => _connecting = true);
    try {
      final request = http.Request('GET', Uri.parse(widget.streamUrl));
      final response = await http.Client().send(request);
      final byteStream = response.stream;

      // MJPEG frames are separated by JPEG SOI/EOI markers
      final buffer = BytesBuilder(copy: false);
      bool insideFrame = false;

      _subscription = byteStream.listen((List<int> chunk) {
        for (int i = 0; i < chunk.length; i++) {
          // SOI 0xFF 0xD8, EOI 0xFF 0xD9
          if (!insideFrame) {
            if (i + 1 < chunk.length && chunk[i] == 0xFF && chunk[i + 1] == 0xD8) {
              buffer.add([0xFF, 0xD8]);
              i++;
              insideFrame = true;
              setState(() => _connecting = false);
            }
          } else {
            buffer.add([chunk[i]]);
            if (i + 1 < chunk.length && chunk[i] == 0xFF && chunk[i + 1] == 0xD9) {
              buffer.add([0xD9]);
              i++;
              insideFrame = false;
              final bytes = buffer.takeBytes();
              _lastFrame = bytes;
              if (mounted) setState(() {});
            }
          }
        }
      }, onError: (_) {
        if (mounted) setState(() => _connecting = false);
      }, onDone: () {
        if (mounted) setState(() => _connecting = false);
      }, cancelOnError: true);
    } catch (_) {
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _closeStream() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_connecting && _lastFrame == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_lastFrame == null) {
      return const Center(child: Text('Camera unavailable', style: TextStyle(color: Colors.white70)));
    }
    return Image.memory(_lastFrame!, gaplessPlayback: true, fit: widget.fit);
  }
}


