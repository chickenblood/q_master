import 'package:material_ui/material_ui.dart';

/// A widget that adapts its child based on the current platform.
///
/// Provides separate builders for Material and Cupertino platforms.
class AdaptivePlatformWidget extends StatelessWidget {
  final Widget Function(BuildContext context) material;
  final Widget Function(BuildContext context) cupertino;

  const AdaptivePlatformWidget({
    super.key,
    required this.material,
    required this.cupertino,
  });

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return cupertino(context);
    } else {
      return material(context);
    }
  }
}
