import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'pages/send.dart';
import 'pages/description.dart';
import 'pages/login.dart';
import 'components/app_title.dart';
import 'models/device_send_manager.dart';
import 'util.dart';
import 'theme.dart';

main() async {
  final deviceSendManager = DeviceSendManager.fromCurrentUrl();

  runApp(
    ChangeNotifierProvider<DeviceSendManager>(
      create: (context) {
        return deviceSendManager;
      },
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: enkraTheme.secondary,
      title: 'Enkra Send: Secure File Transfer with End-to-End Encryption',
      theme: ThemeData.from(
        useMaterial3: true,
        colorScheme: const ColorScheme.light().copyWith(
          primary: enkraTheme.primary,
          secondary: enkraTheme.secondary,
          onPrimary: enkraTheme.onPrimary,
          surface: enkraTheme.background,
          onSurface: enkraTheme.onBackground,
          background: enkraTheme.background,
          error: enkraTheme.danger,
          tertiary: enkraTheme.miscColor,
        ),
      ),
      home: const MyHomePage(title: 'Enkra Send'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isMobile()) {
      return buildMobile(theme);
    } else {
      return buildDesktop(theme);
    }
  }

  buildMobile(ThemeData theme) {
    return Consumer<DeviceSendManager>(
        builder: (context, deviceSendManager, child) {
      final state = deviceSendManager.currentState();

      if (state is PairedState) {
        return Scaffold(
          appBar: AppBar(
            title: AppTitle(title: widget.title),
            backgroundColor: theme.colorScheme.background,
            surfaceTintColor: theme.colorScheme.background,
          ),
          body: Column(
            children: [
              Divider(
                thickness: 1,
                height: 1,
                color: Colors.grey[300]!,
              ),
              Expanded(child: buildLeftWidget()),
            ],
          ),
        );
      } else {
        return Stack(
          children: [
            Opacity(
              opacity: 0.5,
              child: SvgPicture.asset(
                'assets/background.svg',
                semanticsLabel: 'Enkra Send background',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Scaffold(
              appBar: AppBar(
                title: AppTitle(title: widget.title),
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
              ),
              backgroundColor: Colors.transparent,
              body: buildLeftWidget(),
            ),
          ],
        );
      }
    });
  }

  buildDesktop(theme) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Stack(
            children: [
              Container(
                child: SvgPicture.asset(
                  'assets/background.svg',
                  semanticsLabel: 'Enkra Send background',
                  fit: BoxFit.fill,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: AppTitle(title: widget.title),
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                ),
                body: buildDesktopBody(theme),
              ),
            ],
          ),
        ),
      ],
    );
  }

  buildDesktopBody(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          Container(
            width: 1024,
            height: 650,
            decoration: BoxDecoration(
                color: theme.colorScheme.background,
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[300]!,
                    offset: const Offset(
                      5.0,
                      5.0,
                    ),
                    blurRadius: 18.0,
                    spreadRadius: 0.0,
                  ),
                ]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: buildLeftWidget(),
                ),
                VerticalDivider(
                  thickness: 1,
                  width: 1,
                  indent: 60,
                  endIndent: 60,
                  color: theme.primaryColor,
                ),
                const Expanded(
                  child: Center(
                    child: Description(),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  buildLeftWidget() {
    return Consumer<DeviceSendManager>(
        builder: (context, deviceSendManager, child) {
      final state = deviceSendManager.currentState();

      if (state is PairedState) {
        return SendDialog(
          pairedState: state,
        );
      } else {
        return Pairing(
          waitToPairState: state as WaitToPairState,
        );
      }
    });
  }
}
