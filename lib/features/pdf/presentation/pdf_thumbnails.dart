import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Vertical strip of page previews for quick navigation.
class PdfThumbnails extends StatelessWidget {
  const PdfThumbnails({
    super.key,
    required this.document,
    required this.currentPage,
    required this.onSelected,
  });

  final PdfDocument document;
  final int currentPage;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 120,
      color: scheme.surfaceContainer,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: document.pages.length,
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          final selected = pageNumber == currentPage;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onSelected(pageNumber),
              child: Column(
                children: [
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            selected ? scheme.primary : scheme.outlineVariant,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: PdfPageView(
                      document: document,
                      pageNumber: pageNumber,
                      maximumDpi: 48,
                    ),
                  ),
                  Text(
                    '$pageNumber',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
