// Tiny CSV builder + browser-side download trigger.
//
// Pure Dart string assembly per RFC 4180:
//   • Fields with comma, quote, CR, or LF → wrapped in double quotes.
//   • Internal quotes doubled.
// No external dependency.
//
// `triggerCsvDownload` is web-only (the admin portal IS web), so we
// import dart:html unconditionally and let mobile compilation fail
// loudly if the file is ever imported into the mobile build. The
// admin/* tree never reaches the mobile app entry point.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

/// Builds an RFC 4180 CSV string from a header row + a list of row
/// values. All values are stringified via [Object.toString].
String buildCsv({
  required List<String> header,
  required List<List<Object?>> rows,
}) {
  final buf = StringBuffer();
  buf.writeln(header.map(_csvField).join(','));
  for (final row in rows) {
    buf.writeln(row.map((v) => _csvField(v?.toString() ?? '')).join(','));
  }
  return buf.toString();
}

String _csvField(String raw) {
  final needsQuote = raw.contains(',') ||
      raw.contains('"') ||
      raw.contains('\n') ||
      raw.contains('\r');
  if (!needsQuote) return raw;
  final escaped = raw.replaceAll('"', '""');
  return '"$escaped"';
}

/// Trigger a browser download for [csv] with the given [filename].
/// The leading UTF-8 BOM keeps Excel from mangling non-ASCII names.
void triggerCsvDownload({
  required String csv,
  required String filename,
}) {
  final bom = [0xEF, 0xBB, 0xBF];
  final bytes = <int>[...bom, ...utf8.encode(csv)];
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
