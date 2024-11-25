import 'package:aves/app_flavor.dart';
import 'package:aves/main_common.dart';
import 'package:aves/services/fgw_notification_service.dart';
import 'package:aves/widget_common.dart';

import 'fgw_widget_common.dart';

const _flavor = AppFlavor.t4play;

@pragma('vm:entry-point')
void main() => mainCommon(_flavor);

@pragma('vm:entry-point')
void widgetMain() => widgetMainCommon(_flavor);

@pragma('vm:entry-point')
void fgwWidgetMain() => foregroundWallpaperWidgetMainCommon(_flavor);

@pragma('vm:entry-point')
void fgwNotificationService() => fgwNotificationServiceAsync();
