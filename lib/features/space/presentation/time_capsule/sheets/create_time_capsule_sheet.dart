import 'package:flutter/material.dart';

import '../models/time_capsule_draft.dart';
import '../utils/time_capsule_date.dart';

Future<TimeCapsuleDraft?> showCreateTimeCapsuleSheet({
  required BuildContext context,
}) {
  String title = '';
  String content = '';
  DateTime? unlockDate;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  return showModalBottomSheet<TimeCapsuleDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.90,
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFCF6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
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
                    const Text(
                      '新的时间胶囊',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3F4436),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '埋下以后，在指定日期以前无法打开。',
                      style: TextStyle(fontSize: 13, color: Color(0xFF918A7D)),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '标题',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      maxLength: 40,
                      onChanged: (value) {
                        title = value;
                      },
                      decoration: _fieldDecoration('给未来的我们'),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '内容',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      minLines: 5,
                      maxLines: 8,
                      maxLength: 2000,
                      onChanged: (value) {
                        content = value;
                      },
                      decoration: _fieldDecoration('写下想留给未来的话……'),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '开启日期',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: const Color(0xFFF5F0E7),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: sheetContext,
                            initialDate: unlockDate ?? tomorrow,
                            firstDate: tomorrow,
                            lastDate: DateTime(today.year + 20, 12, 31),
                          );

                          if (picked == null) {
                            return;
                          }

                          setSheetState(() {
                            unlockDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            );
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 17,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                color: Color(0xFF71835E),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  unlockDate == null
                                      ? '选择未来的某一天'
                                      : formatTimeCapsuleDate(unlockDate!),
                                  style: TextStyle(
                                    color: unlockDate == null
                                        ? const Color(0xFFAAA397)
                                        : const Color(0xFF4F4B44),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFFAAA397),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          final finalTitle = title.trim();
                          final finalContent = content.trim();

                          if (finalTitle.isEmpty ||
                              finalContent.isEmpty ||
                              unlockDate == null) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(content: Text('标题、内容和开启日期都要填写')),
                            );
                            return;
                          }

                          Navigator.of(sheetContext).pop(
                            TimeCapsuleDraft(
                              title: finalTitle,
                              content: finalContent,
                              unlockDate: unlockDate!,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF71835E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('埋下时间胶囊'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

InputDecoration _fieldDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: const Color(0xFFF5F0E7),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFF7E9067), width: 1.4),
    ),
  );
}
