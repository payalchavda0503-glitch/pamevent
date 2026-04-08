import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../helpers/app_colors.dart';
import 'conditional_parent.widget.dart';

class CustomImage extends StatelessWidget {
  const CustomImage(
    this.path, {
    this.width,
    this.height,
    this.emptyOnError = false,
    this.whenEmpty,
    this.centerLoader = true,
    this.fit = BoxFit.cover,
    super.key,
  }) : isSvg = false;

  const CustomImage.svg(
    this.path, {
    this.width,
    this.height,
    this.emptyOnError = false,
    this.whenEmpty,
    this.fit = BoxFit.contain,
    super.key,
  }) : isSvg = true,
       centerLoader = false;

  final bool isSvg;

  final String? path;

  final bool emptyOnError;
  final Widget? whenEmpty;
  final bool centerLoader;
  final BoxFit fit;
  final double? width;
  final double? height;

  Widget get _errorWidget {
    if (emptyOnError) return whenEmpty ?? const SizedBox();
    return const FittedBox(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Center(
          child: Icon(color: AppColors.lightGrey, Icons.broken_image_outlined),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.trim().isEmpty) return _errorWidget;
    if (isSvg) {
      return SvgPicture.network(
        path!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _errorWidget,
      );
    }
    return CachedNetworkImage(
      imageUrl: path!,
      fit: fit,
      width: width,
      height: height,
      httpHeaders: const {'Connection': 'Keep-Alive'},
      errorWidget: (_, _, _) => _errorWidget,
      progressIndicatorBuilder: (_, _, lp) {
        return ConditionalParentWidget(
          isIncluded: centerLoader,
          parentBuilder: (child) => Center(child: child),
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              value: lp.progress,
            ),
          ),
        );
      },
    );
  }
}
