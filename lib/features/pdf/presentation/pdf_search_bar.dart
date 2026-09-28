import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Floating full-text search for the open PDF.
class PdfSearchBar extends StatefulWidget {
  const PdfSearchBar({
    super.key,
    required this.searcher,
    required this.onClose,
  });

  final PdfTextSearcher searcher;
  final VoidCallback onClose;

  @override
  State<PdfSearchBar> createState() => _PdfSearchBarState();
}

class _PdfSearchBarState extends State<PdfSearchBar> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    widget.searcher.resetTextSearch();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      widget.searcher.resetTextSearch();
    } else {
      widget.searcher.startTextSearch(query.trim(), caseInsensitive: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searcher = widget.searcher;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 340,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListenableBuilder(
            listenable: searcher,
            builder:
                (context, _) => Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search in PDF',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: _search,
                        onSubmitted: (_) => searcher.goToNextMatch(),
                      ),
                    ),
                    if (searcher.isSearching)
                      const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_text.text.isNotEmpty)
                      Text(
                        searcher.hasMatches
                            ? '${searcher.currentIndex! + 1}/${searcher.matches.length}'
                            : '0',
                      ),
                    IconButton(
                      tooltip: 'Previous match',
                      icon: const Icon(Icons.keyboard_arrow_up),
                      onPressed:
                          searcher.hasMatches ? searcher.goToPrevMatch : null,
                    ),
                    IconButton(
                      tooltip: 'Next match',
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed:
                          searcher.hasMatches ? searcher.goToNextMatch : null,
                    ),
                    IconButton(
                      tooltip: 'Close search',
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}
