import 'package:flutter/material.dart';
import 'car_texture_background.dart';
import '../theme/app_theme.dart';

class CarTextureScaffold extends Scaffold {
  const CarTextureScaffold({
    super.key,
    super.appBar,
    super.body,
    super.floatingActionButton,
    super.floatingActionButtonLocation,
    super.drawer,
    super.endDrawer,
    super.backgroundColor,
    super.resizeToAvoidBottomInset,
    super.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return CarTextureBackground(
      opacity: 0.04,
      child: Scaffold(
        backgroundColor: backgroundColor ?? AppTheme.backgroundColor,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        drawer: drawer,
        endDrawer: endDrawer,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

