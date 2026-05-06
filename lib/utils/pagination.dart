import 'package:flutter/material.dart';

mixin PaginationMixin<T extends StatefulWidget> on State<T> {
  int _visibleCount = 10;
  bool _isLoading = false;
  ScrollController? _scrollController;

  int get paginationBatchSize => 10;

  @protected
  List<dynamic> get paginationItems;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController!.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController!.hasClients) return;
    final maxScroll = _scrollController!.position.maxScrollExtent;
    final currentScroll = _scrollController!.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    final total = paginationItems.length;
    if (_visibleCount >= total) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _visibleCount = (_visibleCount + paginationBatchSize).clamp(0, total);
      _isLoading = false;
    });
  }

  void resetPagination() {
    setState(() {
      _visibleCount = paginationBatchSize;
    });
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  int get visibleCount => _visibleCount;
  bool get isLoading => _isLoading;
  ScrollController get scrollController => _scrollController!;
}