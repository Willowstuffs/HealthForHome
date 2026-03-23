import 'dart:async';

class AppRefreshService {
  static final AppRefreshService _instance = AppRefreshService._internal();
  factory AppRefreshService() => _instance;

  AppRefreshService._internal();

  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void refresh() {
    _controller.add(null);
  }
}