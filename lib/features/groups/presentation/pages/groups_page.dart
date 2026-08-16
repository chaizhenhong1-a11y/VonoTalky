import 'package:flutter/material.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.topRight,
        colors: [Color(0xFFF8DCEB), Color(0xFFEBDDF5), Color(0xFFDCCFF3)],
      ),
    ),
    child: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Groups',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5F3792),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF9F7FC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    size: 58,
                    color: Color(0xFF805BB3),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Group tools are coming next',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Your group conversations are now on Chats',
                    style: TextStyle(fontSize: 12, color: Color(0xFF756E7C)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
