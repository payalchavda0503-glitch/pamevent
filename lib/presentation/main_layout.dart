import 'package:flutter/material.dart';
import '../helpers/app_colors.dart';
import 'home.screen.dart';
import 'profile/profile.screen.dart';
import 'search/search_results.screen.dart';
import 'shared/widgets/app_drawer.widget.dart';
import 'tickets/my_tickets_list.screen.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HomeScreen(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onSearchTap: () => _onItemTapped(1),
      ),
      SearchResultsScreen(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
      MyTicketsListScreen(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
      ProfileScreen(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(onTabSelected: _onItemTapped),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.black,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            activeIcon: Icon(Icons.confirmation_number),
            label: 'My tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
