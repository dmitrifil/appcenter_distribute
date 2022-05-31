
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.onMiddle,
    this.subTitle = '',
    this.mandatoryUpdate = false,
    this.confirmButtonText = '',
    this.middleButtonText = '',
    this.cancelButtonText = '',
    this.onCancel,
  }): super(key: key);

  final bool mandatoryUpdate;
  final String title;
  final String subTitle;
  final String content;
  final String confirmButtonText;
  final String middleButtonText;
  final String cancelButtonText;
  final void Function() onConfirm;
  final void Function()? onMiddle;
  final void Function()? onCancel;

  @override
  Widget build(BuildContext context) {

    return CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: <Widget>[
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                subTitle,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            Text(
              content,
              textAlign: TextAlign.left,
              style: const TextStyle(
                height: 1.5
              ),
            )
          ]
        )
      ),
      actions: [
        Visibility(
          visible: !mandatoryUpdate,
          child: TextButton(
            child: Text(
              cancelButtonText,
              style: TextStyle(
                color: Colors.grey[600]
              ),
            ),
            onPressed: onCancel ?? () => Navigator.pop(context)
          )
        ),
        Visibility(
          visible: middleButtonText.isNotEmpty,
          child: TextButton(
            child: Text(
              middleButtonText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue
              ),
            ),
            onPressed: (){
              Navigator.pop(context);
              if(onMiddle != null) onMiddle!();
            }
          ),
         ),
        TextButton(
          child: Text(
            confirmButtonText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue
            ),
          ),
          onPressed: (){
            Navigator.pop(context);
            onConfirm();
          }
        ),
      ],
    );
  }
}