import 'package:flutter/foundation.dart';
import 'package:image_scanner_example/main.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoProvider extends ChangeNotifier {
  List<AssetPathEntity> list = [];

  int type = 0;

  DateTime dt = DateTime.now();

  var hasAll = true;

  Map<AssetPathEntity, PathProvider> pathProviderMap = {};

  bool _notifying = false;

  bool get notifying => _notifying;

  set notifying(bool notifying) {
    _notifying = notifying;
    notifyListeners();
  }

  void changeType(int v) {
    this.type = v;
    notifyListeners();
  }

  void changeHasAll(bool value) {
    this.hasAll = value;
    notifyListeners();
  }

  void changeDateToNow() {
    this.dt = DateTime.now();
    notifyListeners();
  }

  void changeDate(DateTime pickDt) {
    this.dt = pickDt;
    notifyListeners();
  }

  void reset() {
    this.list.clear();
    pathProviderMap.clear();
  }

  Future<void> refreshGalleryList() async {
    var galleryList = await PhotoManager.getAssetPathList(
      fetchDateTime: dt,
      type: RequestType.values[type],
      hasAll: hasAll,
    );

    galleryList.sort((s1, s2) {
      return s2.assetCount.compareTo(s1.assetCount);
    });

    this.list.clear();
    this.list.addAll(galleryList);
  }

  PathProvider getOrCreatePathProvider(AssetPathEntity pathEntity) {
    pathProviderMap[pathEntity] ??= PathProvider(pathEntity);
    return pathProviderMap[pathEntity];
  }
}

class PathProvider extends ChangeNotifier {
  static const loadCount = 50;

  bool isInit = false;

  final AssetPathEntity path;
  PathProvider(this.path);

  List<AssetEntity> list = [];

  var page = 0;

  int get showItemCount {
    if (list.length == path.assetCount) {
      return path.assetCount;
    } else {
      return path.assetCount;
    }
  }

  Future onRefresh() async {
    final list = await path.getAssetListPaged(0, loadCount);
    page = 0;
    this.list.clear();
    this.list.addAll(list);
    isInit = true;
    notifyListeners();
    printListLength("onRefresh");
  }

  Future<void> onLoadMore() async {
    if (showItemCount > path.assetCount) {
      print("already max");
      return;
    }
    final list = await path.getAssetListPaged(page + 1, loadCount);
    page = page + 1;
    this.list.addAll(list);
    notifyListeners();
    printListLength("loadmore");
  }

  void delete(AssetEntity entity) async {
    final result = await PhotoManager.editor.deleteWithIds([entity.id]);
    if (result.isNotEmpty) {
      await path.refreshPathProperties(dt: path.fetchDatetime);
      final list =
          await path.getAssetListRange(start: 0, end: provider.list.length);
      printListLength("deleted");
      this.list.clear();
      this.list.addAll(list);
      notifyListeners();
    }
  }

  void printListLength(String tag) {
    print("$tag length : ${list.length}");
  }
}
