import 'dart:html';

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
}) {
  final theme = Theme.of(context);

  final controller = TextEditingController();

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
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
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
          )),
          const SizedBox(width: 8),
          IconButton(
            padding: const EdgeInsets.all(0),
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
            icon: const Icon(
              Icons.arrow_upward,
            ),
            color: theme.colorScheme.primary,
            onPressed: onSubmitted,
          ),
        ],
      ),
    ),
  );
}

@swidget
Widget __placeholder(
  BuildContext context,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                "Input text below or drop file here to send",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
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
    final scrollController = ScrollController();

    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });

    return Column(children: [
      Expanded(
        child: renderContent(scrollController, theme),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: 16),
          _QuickAction(
            title: "Copy clipboard",
          ),
          _QuickAction(
            title: "Send picture",
            onTap: () => _openImageFile(context),
          ),
        ],
      ),
      _Input(
        isEnterToSend: true,
        onSubmit: (msg) {
          onMessage(context, msg, scrollController);
        },
      ),
    ]);
  }

  Future<void> _openImageFile(BuildContext context) async {
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

  onMessage(context, msg, scrollController) {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    final deviceSendManager =
        Provider.of<DeviceSendManager>(context, listen: false);

    final pairedState = deviceSendManager.currentStateAs<PairedState>();

    pairedState.sendText(msg);
  }

  renderContent(scrollController, theme) {
    return AnimatedBuilder(
        animation: widget.pairedState,
        builder: (context, child) {
          final messages = widget.pairedState.messages;

          if (messages.isEmpty) {
            return const _Placeholder();
          }

          final noteItems = renderMessages(messages, theme);

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

  renderMessages(messages, theme) {
    return messages.map((message) {
      switch (message.type) {
        case MessageType.Text:
          {
            return MessageContainer(
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
                    color: Colors.black45,
                    onPressed: () => copyToClipboardAutoClear(message.text!),
                  ),
                ],
              ),
            );
          }
          break;
        case MessageType.Image:
          {
            return MessageContainer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.memory(
                        message.image!,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.download,
                    ),
                    color: Colors.black45,
                    onPressed: () => downloadBlobFile(
                      message.fileName!,
                      message.image!,
                    ),
                  ),
                ],
              ),
            );
          }
          break;
      }
    }).toList();
  }
}

@swidget
Widget messageContainer(
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
    width: double.infinity,
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
  Function()? onTap,
}) {
  final theme = Theme.of(context);

  return Material(
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 19,
            ),
          ),
        ),
      ),
      onTap: onTap,
    ),
  );
}
