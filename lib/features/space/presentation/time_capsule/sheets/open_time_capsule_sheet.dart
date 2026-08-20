import 'package:flutter/material.dart';

import '../models/time_capsule_item.dart';
import '../utils/time_capsule_date.dart';

Future<void> showOpenTimeCapsuleSheet({
  required BuildContext context,
  required TimeCapsuleItem capsule,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
        ),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFCF6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7D0C3),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Icon(Icons.drafts_outlined, color: Color(0xFF71835E)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      capsule.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3F4436),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text(
                    '埋于 ${formatTimeCapsuleDate(capsule.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999287),
                    ),
                  ),
                  Text(
                    '开启于 ${formatTimeCapsuleDate(capsule.unlockDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF71835E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EBDD),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      capsule.content,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: Color(0xFF514C43),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
