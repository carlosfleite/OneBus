import 'package:flutter/widgets.dart';

/// What the bottom sheet is showing. The map reacts to the top page
/// (filters the line, centers the stop, follows the bus).
sealed class SheetPage {
  const SheetPage();
}

class HomePage extends SheetPage {
  const HomePage();
}

class LinePage extends SheetPage {
  final String lineId;
  const LinePage(this.lineId);
}

class StopPage extends SheetPage {
  final String stopId;
  const StopPage(this.stopId);
}

class BusPage extends SheetPage {
  final String busId;
  const BusPage(this.busId);
}

/// Every recharge point, nearest first.
class RechargeListPage extends SheetPage {
  const RechargeListPage();
}

class RechargePage extends SheetPage {
  final String pointId;
  const RechargePage(this.pointId);
}

/// Actions a sheet page can trigger on the map screen.
abstract class SheetNav {
  void push(SheetPage page);
  void pop();
  void openPass();
  void openSettings();

  bool get following;
  void follow();

  TextEditingController get search;
  FocusNode get searchFocus;
}

/// A page split into a pinned header and scrolling body.
class SheetContent {
  final Widget header;
  final double headerHeight;
  final List<Widget> body;

  const SheetContent({
    required this.header,
    required this.headerHeight,
    required this.body,
  });
}
