import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (goldenFileComparator is LocalFileComparator) {
    final comparator = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantComparator(
      comparator.basedir,
      0.01, // 1% tolerance
    );
  }
  await testMain();
}

class _TolerantComparator extends LocalFileComparator {
  final double threshold;

  _TolerantComparator(Uri basedir, this.threshold) : super(basedir);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final File goldenFile = File.fromUri(basedir.resolveUri(golden));
    if (!goldenFile.existsSync()) {
      return super.compare(imageBytes, golden);
    }

    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed || result.diffPercent <= threshold) {
      if (!result.passed) {
        debugPrint(
          'Golden mismatch within tolerance (${(result.diffPercent * 100).toStringAsFixed(2)}% <= ${(threshold * 100).toStringAsFixed(2)}%): $golden',
        );
      }
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}
