import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vonotalky/features/space/presentation/pages/time_capsule.dart';
import 'package:vonotalky/features/space/presentation/widgets/shared_space_background.dart';
import 'package:vonotalky/features/pet/presentation/pages/pet_home_page.dart';

class Space extends StatefulWidget {
  const Space({super.key});

  @override
  State<Space> createState() => _SpaceState();
}

class _SpaceState extends State<Space>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // =========================
          // 三个 Tab 共用的超长背景
          // =========================
          Positioned.fill(
            child: SharedSpaceBackground(
              pageAnimation: _tabController.animation!,
            ),
          ),

          // =========================
          // 三个页面
          // =========================
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 116,
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TransparentTabPage(
                    child: const PetHomePage(),
                  ),

                  const TimeCapsule(),

                  const _TransparentTabPage(
                    child: Center(
                      child: Text('宠物'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =========================
          // 顶部标题 + 漂浮 TabBar
          // =========================
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(
                  height: 6,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 22,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '空间',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                  ),
                  child: _SpaceTabBar(
                    controller: _tabController,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceTabBar extends StatelessWidget {
  const _SpaceTabBar({
    required this.controller,
  });

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isDark =
        theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        24,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(
            6,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0x66211C28)
                : const Color(0xB8FFFFFF),
            borderRadius: BorderRadius.circular(
              24,
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(
                      alpha: 0.08,
                    )
                  : Colors.white.withValues(
                      alpha: 0.82,
                    ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark
                      ? 0.20
                      : 0.07,
                ),
                blurRadius: 22,
                offset: const Offset(
                  0,
                  8,
                ),
              ),
            ],
          ),
          child: TabBar(
            controller: controller,

            dividerColor: Colors.transparent,

            splashBorderRadius:
                BorderRadius.circular(
              18,
            ),

            overlayColor:
                WidgetStateProperty.all(
              Colors.transparent,
            ),

            indicatorSize:
                TabBarIndicatorSize.tab,

            indicator: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary.withValues(
                    alpha: isDark
                        ? 0.90
                        : 0.82,
                  ),
                  colors.secondary.withValues(
                    alpha: isDark
                        ? 0.78
                        : 0.68,
                  ),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary
                      .withValues(
                    alpha: 0.24,
                  ),
                  blurRadius: 12,
                  offset: const Offset(
                    0,
                    4,
                  ),
                ),
              ],
            ),

            labelColor: Colors.white,

            unselectedLabelColor:
                isDark
                    ? Colors.white.withValues(
                        alpha: 0.68,
                      )
                    : const Color(
                        0xFF5D6258,
                      ),

            tabs: const [
              _SpaceTab(
                icon: Icons.home_rounded,
              ),

              _SpaceTab(
                icon: Icons.hourglass_bottom_rounded,
              ),

              _SpaceTab(
                icon: Icons.pets_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpaceTab extends StatelessWidget {
  const _SpaceTab({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 52,
      child: Icon(
        icon,
        size: 23,
      ),
    );
  }
}

class _TransparentTabPage
    extends StatelessWidget {
  const _TransparentTabPage({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor:
            Colors.transparent,
        canvasColor: Colors.transparent,
      ),
      child: child,
    );
  }
}