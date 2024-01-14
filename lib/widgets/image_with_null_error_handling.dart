import 'package:flutter/material.dart';

class ImageWithNullAndErrorHandling extends StatelessWidget {
  final String? imageUrl;

  const ImageWithNullAndErrorHandling({this.imageUrl, super.key});

  @override
  Widget build(BuildContext context) {
    return imageUrl != null
        ? Image.network(
            imageUrl!,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.image_not_supported);
            },
          )
        : const Icon(Icons.account_circle);
  }
}
