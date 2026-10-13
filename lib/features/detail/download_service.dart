import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../gallery/data/models/pixabay_image.dart';

/// Downloads the full-size image and saves it into the device photo gallery.
///
/// Permissions are handled by the `gal` plugin: [Gal.requestAccess] shows the
/// system dialog when needed (Android <= 9 storage, iOS "Add Photos").
/// Android 10+ uses MediaStore and needs no runtime permission.
class DownloadService {
  DownloadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<void> saveToGallery(
    PixabayImage image, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    // Web platform: open image in new tab for download
    if (kIsWeb) {
      throw const AppException(
        AppErrorType.platformNotSupported,
        'On web, right-click the image and select "Save image as" to download.',
      );
    }

    File? tempFile;
    try {
      if (!await Gal.hasAccess(toAlbum: true)) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          throw const AppException(
            AppErrorType.permissionDenied,
            'Permission denied. Allow photo access in system settings to save images.',
          );
        }
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/pixabay_${image.id}${_extension(image.largeImageUrl)}';
      tempFile = File(path);

      await _dio.download(
        image.largeImageUrl,
        path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );

      await Gal.putImage(path, album: AppConfig.downloadAlbum);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw const AppException(AppErrorType.cancelled, 'Download cancelled.');
      }
      throw const AppException(
          AppErrorType.network, 'Download failed. Check your connection and retry.');
    } on GalException catch (e) {
      if (e.type == GalExceptionType.accessDenied) {
        throw const AppException(
          AppErrorType.permissionDenied,
          'Permission denied. Allow photo access in system settings to save images.',
        );
      }
      if (e.type == GalExceptionType.notEnoughSpace) {
        throw const AppException(
            AppErrorType.storage, 'Not enough storage space to save the image.');
      }
      throw const AppException(
          AppErrorType.storage, 'Could not save the image to your gallery.');
    } on FileSystemException {
      throw const AppException(
          AppErrorType.storage, 'Could not write the image to storage.');
    } finally {
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
  }

  String _extension(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final dot = path.lastIndexOf('.');
    return dot == -1 ? '.jpg' : path.substring(dot);
  }
}
