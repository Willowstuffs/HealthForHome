import 'package:flutter/material.dart';
import '../../screens/login_register_screen.dart';
import '../../screens/request_form_screen.dart';
import '../../screens/account_screen.dart';
import '../../services/api_service.dart';
import '../../widgets/category_chip.dart';
import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              ApiService().isLoggedIn
                  ? Icons.account_circle
                  : Icons.person_outline,
              color: AppColors.onBackground,
            ),
            onPressed: () async {
              if (ApiService().isLoggedIn) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                );
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginRegisterScreen(),
                  ),
                );
              }
              setState(
                () {},
              ); // Refresh state after returning (e.g. login/logout)
            },
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sekcja powitalna
              _buildWelcomeSection(),

              SizedBox(height: 24),
              // Kategorie
              _buildCategoriesSection(),

              // SizedBox(height: 24),

              // // Lista specjalistów
              // _buildSpecialistsSection(),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Widget _buildWelcomeSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Znajdź specjalistę',
  //         style: Theme.of(context).textTheme.headlineLarge,
  //       ),
  //       SizedBox(height: 8),
  //       Text(
  //         'Certyfikowani specjaliści z dojazdem do Ciebie',
  //         style: Theme.of(
  //           context,
  //         ).textTheme.bodyLarge?.copyWith(color: AppColors.secondary),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // LOGO
          Image.asset('lib/images/logo.png', width: 150, height: 150),
          SizedBox(height: 16),
          Text(
            'Health for Home',
            style: Theme.of(context).textTheme.headlineLarge!.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = MockData.getCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Wybierz kategorię',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        // Lista kategorii
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final category = categories[index];

            return CategoryChip(
              title: category.title,
              icon: category.icon,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RequestFormScreen(categoryName: category.title),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Widget _buildSpecialistsSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             'Polecani specjaliści',
  //             style: Theme.of(context).textTheme.headlineMedium,
  //           ),
  //           TextButton(
  //             onPressed: () {},
  //             child: Text(
  //               'Zobacz wszystkich',
  //               style: TextStyle(
  //                 color: AppColors.primary,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       SizedBox(height: 16),
  //       ListView.builder(
  //         shrinkWrap: true,
  //         physics: NeverScrollableScrollPhysics(),
  //         itemCount: MockData.getSpecialists().length,
  //         itemBuilder: (context, index) {
  //           return Padding(
  //             padding: const EdgeInsets.only(bottom: 16.0),
  //             child: SpecialistCard(
  //               specialist: MockData.getSpecialists()[index],
  //               onTap: () {
  //                 // Navigate to specialist details
  //               },
  //             ),
  //           );
  //         },
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildBottomNavigationBar() {
  //   return BottomNavigationBar(
  //     currentIndex: 0,
  //     type: BottomNavigationBarType.fixed,
  //     selectedLabelStyle: TextStyle(fontSize: 12),
  //     unselectedLabelStyle: TextStyle(fontSize: 12),
  //     items: [
  //       BottomNavigationBarItem(
  //         icon: Icon(Icons.home),
  //         activeIcon: Icon(Icons.home_filled),
  //         label: 'Główna',
  //       ),
  //       BottomNavigationBarItem(
  //         icon: Icon(Icons.calendar_today),
  //         activeIcon: Icon(Icons.calendar_today),
  //         label: 'Wizyty',
  //       ),
  //       BottomNavigationBarItem(
  //         icon: Icon(Icons.map_outlined),
  //         activeIcon: Icon(Icons.map),
  //         label: 'Mapa',
  //       ),
  //       BottomNavigationBarItem(
  //         icon: Icon(Icons.favorite_outline),
  //         activeIcon: Icon(Icons.favorite),
  //         label: 'Ulubione',
  //       ),
  //       BottomNavigationBarItem(
  //         icon: Icon(Icons.person_outline),
  //         activeIcon: Icon(Icons.person),
  //         label: 'Profil',
  //       ),
  //     ],
  //     onTap: (index) {
  //       // Handle navigation
  //     },
  //   );
  // }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
