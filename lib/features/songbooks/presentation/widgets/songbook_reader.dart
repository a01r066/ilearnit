import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/storage/offline_storage.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/providers/dio_provider.dart';
import '../../data/datasources/songbook_purchases_datasource.dart';
import '../providers/songbook_providers.dart';

/// Opens the paid songbook PDF.
///
/// Access is re-checked on every open (`resolveSongbookContent`), even
/// when a cached copy exists, so a refund or an expired subscription takes
/// effect immediately. The file lives in `OfflineStorage('songbooks')`
/// (backup-excluded, wiped on sign-out).
Future<void> openSongbook(
  BuildContext context,
  WidgetRef ref,
  String songbookId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final t = context.l10n;
  try {
    final url =
        await ref.read(songbookPurchasesDataSourceProvider).resolveContent(songbookId);
    final dir = await OfflineStorage.dir('songbooks');
    final file = File('${dir.path}${Platform.pathSeparator}$songbookId.pdf');
    if (!await file.exists()) {
      messenger.showSnackBar(SnackBar(content: Text(t.songbookPreparing)));
      await ref.read(mediaDownloadDioProvider).download(url, file.path);
    }
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      messenger.showSnackBar(SnackBar(content: Text(t.songbookNoViewer)));
    }
  } on SongbookContentException catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text(e.isLocked ? t.songbookLocked : t.songbookOpenFailed),
    ));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(t.songbookOpenFailed)));
  }
}

/// Full-screen viewer for the free sample pages (`samplePages` image URLs).
Future<void> showSongbookSample(BuildContext context, List<String> pages) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => _SampleViewer(pages: pages),
    ),
  );
}

class _SampleViewer extends StatefulWidget {
  const _SampleViewer({required this.pages});
  final List<String> pages;

  @override
  State<_SampleViewer> createState() => _SampleViewerState();
}

class _SampleViewerState extends State<_SampleViewer> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(t.songbookSamplePage('${_index + 1}', '${widget.pages.length}')),
      ),
      body: PageView.builder(
        itemCount: widget.pages.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.pages[i],
              fit: BoxFit.contain,
              placeholder: (_, __) =>
                  const CircularProgressIndicator(color: Colors.white),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}
