import 'package:flutter/material.dart';

class LoadingService extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isMergedExpanded = true;
  bool get isMergedExpanded => _isMergedExpanded;

  bool _isSelectImagesExpanded = true;
  bool get isSelectImagesExpanded => _isSelectImagesExpanded;

  void showLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void hideLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void expandMergeTile(){
    _isMergedExpanded = true;
    notifyListeners();
  }

  void collapseMergeTile(){
    _isMergedExpanded = false;
    notifyListeners();
  }

  void expandSelectImagesTile(){
    _isSelectImagesExpanded = true;
    notifyListeners();
  }

  void collapseSelectImagesTile(){
    _isSelectImagesExpanded = false;
    notifyListeners();
  }
}
