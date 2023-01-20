import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:file_selector/file_selector.dart';

import '../models/device_send_manager.dart';
import '../util.dart';

part 'send.g.dart';

@swidget
Widget __input(
  BuildContext context, {
  ValueChanged<String>? onSubmit,
  bool isEnterToSend = false,
  required TextEditingController controller,
  double elevation = 0,
}) {
  final theme = Theme.of(context);

  onSubmitted() {
    final content = controller.text;

    if (content == "") {
      return;
    }

    controller.clear();

    onSubmit?.call(content);
  }

  final keyBoardAction =
      isEnterToSend ? TextInputAction.done : TextInputAction.newline;

  final textFieldOnSubmitted = isEnterToSend ? (_) => onSubmitted() : null;

  return Material(
    type: MaterialType.card,
    elevation: elevation,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: TextField(
                  keyboardType: TextInputType.multiline,
                  textInputAction: keyBoardAction,
                  maxLines: 5,
                  minLines: 1,
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Press Ctrl+Enter to insert new lines",
                    border: InputBorder.none,
                    isDense: false,
                  ),
                  onSubmitted: textFieldOnSubmitted,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 50,
          height: 50,
          child: IconButton(
            padding: const EdgeInsets.all(0),
            icon: const Icon(
              Icons.arrow_upward,
            ),
            color: theme.colorScheme.primary,
            onPressed: onSubmitted,
          ),
        ),
      ],
    ),
  );
}

@swidget
Widget __placeholder(
  BuildContext context,
) {
  final theme = Theme.of(context);

  final placeholderBody = Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Input text below",
          style: TextStyle(
            color: theme.colorScheme.onBackground,
            fontSize: 20,
          ),
        ),
        Text(
          "or drop file here to send",
          style: TextStyle(
            color: theme.colorScheme.onBackground,
            fontSize: 20,
          ),
        ),
      ],
    ),
  );

  if (isMobile()) {
    return placeholderBody;
  } else {
    return Container(
      padding: const EdgeInsets.only(
        top: 32,
        left: 32,
        right: 32,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          color: Colors.grey[100]!.withOpacity(0.7),
        ),
        child: placeholderBody,
      ),
    );
  }
}

class SendDialog extends StatefulHookWidget {
  const SendDialog({
    Key? key,
    required this.pairedState,
  }) : super(key: key);

  final PairedState pairedState;

  @override
  _SendDialogState createState() => _SendDialogState();
}

class _SendDialogState extends State<SendDialog> {
  @override
  Widget build(BuildContext context) {
    if (isMobile()) {
      return buildMobile(context);
    } else {
      return buildDesktop(context);
    }
  }

  buildQuickActions(inputController) {
    final clipboardText = isMobile() ? "Clibboard" : "Copy clipboard";
    final pictureText = isMobile() ? "Picture" : "Send picture";
    final fileText = isMobile() ? "File" : "Send file";

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _QuickAction(
          title: clipboardText,
          icon: Icons.content_paste,
          onTap: () => _onCopyClipboard(inputController),
        ),
        _QuickAction(
          title: pictureText,
          icon: Icons.image_outlined,
          onTap: () => _sendImage(context),
        ),
        _QuickAction(
          title: fileText,
          icon: Icons.description_outlined,
          onTap: () => _sendFile(context),
        ),
      ],
    );
  }

  buildMobile(context) {
    final theme = Theme.of(context);

    final inputController = TextEditingController();

    return Column(children: [
      Expanded(
        child: renderContent(theme),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: buildQuickActions(inputController),
      ),
      const SizedBox(height: 10),
      Divider(
        thickness: 1,
        height: 1,
        color: Colors.grey[300]!,
      ),
      Padding(
        padding: const EdgeInsets.only(
          left: 8,
          right: 4,
        ),
        child: _Input(
          isEnterToSend: true,
          controller: inputController,
          onSubmit: (msg) {
            onMessage(context, msg);
          },
        ),
      ),
    ]);
  }

  buildDesktop(context) {
    final theme = Theme.of(context);

    final inputController = TextEditingController();

    return Column(children: [
      Expanded(
        child: renderContent(theme),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: buildQuickActions(inputController),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.only(
          left: 8,
          right: 16,
        ),
        child: Divider(
          thickness: 1,
          height: 1,
          color: Colors.grey[300]!,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(
          left: 8,
          right: 4,
        ),
        child: _Input(
          isEnterToSend: true,
          controller: inputController,
          onSubmit: (msg) {
            onMessage(context, msg);
          },
        ),
      ),
    ]);
  }

  Future<void> _onCopyClipboard(inputController) async {
    final content = await copyFromClipboard();

    if (content != null && content.trim() != "") {
      inputController.text = content.trim();
    }
  }

  Future<void> _sendImage(BuildContext context) async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      mimeTypes: [
        "image/*",
        "image/avif",
        "image/gif",
        "image/jpeg",
        "image/png",
        "image/svg+xml",
        "image/webp",
        "image/apng",
      ],
    );
    final XFile? file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[typeGroup],
    );

    if (file == null) {
      // Operation was canceled by the user.
      return;
    }
    final String fileName = file.name;
    final String filePath = file.path;

    final data = await file.readAsBytes();

    final deviceSendManager =
        Provider.of<DeviceSendManager>(context, listen: false);

    final pairedState = deviceSendManager.currentStateAs<PairedState>();

    pairedState.sendImage(file.name, data);
  }

  Future<void> _sendFile(BuildContext context) async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'files',
    );
    final XFile? file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[typeGroup],
    );

    if (file == null) {
      // Operation was canceled by the user.
      return;
    }
    final String fileName = file.name;
    final String filePath = file.path;

    final data = await file.readAsBytes();

    final deviceSendManager =
        Provider.of<DeviceSendManager>(context, listen: false);

    final pairedState = deviceSendManager.currentStateAs<PairedState>();

    pairedState.sendFile(file.name, data);
  }

  onMessage(context, msg) {
    final deviceSendManager =
        Provider.of<DeviceSendManager>(context, listen: false);

    final pairedState = deviceSendManager.currentStateAs<PairedState>();

    pairedState.sendText(msg);
  }

  renderContent(theme) {
    return AnimatedBuilder(
        animation: widget.pairedState,
        builder: (context, child) {
          final messages = widget.pairedState.messages;

          if (messages.isEmpty) {
            return const _Placeholder();
          }

          final noteItems = renderMessages(messages, theme);

          final scrollController = ScrollController();
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await Future.delayed(const Duration(milliseconds: 100));

            if (scrollController.hasClients) {
              scrollController
                  .jumpTo(scrollController.position.maxScrollExtent);
            }
          });

          return ListView.builder(
            padding: const EdgeInsets.only(
              left: 32,
              right: 32,
              top: 16,
            ),
            itemCount: noteItems.length,
            itemBuilder: (context, index) {
              return noteItems[index];
            },
            controller: scrollController,
          );
        });
  }

  renderText(message, ThemeData theme) {
    return _MessageContainer(
      backgroundColor: theme.colorScheme.secondary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(message.text!),
          ),
          IconButton(
            icon: const Icon(
              Icons.copy,
            ),
            color: theme.colorScheme.primary,
            onPressed: () => copyToClipboardAutoClear(message.text!),
          ),
        ],
      ),
    );
  }

  renderImage(message, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: _MessageContainer(
        backgroundColor: theme.colorScheme.secondary,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 300,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.memory(
                    message.content!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(
                Icons.download,
              ),
              color: theme.colorScheme.primary,
              onPressed: () => downloadBlobFile(
                message.fileName!,
                message.content!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  renderFile(message, ThemeData theme) {
    return _MessageContainer(
      backgroundColor: theme.colorScheme.secondary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 30,
            child: Icon(
              Icons.description_outlined,
              color: theme.colorScheme.tertiary,
              size: 32,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message.fileName!),
          ),
          IconButton(
            icon: const Icon(
              Icons.download,
            ),
            color: theme.colorScheme.primary,
            onPressed: () => downloadBlobFile(
              message.fileName!,
              message.content!,
            ),
          ),
        ],
      ),
    );
  }

  renderMessages(messages, theme) {
    return messages.map((message) {
      switch (message.type) {
        case MessageType.Text:
          return renderText(message, theme);
          break;
        case MessageType.Image:
          return renderImage(message, theme);
          break;
        case MessageType.File:
          return renderFile(message, theme);
          break;
      }
    }).toList();
  }
}

@swidget
Widget __messageContainer(
  BuildContext context, {
  required Widget child,
  Color? backgroundColor,
  GestureLongPressCallback? onLongPress,
  GestureTapCallback? onTap,
}) {
  backgroundColor = backgroundColor ?? Colors.grey[100];

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
    ),
    child: Material(
      color: backgroundColor,
      type: MaterialType.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: child,
        ),
      ),
    ),
  );
}

@swidget
Widget __quickAction(
  BuildContext context, {
  required String title,
  required IconData icon,
  Function()? onTap,
}) {
  final theme = Theme.of(context);

  return Material(
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 28,
              width: 18,
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
