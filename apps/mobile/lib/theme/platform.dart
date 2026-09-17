import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

/// Whether the app should render its Cupertino (iOS) widget family instead
/// of Material.
///
/// Backed by [defaultTargetPlatform] rather than `dart:io`'s
/// `Platform.isIOS` because the latter throws on the web target.
bool get isCupertino => defaultTargetPlatform == TargetPlatform.iOS;
