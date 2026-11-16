import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as material;

import 'adaptive_platform.dart';

/// An indeterminate Material progress indicator or Cupertino activity spinner.
class AdaptiveActivityIndicator extends StatelessWidget {
  const AdaptiveActivityIndicator({super.key});

  @override
  Widget build(BuildContext context) => isMaterialPlatform(context)
      ? const material.CircularProgressIndicator()
      : const cupertino.CupertinoActivityIndicator();
}
