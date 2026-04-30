// ignore_for_file: avoid_print

import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:preference_list/preference_list.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'package:window_manager_plus_example/utils/config.dart';

const _kSizes = [
  Size(400, 400),
  Size(600, 600),
  Size(800, 800),
];

const _kMinSizes = [
  Size(400, 400),
  Size(600, 600),
];

const _kMaxSizes = [
  Size(600, 600),
  Size(800, 800),
];

// These are two custom colors that are used in the preference_list package.
// We reuse them here for consistency.
const gray1 = Color(0xff999999);
const gray2 = Color(0xff9b9b9b);

class ListenableInfoWidget extends StatelessWidget {
  ListenableInfoWidget.global(
      this.listener, this.listeningToThis, this.switchListenableCallback)
      : title = "Global",
        _instance = null,
        switchTargetCallback = null,
        targetingThis = false;

  ListenableInfoWidget.fromWMP(
      WindowManagerPlus instance,
      this.listener,
      this.targetingThis,
      this.switchTargetCallback,
      this.listeningToThis,
      this.switchListenableCallback)
      : title = instance.toString(),
        _instance = instance;

  final String title;
  final WindowListener listener;
  final bool targetingThis;
  final Function(WindowManagerPlus?)? switchTargetCallback;
  final bool listeningToThis;
  final Function(WindowManagerPlus?) switchListenableCallback;
  final WindowManagerPlus? _instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 48,
      ),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Row(
        children: [
          Container(
              height: 20,
              width: 200,
              alignment: Alignment.centerLeft,
              padding: EdgeInsetsGeometry.only(left: 20),
              child: Text(
                title,
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.left,
              )),
          Padding(
              padding: EdgeInsetsGeometry.symmetric(vertical: 2),
              child: VerticalDivider(thickness: 1, color: gray2)),
          Container(
            height: 20,
            width: 180,
            alignment: Alignment.center,
            child: _instance == null
                ? Text('')
                : targetingThis
                    ? Text('Current Target', style: TextStyle(color: gray2))
                    : TextButton(
                        child: Text('Set Target'),
                        onPressed: () => switchTargetCallback!(_instance),
                      ),
          ),
          Padding(
              padding: EdgeInsetsGeometry.symmetric(vertical: 2),
              child: VerticalDivider(thickness: 1, color: gray2)),
          Container(
            height: 20,
            width: 180,
            alignment: Alignment.center,
            child: listeningToThis
                ? Text('Listening', style: TextStyle(color: gray2))
                : TextButton(
                    child: Text('Listen'),
                    onPressed: () => switchListenableCallback(_instance),
                  ),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        spacing: 5,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

const _kIconTypeDefault = 'default';
const _kIconTypeOriginal = 'original';

class _HomePageState extends State<HomePage> with TrayListener, WindowListener {
  bool _isPreventClose = false;
  Size _size = _kSizes.first;
  Size? _minSize;
  Size? _maxSize;
  bool _isFullScreen = false;
  bool _isResizable = true;
  bool _isMovable = true;
  bool _isMinimizable = true;
  bool _isMaximizable = true;
  bool _isClosable = true;
  bool _isAlwaysOnTop = false;
  bool _isAlwaysOnBottom = false;
  bool _isSkipTaskbar = false;
  double _progress = 0;
  bool _hasShadow = true;
  double _opacity = 1;
  bool _isIgnoreMouseEvents = false;
  String _iconType = _kIconTypeOriginal;
  bool _isVisibleOnAllWorkspaces = false;

  final TextEditingController _methodNameController =
      TextEditingController(text: 'testMethodName');
  final TextEditingController _firstArgController = TextEditingController();

  List<WindowManagerPlus> windowManagerPlusInstances = [];
  WindowManagerPlus? listeningTo = null;
  WindowManagerPlus? currentTarget = null;

  TextEditingController idFieldController = TextEditingController();

  WindowManagerPlus getTargetWMP() {
    return currentTarget ?? WindowManagerPlus.current;
  }

  void switchListenable(WindowManagerPlus? wmp) {
    if (WindowManagerPlus.globalListeners.contains(this)) {
      WindowManagerPlus.removeGlobalListener(this);
    }
    if (listeningTo != null) {
      listeningTo!.removeListener(this);
    }
    if (wmp == null) {
      // we are switching to the global listener
      WindowManagerPlus.addGlobalListener(this);
      setState(() {
        listeningTo = null;
      });
    } else {
      // we are switching to a specific listener
      wmp.addListener(this);
      setState(() {
        listeningTo = wmp;
      });
    }
  }

  void switchTarget(WindowManagerPlus? wmp) {
    setState(() {
      currentTarget = wmp;
    });
  }

  @override
  void initState() {
    trayManager.addListener(this);
    windowManagerPlusInstances.add(WindowManagerPlus.current);
    switchListenable(WindowManagerPlus.current);
    switchTarget(WindowManagerPlus.current);
    // WindowManagerPlus.addGlobalListener(this);
    _init();
    super.initState();
  }

  @override
  void dispose() {
    _methodNameController.dispose();
    _firstArgController.dispose();
    trayManager.removeListener(this);
    switchListenable(null);
    switchTarget(null);
    // WindowManagerPlus.removeGlobalListener(this);
    super.dispose();
  }

  Future<void> _init() async {
    await trayManager.setIcon(
      Platform.isWindows
          ? 'images/tray_icon_original.ico'
          : 'images/tray_icon_original.png',
    );
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show Window',
        ),
        MenuItem(
          key: 'set_ignore_mouse_events',
          label: 'setIgnoreMouseEvents(false)',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit App',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
    setState(() {});
  }

  Future<void> _handleSetIcon(String iconType) async {
    _iconType = iconType;
    String iconPath =
        Platform.isWindows ? 'images/tray_icon.ico' : 'images/tray_icon.png';

    if (_iconType == 'original') {
      iconPath = Platform.isWindows
          ? 'images/tray_icon_original.ico'
          : 'images/tray_icon_original.png';
    }

    await getTargetWMP().setIcon(iconPath);
  }

  Widget _buildBody(BuildContext context) {
    return PreferenceList(
      children: <Widget>[
        PreferenceListSection(
          children: [
            PreferenceListItem(
              title: const Text('ThemeMode'),
              detailText: Text('${sharedConfig.themeMode}'),
              onTap: () async {
                ThemeMode newThemeMode =
                    sharedConfig.themeMode == ThemeMode.light
                        ? ThemeMode.dark
                        : ThemeMode.light;

                await sharedConfigManager.setThemeMode(newThemeMode);
                await WindowManagerPlus.current.setBrightness(
                  newThemeMode == ThemeMode.light
                      ? Brightness.light
                      : Brightness.dark,
                );
                setState(() {});
              },
            ),
          ],
        ),
        PreferenceListSection(
          title: const Text('METHODS'),
          children: [
            PreferenceListItem(
              title: const Text('createWindow'),
              onTap: () async {
                final newWindow = await WindowManagerPlus.createWindow(
                    ['test args 1', 'test args 2']);
                if (newWindow != null) {
                  setState(() {
                    windowManagerPlusInstances.add(newWindow!);
                  });
                }
                BotToast.showText(text: 'New Created Window: $newWindow');
              },
            ),
            PreferenceListItem(
              title: const Text('getAllWindowManagerIds'),
              onTap: () async {
                final windowManagerIds =
                    await WindowManagerPlus.getAllWindowManagerIds();
                BotToast.showText(
                    text: 'WindowManager ID List: $windowManagerIds');
              },
            ),
            PreferenceListItem(
              title: const Text('invokeMethodToWindow'),
              onTap: () async {
                final sortedWindowManagerIds =
                    (await WindowManagerPlus.getAllWindowManagerIds())
                        // .where((wId) => wId != WindowManagerPlus.current.id)
                        .toList();
                sortedWindowManagerIds.sort();
                int? selectedWindowTargetId = await showDialog(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      title: const Text(
                          'Select the Target Window to invoke the method'),
                      content: SizedBox(
                        width: 300,
                        height: 300,
                        child: ListView(
                          children: [
                            TextField(
                              controller: _methodNameController,
                              decoration: const InputDecoration(
                                labelText: 'Method name to be invoked',
                              ),
                            ),
                            TextField(
                              controller: _firstArgController,
                              decoration: const InputDecoration(
                                labelText: 'First argument to be passed',
                              ),
                            ),
                            for (var id in sortedWindowManagerIds)
                              ListTile(
                                title: Text('WindowManager ID: $id'),
                                onTap: () {
                                  Navigator.of(context).pop(id);
                                },
                              ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );

                if (selectedWindowTargetId != null) {
                  final response = await getTargetWMP().invokeMethodToWindow(
                      selectedWindowTargetId,
                      _methodNameController.text,
                      _firstArgController.text.trim().isNotEmpty
                          ? [_firstArgController.text.trim()]
                          : null);
                  BotToast.showText(
                      text: 'Response from $selectedWindowTargetId: $response');
                }
              },
            ),
            PreferenceListItem(
              title: const Text('setAsFrameless'),
              onTap: () async {
                await getTargetWMP().setAsFrameless();
              },
            ),
            PreferenceListItem(
              title: const Text('close'),
              onTap: () async {
                await getTargetWMP().close();
                await Future.delayed(const Duration(seconds: 2));
                await getTargetWMP().show();
              },
            ),
            PreferenceListSwitchItem(
              title: const Text('isPreventClose / setPreventClose'),
              onTap: () async {
                _isPreventClose = await getTargetWMP().isPreventClose();
                BotToast.showText(text: 'isPreventClose: $_isPreventClose');
              },
              value: _isPreventClose,
              onChanged: (newValue) async {
                _isPreventClose = newValue;
                await getTargetWMP().setPreventClose(_isPreventClose);
                setState(() {});
              },
            ),
            PreferenceListItem(
              title: const Text('focus / blur'),
              onTap: () async {
                await getTargetWMP().blur();
                await Future.delayed(const Duration(seconds: 2));
                print('isFocused: ${await getTargetWMP().isFocused()}');
                await Future.delayed(const Duration(seconds: 2));
                await getTargetWMP().focus();
                await Future.delayed(const Duration(seconds: 2));
                print('isFocused: ${await getTargetWMP().isFocused()}');
              },
            ),
            PreferenceListItem(
              title: const Text('show / hide'),
              onTap: () async {
                await getTargetWMP().hide();
                await Future.delayed(const Duration(seconds: 2));
                await getTargetWMP().show();
                await getTargetWMP().focus();
              },
            ),
            PreferenceListItem(
              title: const Text('isVisible'),
              onTap: () async {
                bool isVisible = await getTargetWMP().isVisible();
                BotToast.showText(
                  text: 'isVisible: $isVisible',
                );

                await Future.delayed(const Duration(seconds: 2));
                getTargetWMP().hide();
                isVisible = await getTargetWMP().isVisible();
                print('isVisible: $isVisible');
                await Future.delayed(const Duration(seconds: 2));
                getTargetWMP().show();
              },
            ),
            PreferenceListItem(
              title: const Text('isMaximized'),
              onTap: () async {
                bool isMaximized = await getTargetWMP().isMaximized();
                BotToast.showText(
                  text: 'isMaximized: $isMaximized',
                );
              },
            ),
            PreferenceListItem(
              title: const Text('maximize / unmaximize'),
              onTap: () async {
                getTargetWMP().maximize();
                await Future.delayed(const Duration(seconds: 2));
                getTargetWMP().unmaximize();
              },
            ),
            PreferenceListItem(
              title: const Text('isMinimized'),
              onTap: () async {
                bool isMinimized = await getTargetWMP().isMinimized();
                BotToast.showText(
                  text: 'isMinimized: $isMinimized',
                );

                await Future.delayed(const Duration(seconds: 2));
                getTargetWMP().minimize();
                await Future.delayed(const Duration(seconds: 2));
                isMinimized = await getTargetWMP().isMinimized();
                print('isMinimized: $isMinimized');
                getTargetWMP().restore();
              },
            ),
            PreferenceListItem(
              title: const Text('minimize / restore'),
              onTap: () async {
                getTargetWMP().minimize();
                await Future.delayed(const Duration(seconds: 2));
                getTargetWMP().restore();
              },
            ),
            PreferenceListItem(
              title: const Text('dock / undock'),
              onTap: () async {
                DockSide? isDocked = await getTargetWMP().isDocked();
                BotToast.showText(text: 'isDocked: $isDocked');
              },
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('dock left'),
                    onPressed: () async {
                      getTargetWMP().dock(side: DockSide.left, width: 500);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('dock right'),
                    onPressed: () async {
                      getTargetWMP().dock(side: DockSide.right, width: 500);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('undock'),
                    onPressed: () async {
                      getTargetWMP().undock();
                    },
                  ),
                ],
              ),
            ),
            PreferenceListSwitchItem(
              title: const Text('isFullScreen / setFullScreen'),
              onTap: () async {
                bool isFullScreen = await getTargetWMP().isFullScreen();
                BotToast.showText(text: 'isFullScreen: $isFullScreen');
              },
              value: _isFullScreen,
              onChanged: (newValue) {
                _isFullScreen = newValue;
                getTargetWMP().setFullScreen(_isFullScreen);
                setState(() {});
              },
            ),
            PreferenceListItem(
              title: const Text('setAspectRatio'),
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('reset'),
                    onPressed: () async {
                      getTargetWMP().setAspectRatio(0);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('1:1'),
                    onPressed: () async {
                      getTargetWMP().setAspectRatio(1);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('16:9'),
                    onPressed: () async {
                      getTargetWMP().setAspectRatio(16 / 9);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('4:3'),
                    onPressed: () async {
                      getTargetWMP().setAspectRatio(4 / 3);
                    },
                  ),
                ],
              ),
            ),
            PreferenceListItem(
              title: const Text('setBackgroundColor'),
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('transparent'),
                    onPressed: () async {
                      getTargetWMP().setBackgroundColor(Colors.transparent);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('red'),
                    onPressed: () async {
                      getTargetWMP().setBackgroundColor(Colors.red);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('green'),
                    onPressed: () async {
                      getTargetWMP().setBackgroundColor(Colors.green);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('blue'),
                    onPressed: () async {
                      getTargetWMP().setBackgroundColor(Colors.blue);
                    },
                  ),
                ],
              ),
            ),
            PreferenceListItem(
              title: const Text('setBounds / setBounds'),
              accessoryView: ToggleButtons(
                onPressed: (int index) async {
                  _size = _kSizes[index];
                  Offset newPosition = await calcWindowPosition(
                    _size,
                    Alignment.center,
                  );
                  await getTargetWMP().setBounds(
                    // Rect.fromLTWH(
                    //   bounds.left + 10,
                    //   bounds.top + 10,
                    //   _size.width,
                    //   _size.height,
                    // ),
                    null,
                    position: newPosition,
                    size: _size,
                    animate: true,
                  );
                  setState(() {});
                },
                isSelected: _kSizes.map((e) => e == _size).toList(),
                children: <Widget>[
                  for (var size in _kSizes)
                    Text(' ${size.width.toInt()}x${size.height.toInt()} '),
                ],
              ),
              onTap: () async {
                Rect bounds = await getTargetWMP().getBounds();
                Size size = bounds.size;
                Offset origin = bounds.topLeft;
                BotToast.showText(
                  text: '${size.toString()}\n${origin.toString()}',
                );
              },
            ),
            PreferenceListItem(
              title: const Text('setAlignment'),
              accessoryView: SizedBox(
                width: 300,
                child: Wrap(
                  children: [
                    CupertinoButton(
                      child: const Text('topLeft'),
                      onPressed: () async {
                        await getTargetWMP().setAlignment(
                          Alignment.topLeft,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('topCenter'),
                      onPressed: () async {
                        await getTargetWMP().setAlignment(
                          Alignment.topCenter,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('topRight'),
                      onPressed: () async {
                        await getTargetWMP().setAlignment(
                          Alignment.topRight,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('centerLeft'),
                      onPressed: () async {
                        await getTargetWMP().setAlignment(
                          Alignment.centerLeft,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('center'),
                      onPressed: () async {
                        await getTargetWMP().setAlignment(
                          Alignment.center,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('centerRight'),
                      onPressed: () async {
                        await getTargetWMP().setAlignment(
                          Alignment.centerRight,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('bottomLeft'),
                      onPressed: () async {
                        await getTargetWMP().setAlignment(
                          Alignment.bottomLeft,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('bottomCenter'),
                      onPressed: () async {
                        await getTargetWMP().setAlignment(
                          Alignment.bottomCenter,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('bottomRight'),
                      onPressed: () async {
                        await getTargetWMP().setAlignment(
                          Alignment.bottomRight,
                          animate: true,
                        );
                      },
                    ),
                  ],
                ),
              ),
              onTap: () async {},
            ),
            PreferenceListItem(
              title: const Text('center'),
              onTap: () async {
                await getTargetWMP().center();
              },
            ),
            PreferenceListItem(
              title: const Text('getPosition / setPosition'),
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('xy>zero'),
                    onPressed: () async {
                      getTargetWMP().setPosition(const Offset(0, 0));
                      setState(() {});
                    },
                  ),
                  CupertinoButton(
                    child: const Text('x+20'),
                    onPressed: () async {
                      Offset p = await getTargetWMP().getPosition();
                      getTargetWMP().setPosition(Offset(p.dx + 20, p.dy));
                      setState(() {});
                    },
                  ),
                  CupertinoButton(
                    child: const Text('x-20'),
                    onPressed: () async {
                      Offset p = await getTargetWMP().getPosition();
                      getTargetWMP().setPosition(Offset(p.dx - 20, p.dy));
                      setState(() {});
                    },
                  ),
                  CupertinoButton(
                    child: const Text('y+20'),
                    onPressed: () async {
                      Offset p = await getTargetWMP().getPosition();
                      getTargetWMP().setPosition(Offset(p.dx, p.dy + 20));
                      setState(() {});
                    },
                  ),
                  CupertinoButton(
                    child: const Text('y-20'),
                    onPressed: () async {
                      Offset p = await getTargetWMP().getPosition();
                      getTargetWMP().setPosition(Offset(p.dx, p.dy - 20));
                      setState(() {});
                    },
                  ),
                ],
              ),
              onTap: () async {
                Offset position = await getTargetWMP().getPosition();
                BotToast.showText(
                  text: position.toString(),
                );
              },
            ),
            PreferenceListItem(
              title: const Text('getSize / setSize'),
              accessoryView: CupertinoButton(
                child: const Text('Set'),
                onPressed: () async {
                  Size size = await getTargetWMP().getSize();
                  getTargetWMP().setSize(
                    Size(size.width + 100, size.height + 100),
                  );
                  setState(() {});
                },
              ),
              onTap: () async {
                Size size = await getTargetWMP().getSize();
                BotToast.showText(
                  text: size.toString(),
                );
              },
            ),
            PreferenceListItem(
              title: const Text('getMinimumSize / setMinimumSize'),
              accessoryView: ToggleButtons(
                onPressed: (int index) {
                  _minSize = _kMinSizes[index];
                  getTargetWMP().setMinimumSize(_minSize!);
                  setState(() {});
                },
                isSelected: _kMinSizes.map((e) => e == _minSize).toList(),
                children: <Widget>[
                  for (var size in _kMinSizes)
                    Text(' ${size.width.toInt()}x${size.height.toInt()} '),
                ],
              ),
            ),
            PreferenceListItem(
              title: const Text('getMaximumSize / setMaximumSize'),
              accessoryView: ToggleButtons(
                onPressed: (int index) {
                  _maxSize = _kMaxSizes[index];
                  getTargetWMP().setMaximumSize(_maxSize!);
                  setState(() {});
                },
                isSelected: _kMaxSizes.map((e) => e == _maxSize).toList(),
                children: <Widget>[
                  for (var size in _kMaxSizes)
                    Text(' ${size.width.toInt()}x${size.height.toInt()} '),
                ],
              ),
            ),
            PreferenceListSwitchItem(
              title: const Text('isResizable / setResizable'),
              onTap: () async {
                bool isResizable = await getTargetWMP().isResizable();
                BotToast.showText(text: 'isResizable: $isResizable');
              },
              value: _isResizable,
              onChanged: (newValue) {
                _isResizable = newValue;
                getTargetWMP().setResizable(_isResizable);
                setState(() {});
              },
            ),
            PreferenceListSwitchItem(
              title: const Text('isMovable / setMovable'),
              onTap: () async {
                bool isMovable = await getTargetWMP().isMovable();
                BotToast.showText(text: 'isMovable: $isMovable');
              },
              value: _isMovable,
              onChanged: (newValue) {
                _isMovable = newValue;
                getTargetWMP().setMovable(_isMovable);
                setState(() {});
              },
            ),
            PreferenceListSwitchItem(
              title: const Text('isMinimizable / setMinimizable'),
              onTap: () async {
                _isMinimizable = await getTargetWMP().isMinimizable();
                setState(() {});
                BotToast.showText(text: 'isMinimizable: $_isMinimizable');
              },
              value: _isMinimizable,
              onChanged: (newValue) async {
                await getTargetWMP().setMinimizable(newValue);
                _isMinimizable = await getTargetWMP().isMinimizable();
                print('isMinimizable: $_isMinimizable');
                setState(() {});
              },
            ),
            PreferenceListSwitchItem(
              title: const Text('isMaximizable / setMaximizable'),
              onTap: () async {
                _isMaximizable = await getTargetWMP().isMaximizable();
                setState(() {});
                BotToast.showText(text: 'isClosable: $_isMaximizable');
              },
              value: _isMaximizable,
              onChanged: (newValue) async {
                await getTargetWMP().setMaximizable(newValue);
                _isMaximizable = await getTargetWMP().isMaximizable();
                print('isMaximizable: $_isMaximizable');
                setState(() {});
              },
            ),
            PreferenceListSwitchItem(
              title: const Text('isClosable / setClosable'),
              onTap: () async {
                _isClosable = await getTargetWMP().isClosable();
                setState(() {});
                BotToast.showText(text: 'isClosable: $_isClosable');
              },
              value: _isClosable,
              onChanged: (newValue) async {
                await getTargetWMP().setClosable(newValue);
                _isClosable = await getTargetWMP().isClosable();
                print('isClosable: $_isClosable');
                setState(() {});
              },
            ),
            PreferenceListSwitchItem(
              title: const Text('isAlwaysOnTop / setAlwaysOnTop'),
              onTap: () async {
                bool isAlwaysOnTop = await getTargetWMP().isAlwaysOnTop();
                BotToast.showText(text: 'isAlwaysOnTop: $isAlwaysOnTop');
              },
              value: _isAlwaysOnTop,
              onChanged: (newValue) {
                _isAlwaysOnTop = newValue;
                getTargetWMP().setAlwaysOnTop(_isAlwaysOnTop);
                setState(() {});
              },
            ),
            PreferenceListSwitchItem(
              title: const Text('isAlwaysOnBottom / setAlwaysOnBottom'),
              onTap: () async {
                bool isAlwaysOnBottom = await getTargetWMP().isAlwaysOnBottom();
                BotToast.showText(text: 'isAlwaysOnBottom: $isAlwaysOnBottom');
              },
              value: _isAlwaysOnBottom,
              onChanged: (newValue) async {
                _isAlwaysOnBottom = newValue;
                await getTargetWMP().setAlwaysOnBottom(_isAlwaysOnBottom);
                setState(() {});
              },
            ),
            PreferenceListItem(
              title: const Text('getTitle / setTitle'),
              onTap: () async {
                String title = await getTargetWMP().getTitle();
                BotToast.showText(
                  text: title.toString(),
                );
                title =
                    'Window ID ${getTargetWMP().id} - ${DateTime.now().millisecondsSinceEpoch}';
                await getTargetWMP().setTitle(title);
              },
            ),
            PreferenceListItem(
              title: const Text('setTitleBarStyle'),
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('normal'),
                    onPressed: () async {
                      getTargetWMP().setTitleBarStyle(
                        TitleBarStyle.normal,
                        windowButtonVisibility: true,
                      );
                      setState(() {});
                    },
                  ),
                  CupertinoButton(
                    child: const Text('hidden'),
                    onPressed: () async {
                      getTargetWMP().setTitleBarStyle(
                        TitleBarStyle.hidden,
                        windowButtonVisibility: false,
                      );
                      setState(() {});
                    },
                  ),
                ],
              ),
              onTap: () {},
            ),
            PreferenceListItem(
              title: const Text('getTitleBarHeight'),
              onTap: () async {
                int titleBarHeight = await getTargetWMP().getTitleBarHeight();
                BotToast.showText(
                  text: 'titleBarHeight: $titleBarHeight',
                );
              },
            ),
            PreferenceListItem(
              title: const Text('isSkipTaskbar'),
              onTap: () async {
                bool isSkipping = await getTargetWMP().isSkipTaskbar();
                BotToast.showText(
                  text: 'isSkipTaskbar: $isSkipping',
                );
              },
            ),
            PreferenceListItem(
              title: const Text('setSkipTaskbar'),
              onTap: () async {
                setState(() {
                  _isSkipTaskbar = !_isSkipTaskbar;
                });
                await getTargetWMP().setSkipTaskbar(_isSkipTaskbar);
                await Future.delayed(const Duration(seconds: 3));
                getTargetWMP().show();
              },
            ),
            PreferenceListItem(
              title: const Text('setProgressBar'),
              onTap: () async {
                for (var i = 0; i <= 100; i++) {
                  setState(() {
                    _progress = i / 100;
                  });
                  print(_progress);
                  await getTargetWMP().setProgressBar(_progress);
                  await Future.delayed(const Duration(milliseconds: 100));
                }
                await Future.delayed(const Duration(milliseconds: 1000));
                await getTargetWMP().setProgressBar(-1);
              },
            ),
            PreferenceListItem(
              title: const Text('setIcon'),
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('Default'),
                    onPressed: () => _handleSetIcon(_kIconTypeDefault),
                  ),
                  CupertinoButton(
                    child: const Text('Original'),
                    onPressed: () => _handleSetIcon(_kIconTypeOriginal),
                  ),
                ],
              ),
              onTap: () => _handleSetIcon(_kIconTypeDefault),
            ),
            PreferenceListSwitchItem(
              title: const Text(
                'isVisibleOnAllWorkspaces / setVisibleOnAllWorkspaces',
              ),
              onTap: () async {
                bool isVisibleOnAllWorkspaces =
                    await getTargetWMP().isVisibleOnAllWorkspaces();
                BotToast.showText(
                  text: 'isVisibleOnAllWorkspaces: $isVisibleOnAllWorkspaces',
                );
              },
              value: _isVisibleOnAllWorkspaces,
              onChanged: (newValue) {
                _isVisibleOnAllWorkspaces = newValue;
                getTargetWMP().setVisibleOnAllWorkspaces(
                  _isVisibleOnAllWorkspaces,
                  visibleOnFullScreen: _isVisibleOnAllWorkspaces,
                );
                setState(() {});
              },
            ),
            PreferenceListItem(
              title: const Text('setBadgeLabel'),
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('null'),
                    onPressed: () async {
                      await getTargetWMP().setBadgeLabel();
                    },
                  ),
                  CupertinoButton(
                    child: const Text('99+'),
                    onPressed: () async {
                      await getTargetWMP().setBadgeLabel('99+');
                    },
                  ),
                ],
              ),
              onTap: () => _handleSetIcon(_kIconTypeDefault),
            ),
            PreferenceListSwitchItem(
              title: const Text('hasShadow / setHasShadow'),
              onTap: () async {
                bool hasShadow = await getTargetWMP().hasShadow();
                BotToast.showText(
                  text: 'hasShadow: $hasShadow',
                );
              },
              value: _hasShadow,
              onChanged: (newValue) {
                _hasShadow = newValue;
                getTargetWMP().setHasShadow(_hasShadow);
                setState(() {});
              },
            ),
            PreferenceListItem(
              title: const Text('getOpacity / setOpacity'),
              onTap: () async {
                double opacity = await getTargetWMP().getOpacity();
                BotToast.showText(
                  text: 'opacity: $opacity',
                );
              },
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('1'),
                    onPressed: () async {
                      _opacity = 1;
                      getTargetWMP().setOpacity(_opacity);
                      setState(() {});
                    },
                  ),
                  CupertinoButton(
                    child: const Text('0.8'),
                    onPressed: () async {
                      _opacity = 0.8;
                      getTargetWMP().setOpacity(_opacity);
                      setState(() {});
                    },
                  ),
                  CupertinoButton(
                    child: const Text('0.6'),
                    onPressed: () async {
                      _opacity = 0.5;
                      getTargetWMP().setOpacity(_opacity);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            PreferenceListSwitchItem(
              title: const Text('setIgnoreMouseEvents'),
              value: _isIgnoreMouseEvents,
              onChanged: (newValue) async {
                _isIgnoreMouseEvents = newValue;
                await getTargetWMP().setIgnoreMouseEvents(
                  _isIgnoreMouseEvents,
                  forward: false,
                );
                setState(() {});
              },
            ),
            PreferenceListItem(
              title: const Text('popUpWindowMenu'),
              onTap: () async {
                await getTargetWMP().popUpWindowMenu();
              },
            ),
            // PreferenceListItem(
            //   title: const Text('grabKeyboard'),
            //   onTap: () async {
            //     await getTargetWMP().grabKeyboard();
            //   },
            // ),
            // PreferenceListItem(
            //   title: const Text('ungrabKeyboard'),
            //   onTap: () async {
            //     await getTargetWMP().ungrabKeyboard();
            //   },
            // ),
          ],
        ),
      ],
    );
  }

  Widget _build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(0),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Scaffold(
            appBar: _isFullScreen
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(kWindowCaptionHeight),
                    child: WindowCaption(
                      brightness: Theme.of(context).brightness,
                      title: Text('Window ID ${WindowManagerPlus.current.id}'),
                    ),
                  ),
            body: Column(
              children: [
                Container(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: IntrinsicHeight(
                        child: Row(
                      children: [
                        SizedBox(
                          height: 30,
                          width: 200,
                          child: Container(),
                        ),
                        Padding(
                            padding: EdgeInsetsGeometry.symmetric(vertical: 2),
                            child: VerticalDivider(thickness: 1, color: gray2)),
                        Container(
                          height: 30,
                          width: 180,
                          alignment: Alignment.centerLeft,
                          child: Text('Target window:'),
                        ),
                        Padding(
                            padding: EdgeInsetsGeometry.symmetric(vertical: 2),
                            child: VerticalDivider(thickness: 1, color: gray2)),
                        Container(
                          height: 30,
                          width: 180,
                          alignment: Alignment.centerLeft,
                          child: Text('Listen to events with:'),
                        ),
                      ],
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      spacing: 5,
                    ))),
                Container(
                    height: 150,
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    margin: EdgeInsetsGeometry.only(right: 10, left: 10),
                    child: ListView(
                        key: ValueKey(windowManagerPlusInstances.length +
                            listeningTo.hashCode),
                        children: <Widget>[
                              ListenableInfoWidget.global(
                                  this, listeningTo == null, switchListenable)
                            ] +
                            List<Widget>.generate(
                                windowManagerPlusInstances.length * 2,
                                (int index) {
                              if (index % 2 == 0) {
                                return Padding(
                                    padding: EdgeInsetsGeometry.symmetric(
                                        horizontal: 2),
                                    child:
                                        Divider(thickness: 0.5, color: gray2));
                              } else {
                                return ListenableInfoWidget.fromWMP(
                                    windowManagerPlusInstances[index ~/ 2],
                                    this,
                                    windowManagerPlusInstances[index ~/ 2] ==
                                        currentTarget,
                                    switchTarget,
                                    windowManagerPlusInstances[index ~/ 2] ==
                                        listeningTo,
                                    switchListenable);
                              }
                            }))),
                Padding(
                  child: Row(children: [
                    Spacer(),
                    Padding(
                        child: Text('Add a WindowManagerPlus instance:'),
                        padding: EdgeInsets.fromLTRB(0, 0, 10, 0)),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: idFieldController,
                        decoration: InputDecoration(
                          labelText: 'Id',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(
                            color: gray2,
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    TextButton(
                        child: Text('Add'),
                        onPressed: () {
                          int? result = int.tryParse(idFieldController.text);
                          if (result != null) {
                            setState(() {
                              windowManagerPlusInstances
                                  .add(WindowManagerPlus.fromWindowId(result));
                              idFieldController.clear();
                            });
                          }
                        })
                  ]),
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 20),
                ),
                DragToMoveArea(
                  child: Container(
                    margin: const EdgeInsets.all(0),
                    width: double.infinity,
                    height: 54,
                    color: gray2.withOpacity(0.3),
                    child: const Center(
                      child: Text('DragToMoveArea'),
                    ),
                  ),
                  targetWindow: getTargetWMP(),
                ),
                if (Platform.isLinux || Platform.isWindows)
                  Container(
                    height: 100,
                    margin: const EdgeInsets.all(20),
                    child: DragToResizeArea(
                      resizeEdgeSize: 6,
                      resizeEdgeColor: Colors.red.withOpacity(0.2),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: gray2.withOpacity(0.3),
                        child: Center(
                          child: GestureDetector(
                            child: const Text('DragToResizeArea'),
                            onTap: () {
                              BotToast.showText(
                                text: 'DragToResizeArea example',
                              );
                            },
                          ),
                        ),
                      ),
                      targetWindow: getTargetWMP(),
                    ),
                  ),
                Expanded(
                  child: _buildBody(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (_isIgnoreMouseEvents) {
          getTargetWMP().setOpacity(1.0);
        }
      },
      onExit: (_) {
        if (_isIgnoreMouseEvents) {
          getTargetWMP().setOpacity(0.5);
        }
      },
      child: _build(context),
    );
  }

  @override
  void onTrayIconMouseDown() {
    WindowManagerPlus.current.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_window':
        await getTargetWMP().focus();
        break;
      case 'set_ignore_mouse_events':
        _isIgnoreMouseEvents = false;
        await getTargetWMP().setIgnoreMouseEvents(_isIgnoreMouseEvents);
        setState(() {});
        break;
    }
  }

  @override
  void onWindowFocus([int? windowId]) {
    if (windowId != null) {
      return;
    }
    setState(() {});
  }

  @override
  void onWindowClose([int? windowId]) {
    if (windowId != null) {
      return;
    }
    if (_isPreventClose) {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Are you sure you want to close this window?'),
            actions: [
              TextButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.of(context).pop();
                  WindowManagerPlus.current.destroy();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void onWindowEvent(String eventName, [int? windowId]) {
    print(
        '[${windowId != null ? "Global Event for Window $windowId from ${WindowManagerPlus.current}" : WindowManagerPlus.current}] onWindowEvent: $eventName');
  }

  @override
  Future<dynamic> onEventFromWindow(
      String eventName, int fromWindowId, dynamic arguments) async {
    BotToast.showText(
        text:
            '[${WindowManagerPlus.current}] Event $eventName from Window $fromWindowId with arguments $arguments');
    return 'Hello from ${WindowManagerPlus.current}';
  }
}
