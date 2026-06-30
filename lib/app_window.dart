import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taif_alamin/utils/print_server.dart';
import 'package:window_manager/window_manager.dart';

class AppWindow extends StatefulWidget {
  final bool showBack;
  final Widget body;
  final List<Widget>? persistentFooterButtons;
  const AppWindow({
    super.key,
    this.showBack = true,
    this.body = const SizedBox.shrink(),
    this.persistentFooterButtons,
  });

  @override
  State<AppWindow> createState() => _AppWindowState();
}

class _AppWindowState extends State<AppWindow> {
  Color close = Colors.transparent,
      minimize = Colors.transparent,
      maximize = Colors.transparent,
      back = Colors.transparent;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Directionality(
          textDirection: TextDirection.ltr,
          child: DragToMoveArea(
            child: Container(
              color: Color(0xFF1E1E2E),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _backButton(),
                  Row(
                    children: [
                      _minimizeButton(),
                      _maximizeButton(),
                      _closeButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: widget.body,
        ),
      ),
      persistentFooterDecoration: BoxDecoration(),
      persistentFooterButtons: widget.persistentFooterButtons,
    );
  }

  Widget _backButton() {
    if (widget.showBack) {
      return InkWell(
        onTap: () {
          context.pop();
        },
        onHover: (value) {
          if (value) {
            back = Colors.grey;
          } else {
            back = Colors.transparent;
          }
          if (mounted) setState(() {});
        },
        child: _option(icon: 'icons/window/back.png', bgColor: back),
      );
    }
    return SizedBox.shrink();
  }

  Widget _closeButton() {
    return InkWell(
      onTap: () async {
        await PrintServer.stop();
        windowManager.close();
      },
      onHover: (value) {
        if (value) {
          close = Colors.red;
        } else {
          close = Colors.transparent;
        }
        if (mounted) setState(() {});
      },
      child: _option(icon: 'icons/window/close.png', bgColor: close),
    );
  }

  Widget _maximizeButton() {
    return InkWell(
      onHover: (value) {
        if (value) {
          maximize = Colors.amber;
        } else {
          maximize = Colors.transparent;
        }
        if (mounted) setState(() {});
      },
      onTap: () async {
        if (await windowManager.isMaximized()) {
          windowManager.unmaximize();
        } else {
          windowManager.maximize();
        }
      },
      child: _option(icon: 'icons/window/maximize.png', bgColor: maximize),
    );
  }

  Widget _minimizeButton() {
    return InkWell(
      onTap: () {
        windowManager.minimize();
      },
      onHover: (value) {
        if (value) {
          minimize = Colors.green;
        } else {
          minimize = Colors.transparent;
        }
        if (mounted) setState(() {});
      },
      child: _option(icon: 'icons/window/minimize.png', bgColor: minimize),
    );
  }

  Widget _option({required String icon, required Color bgColor}) {
    return Container(
      margin: EdgeInsets.all(4),
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Image.asset(icon, color: Colors.white, width: 16, height: 16),
      ),
    );
  }
}
