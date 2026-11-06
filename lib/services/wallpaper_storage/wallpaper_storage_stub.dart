class WallpaperStorageService {
  Future<bool> saveWallpaper(String base64Data) async => false;
  Future<String?> loadWallpaper() async => null;
  Future<bool> clearWallpaper() async => false;
  Future<String> compressImage(
    String dataUrl, {
    int maxDim = 1920,
    double quality = 0.85,
  }) async => dataUrl;
}
