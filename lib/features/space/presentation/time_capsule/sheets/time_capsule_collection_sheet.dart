import 'package:flutter/material.dart';

import '../models/time_capsule_item.dart';
import '../utils/time_capsule_date.dart';

enum TimeCapsuleCollectionActionType { create, select }

class TimeCapsuleCollectionResult {
  const TimeCapsuleCollectionResult._({required this.type, this.capsule});

  const TimeCapsuleCollectionResult.create()
    : this._(type: TimeCapsuleCollectionActionType.create);

  const TimeCapsuleCollectionResult.select(TimeCapsuleItem capsule)
    : this._(type: TimeCapsuleCollectionActionType.select, capsule: capsule);

  final TimeCapsuleCollectionActionType type;
  final TimeCapsuleItem? capsule;
}

Future<TimeCapsuleCollectionResult?> showTimeCapsuleCollectionSheet({
  required BuildContext context,
  required List<TimeCapsuleItem> capsules,
}) {
  return showModalBottomSheet<TimeCapsuleCollectionResult>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFCF6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7D0C3),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 16, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '树下的时间胶囊',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3F4436),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '有些回忆，需要等到未来才能打开。',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF918A7D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              if (capsules.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 46,
                          color: Color(0xFFB3AD9F),
                        ),
                        SizedBox(height: 14),
                        Text(
                          '树下还什么都没有',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6F695E),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '埋下第一个时间胶囊吧',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9A9489),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: capsules.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final capsule = capsules[index];
                      final unlocked = capsule.isUnlocked();

                      return Material(
                        color: const Color(0xFFF6F1E8),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.of(
                              sheetContext,
                            ).pop(TimeCapsuleCollectionResult.select(capsule));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: unlocked
                                        ? const Color(0xFFE4ECD9)
                                        : const Color(0xFFEAE5DD),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    unlocked
                                        ? Icons.drafts_outlined
                                        : Icons.lock_outline,
                                    color: unlocked
                                        ? const Color(0xFF657B54)
                                        : const Color(0xFF8E887F),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        capsule.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4C4A43),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        unlocked
                                            ? '已经可以打开'
                                            : '${formatTimeCapsuleDate(capsule.unlockDate)} 开启',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: unlocked
                                              ? const Color(0xFF71835E)
                                              : const Color(0xFF948E84),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  unlocked
                                      ? Icons.chevron_right
                                      : Icons.lock_clock_outlined,
                                  color: const Color(0xFFAAA397),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(
                        sheetContext,
                      ).pop(const TimeCapsuleCollectionResult.create());
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF71835E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('埋下新的时间胶囊'),
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
