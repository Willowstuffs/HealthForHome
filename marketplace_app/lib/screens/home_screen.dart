import 'package:flutter/material.dart';
import '../../screens/login_register_screen.dart';
import '../../screens/request_form_screen.dart';
import '../../screens/account_screen.dart';
import '../../services/api_service.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/appointment_card.dart';
import '../../data/mock_data.dart';
import '../../models/client_profile.dart';
import '../../models/appointment.dart';
import '../../theme/app_theme.dart';
import '../../screens/map_screen.dart';
import '../../screens/calendar_screen.dart';

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

    // Guest
    if (!isLoggedIn) {
      return _buildGuestScaffold();
    }

    // Logged In
    return _buildLoggedInScaffold();
  }

  Widget _buildGuestScaffold() {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HealthForHome',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Twoje zdrowie w domu',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginRegisterScreen(),
                            ),
                          );
                          _checkLoginAndLoadProfile();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildWelcomeSection(),
                const SizedBox(height: 32),
                _buildCategoriesSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInScaffold() {
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
        bodyContent = const CalendarScreen();
        break;
      default:
        bodyContent = _buildDashboard();
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(child: bodyContent),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          showUnselectedLabels: true,
          onTap: _onBottomNavTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Start',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'Szukaj',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded),
              label: 'Kalendarz',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const RequestFormScreen(categoryName: 'Fizjoterapia'),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              label: const Text(
                "Nowe ogłoszenie",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfoHeader(),
          const SizedBox(height: 32),

          _buildServiceRequestsList(),
          const SizedBox(height: 24),

          _buildAppointmentsList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceContainerHighest,
            AppColors.surfaceContainerHighest.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Witaj z powrotem!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoadingProfile
                      ? 'Ładowanie...'
                      : (_clientProfile?.firstName ?? 'Użytkowniku'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jak możemy Ci dzisiaj pomóc?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountScreen()),
              );
              _checkLoginAndLoadProfile();
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRequestsList() {
    return FutureBuilder<List<ServiceRequest>>(
      future: ApiService().getMyServiceRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                strokeWidth: 3,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.list_alt_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Moje ogłoszenia',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Błąd podczas ładowania ogłoszeń: ${snapshot.error}',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        var requests = snapshot.data ?? [];
        requests = requests.where((r) => r.status == 'open').toList();
        requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (requests.length > 3) {
          requests = requests.sublist(0, 3);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.list_alt_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Twoje ogłoszenia',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (requests.isEmpty)
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Brak aktywnych ogłoszeń.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = requests[index];
                return Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.assignment_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.serviceTypeName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    req.status == 'open'
                                        ? 'Otwarte'
                                        : req.status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.date_range_rounded,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${req.dateFrom.day.toString().padLeft(2, '0')}.${req.dateFrom.month.toString().padLeft(2, '0')} - ${req.dateTo.day.toString().padLeft(2, '0')}.${req.dateTo.month.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentsList() {
    return FutureBuilder<List<Appointment>>(
      future: ApiService().getAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                strokeWidth: 3,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Moje wizyty',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Błąd podczas ładowania wizyt: ${snapshot.error}',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        var appointments = snapshot.data ?? [];
        appointments = appointments
            .where((a) => a.appointmentStatus == 'confirmed')
            .toList();
        appointments.sort(
          (a, b) => a.scheduledStart.compareTo(b.scheduledStart),
        );
        if (appointments.length > 3) {
          appointments = appointments.sublist(0, 3);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Nadchodzące wizyty',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (appointments.isEmpty)
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Brak nadchodzących wizyt',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.accent.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Image.asset('lib/images/logo.png', width: 80, height: 80),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Health for Home',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Profesjonalna opieka zdrowotna\nw zaciszu Twojego domu',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.accent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medical_services_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Wybierz kategorię',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Znajdź specjalistę odpowiedniego dla Twoich potrzeb',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
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
