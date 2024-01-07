import 'package:flutter/material.dart';

Widget ImageWithNullAndErrorHandling(String? imageUrl) {
  return imageUrl != null
      ? Image.network(
          imageUrl,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.image_not_supported);
          },
        )
      : const Icon(Icons.account_circle);
}
