import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

Future<Uint8List?> generateThumbnail(String assetPath, {double positionSeconds = 0.3, int maxWidth = 512, double quality = 0.8}) async {
  final v = html.VideoElement()
    ..src = assetPath
    ..preload = 'metadata'
    ..muted = true
    ..crossOrigin = 'anonymous';
  await v.onLoadedMetadata.first;
  double t = positionSeconds;
  if (v.duration.isFinite) {
    t = t.clamp(0.0, v.duration / 2);
  }
  final seeked = v.onSeeked.first;
  v.currentTime = t;
  await seeked;
  int w = v.videoWidth;
  int h = v.videoHeight;
  if (w == 0 || h == 0) return null;
  if (w > maxWidth) {
    final ratio = maxWidth / w;
    w = maxWidth;
    h = (h * ratio).round();
  }
  final canvas = html.CanvasElement(width: w, height: h);
  final ctx = canvas.context2D;
  ctx.drawImageScaled(v, 0, 0, w, h);
  final url = canvas.toDataUrl('image/jpeg', quality);
  final i = url.indexOf(',');
  final b64 = url.substring(i + 1);
  return base64.decode(b64);
}
