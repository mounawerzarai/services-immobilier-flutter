import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'listing_photo.dart';

const double _kHeight = 280;

/// Photos d'une annonce : on glisse de gauche à droite, avec un compteur « 2 / 5 ».
class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel({super.key, required this.photos});

  final List<String> photos;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    if (photos.isEmpty) {
      return const ListingPhoto(height: _kHeight);
    }

    return SizedBox(
      height: _kHeight,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) =>
                ListingPhoto(url: photos[i], height: _kHeight),
          ),
          if (photos.length > 1)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.text,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_index + 1} / ${photos.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}