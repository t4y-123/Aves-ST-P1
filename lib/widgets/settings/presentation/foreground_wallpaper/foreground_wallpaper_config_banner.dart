import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/basic/font_size_icon_theme.dart';
import 'package:flutter/material.dart';

class ForegroundWallpaperConfigBanner<T> extends StatelessWidget {
  String bannerString;
  ForegroundWallpaperConfigBanner({super.key,required this.bannerString});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const FontSizeIconTheme(child: Icon(AIcons.info)),
          const SizedBox(width: 16),
          Expanded(child: Text(bannerString)),
        ],
      ),
    );
  }
}
