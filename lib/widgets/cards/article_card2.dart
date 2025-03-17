import 'package:armstrong/widgets/cards/article_details_2.dart';
import 'package:flutter/material.dart';
import 'package:armstrong/widgets/cards/article_details.dart';

class ArticleCard2 extends StatelessWidget {
  final String articleId;
  final String imageUrl;
  final String title;
  final String publisher;

  const ArticleCard2({
    Key? key,
    required this.articleId,
    required this.imageUrl,
    required this.title,
    required this.publisher,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive card width
    double cardWidth = screenWidth * 0.5; // Default: 50% of screen width
    if (screenWidth > 600) cardWidth = screenWidth * 0.35; // Tablet size
    if (screenWidth > 900) cardWidth = screenWidth * 0.25; // Larger screens
    cardWidth = cardWidth.clamp(220, 400); // Min 220, Max 400

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ArticleDetailPage2(articleId: articleId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              var tween = Tween<double>(begin: 0.95, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeOutQuad));

              return ScaleTransition(
                scale: animation.drive(tween),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
          ),
        );
      },
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: AspectRatio(
                aspectRatio: 16 / 9, // Ensures image scales properly
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover, // Prevents zoom-in/zoom-out issues
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                        child: Icon(Icons.image_not_supported,
                            size: 40, color: Colors.grey)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true, // Ensures long words break properly
                  ),
                  const SizedBox(height: 6),
                  Text(
                    publisher,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 1, // Prevents overflow
                    overflow: TextOverflow.ellipsis, // Ensures truncation
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
