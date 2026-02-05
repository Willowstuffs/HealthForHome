import 'package:flutter/material.dart';
import '../../screens/login_register_screen.dart';
import '../../screens/request_form_screen.dart';
import '../../screens/account_screen.dart';
import '../../services/api_service.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/specialist_card.dart';
import '../../widgets/appointment_card.dart';
import '../../data/mock_data.dart';
import '../../models/client_profile.dart'; // Import ClientProfile
import '../../theme/app_theme.dart';
import '../../screens/map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  ClientProfile? _clientProfile;
  bool _isLoadingProfile = false;
  @override
  void initState() {
    super.initState();
    _checkLoginAndLoadProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkLoginAndLoadProfile() async {
    if (ApiService().isLoggedIn) {
      setState(() => _isLoadingProfile = true);
      try {
        final profile = await ApiService().getClientProfile();
        if (mounted) {
          setState(() {
            _clientProfile = profile;
            _isLoadingProfile = false;
          });
        }
      } catch (e) {
        // Handle error silently or show snackbar
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ApiService().isLoggedIn;

    // Guest View
    if (!isLoggedIn) {
      return _buildGuestScaffold();
    }

    // Logged In View
    return _buildLoggedInScaffold();
  }

  Widget _buildGuestScaffold() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_outline,
              color: AppColors.onBackground,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginRegisterScreen()),
              );
              _checkLoginAndLoadProfile(); // Refresh on return
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
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildCategoriesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInScaffold() {
    // If we are on Home tab (index 0), show dashboard
    // Otherwise show placeholder
    Widget bodyContent;
    switch (_currentIndex) {
      case 0:
        bodyContent = _buildDashboard();
        break;
      case 1:
        bodyContent = const Center(
          child: Text("Szukaj specjalistów (Wkrótce)"),
        );
        break;
      case 2:
        bodyContent = const MapScreen();
        break;
      case 3:
        bodyContent = const Center(child: Text("Kalendarz (Wkrótce)"));
        break;
      default:
        bodyContent = _buildDashboard();
    }

    return Scaffold(
      backgroundColor: AppColors.background, // Match theme background
      appBar: _currentIndex == 0
          ? null // No AppBar on Home tab (custom greeting inside body or custom SliverAppBar could be used, but standard design typically mimics SafeArea)
          : AppBar(
              title: const Text('HealthForHome'),
              backgroundColor: AppColors.background,
              elevation: 0,
            ),
      body: SafeArea(child: bodyContent),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        // selectedItemColor and unselectedItemColor are now handled by the theme
        showUnselectedLabels: true,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Start'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Szukaj'),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Kalendarz',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Greeting
          _buildUserInfoHeader(),
          const SizedBox(height: 24),

          // Specialists Section
          _buildSpecialistsList(),
          const SizedBox(height: 24),

          // Appointments Section
          _buildAppointmentsList(),
        ],
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Witaj,',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isLoadingProfile
                  ? 'Ładowanie...'
                  : (_clientProfile?.firstName ?? 'Użytkowniku'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            );
            _checkLoginAndLoadProfile();
          },
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(Icons.person, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialistsList() {
    final specialists = MockData.getSpecialists();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proponowani specjaliści',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: specialists.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final specialist = specialists[index];
            return SpecialistCard(
              specialist: specialist,
              onTap: () {
                // Navigate to details
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppointmentsList() {
    return FutureBuilder<List<dynamic>>(
      future: ApiService().getAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final appointments = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nadchodzące wizyty',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (appointments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Brak nadchodzących wizyt'),
              ),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return AppointmentCard(
                  appointment: appointments[index],
                  onTap: () {
                    // TODO: nawigacja do szczegółów wizyty
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // LOGO
          Image.asset('lib/images/logo.png', width: 150, height: 150),
          const SizedBox(height: 16),
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
        const SizedBox(height: 12),
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
}
