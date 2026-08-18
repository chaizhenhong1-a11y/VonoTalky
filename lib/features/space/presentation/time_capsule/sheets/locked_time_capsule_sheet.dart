import 'package:flutter/material.dart';

import '../models/time_capsule_item.dart';
import '../utils/time_capsule_date.dart';

Future<void> showLockedTimeCapsuleSheet({
  required BuildContext context,
  required TimeCapsuleItem capsule,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFCF6),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAE5DD),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.lock_clock_outlined,
                  size: 30,
                  color: Color(0xFF777168),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                capsule.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF45423C),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '这个时间胶囊还没有到开启的时候。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF918A7D)),
              ),
              const SizedBox(height: 16),
              Text(
                '${formatTimeCapsuleDate(capsule.unlockDate)} 才能打开',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF71835E),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF71835E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('知道了'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
