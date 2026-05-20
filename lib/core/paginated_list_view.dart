import 'package:flutter/material.dart';

import 'paginated.dart';

typedef PageFetcher<T> = Future<PaginatedResult<T>> Function(int page, int perPage);
typedef PageItemBuilder<T> = Widget Function(BuildContext context, T item);

class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.fetcher,
    required this.itemBuilder,
    this.headerSliver,
    this.emptyMessage = 'Kayıt yok.',
    this.cacheKey,
  });

  final PageFetcher<T> fetcher;
  final PageItemBuilder<T> itemBuilder;

  /// Optional sticky header shown above the swipeable pages (e.g. balance card,
  /// tabs). Stays fixed while pages swipe horizontally.
  final Widget? headerSliver;

  final String emptyMessage;

  /// When the cacheKey changes, internal cache + state are reset (e.g. when a
  /// status filter changes outside this widget).
  final Object? cacheKey;

  @override
  State<PaginatedListView<T>> createState() => PaginatedListViewState<T>();
}

class PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  late PageController _pageController;
  int _perPage = kDefaultPerPage;
  int _currentPageIndex = 0; // 0-based
  int _knownLastPage = 1;
  int _total = 0;
  final Map<int, Future<PaginatedResult<T>>> _pageFutures = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadPage(0);
  }

  @override
  void didUpdateWidget(covariant PaginatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey) {
      _reset();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    setState(() {
      _pageFutures.clear();
      _currentPageIndex = 0;
      _knownLastPage = 1;
      _total = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    _loadPage(0);
  }

  /// Invalidate cache and reload (called from external refresh).
  Future<void> refresh() async {
    final wasOnIndex = _currentPageIndex;
    setState(() {
      _pageFutures.clear();
    });
    _loadPage(wasOnIndex);
    await _pageFutures[wasOnIndex];
  }

  Future<PaginatedResult<T>> _loadPage(int pageIndex) {
    final cached = _pageFutures[pageIndex];
    if (cached != null) return cached;

    final future =
        widget.fetcher(pageIndex + 1, _perPage).then((result) {
      if (mounted) {
        setState(() {
          _knownLastPage = result.lastPage;
          _total = result.total;
        });
      }
      return result;
    });
    _pageFutures[pageIndex] = future;
    return future;
  }

  void _onPerPageChanged(int? value) {
    if (value == null || value == _perPage) return;
    setState(() {
      _perPage = value;
      _pageFutures.clear();
      _currentPageIndex = 0;
      _knownLastPage = 1;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    _loadPage(0);
  }

  void _goToPage(int index) {
    final clamped = index.clamp(0, _knownLastPage - 1);
    _pageController.animateToPage(
      clamped,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (widget.headerSliver != null) widget.headerSliver!,

        // Top bar: per-page selector + summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _total > 0
                      ? 'Toplam $_total kayıt'
                      : ' ',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Text('Sayfa başına: ',
                  style: theme.textTheme.bodySmall),
              DropdownButton<int>(
                value: _perPage,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: [
                  for (final opt in kPerPageOptions)
                    DropdownMenuItem(value: opt, child: Text('$opt')),
                ],
                onChanged: _onPerPageChanged,
              ),
            ],
          ),
        ),

        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _knownLastPage,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) {
              setState(() => _currentPageIndex = i);
              _loadPage(i);
              if (i + 1 < _knownLastPage) {
                _loadPage(i + 1); // prefetch next
              }
            },
            itemBuilder: (context, pageIndex) {
              return FutureBuilder<PaginatedResult<T>>(
                future: _loadPage(pageIndex),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Hata: ${snap.error}'),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () {
                                setState(() {
                                  _pageFutures.remove(pageIndex);
                                });
                                _loadPage(pageIndex);
                              },
                              child: const Text('Tekrar dene'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final data = snap.data!;
                  if (data.items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(child: Text(widget.emptyMessage)),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: data.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) =>
                        widget.itemBuilder(ctx, data.items[i]),
                  );
                },
              );
            },
          ),
        ),

        // Bottom: page indicator + prev/next
        if (_knownLastPage > 1)
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPageIndex > 0
                      ? () => _goToPage(_currentPageIndex - 1)
                      : null,
                  tooltip: 'Önceki sayfa',
                ),
                Text(
                  'Sayfa ${_currentPageIndex + 1} / $_knownLastPage',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPageIndex < _knownLastPage - 1
                      ? () => _goToPage(_currentPageIndex + 1)
                      : null,
                  tooltip: 'Sonraki sayfa',
                ),
              ],
            ),
          ),
      ],
    );
  }
}
