import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/nearby_specialist.dart';
import '../../models/specialist_profile_details.dart';
import '../../models/specialist_offer.dart';
import '../../theme/app_theme.dart';

class SearchSpecialistsScreen extends StatefulWidget {
  const SearchSpecialistsScreen({super.key});

  @override
  State<SearchSpecialistsScreen> createState() =>
      _SearchSpecialistsScreenState();
}

class _SearchSpecialistsScreenState extends State<SearchSpecialistsScreen> {
  final TextEditingController _addressController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<NearbySpecialist> _specialists = [];
  bool _isLoading = false;
  String? _error;

  DateTime? _lastRequestTime;
  final Duration _cooldown = const Duration(seconds: 5);

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _searchByAddress() {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;
    _performSearch(
      () => _apiService.getNearbySpecialistsByAddressText(address),
    );
  }

  void _searchByMyAddress() {
    _addressController.clear();
    _performSearch(() => _apiService.getNearbySpecialistsMyAddress());
  }

  Future<void> _performSearch(
    Future<List<NearbySpecialist>> Function() fetchOp,
  ) async {
    final now = DateTime.now();
    if (_lastRequestTime != null &&
        now.difference(_lastRequestTime!) < _cooldown) {
      final remaining =
          _cooldown.inSeconds - now.difference(_lastRequestTime!).inSeconds;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zbyt wiele zapytań. Poczekaj $remaining sekund.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await fetchOp();
      setState(() {
        _specialists = result;
        _lastRequestTime = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _lastRequestTime = DateTime.now();
        _isLoading = false;
      });
    }
  }

  void _showSpecialistDetails(NearbySpecialist specialist) {
    showDialog(
      context: context,
      builder: (context) {
        return SpecialistDetailsPopup(
          specialistId: specialist.id,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _searchByMyAddress,
        icon: const Icon(Icons.my_location_rounded),
        label: const Text('Blisko mnie'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: 'Wpisz miasto lub adres...',
                    prefixIcon: const Icon(Icons.location_city_rounded),
                    filled: true,
                    fillColor: AppColors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onSubmitted: (_) => _searchByAddress(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                  onPressed: _searchByAddress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text(_error!, style: TextStyle(color: AppColors.error)),
              ),
            )
          else if (_specialists.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Brak wyników lub nie wyszukano specjalistów.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _specialists.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final sp = _specialists[index];
                  return SpecialistCard(
                    specialist: sp,
                    onTap: () => _showSpecialistDetails(sp),
                  );
                },
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class SpecialistCard extends StatelessWidget {
  final NearbySpecialist specialist;
  final VoidCallback onTap;

  const SpecialistCard({
    super.key,
    required this.specialist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: ClipOval(
                child: specialist.avatarUrl != null && specialist.avatarUrl!.isNotEmpty
                    ? Image.network(
                        specialist.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, color: AppColors.primary),
                      )
                    : const Icon(Icons.person, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    specialist.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (specialist.professionalTitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      specialist.professionalTitle!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpecialistDetailsPopup extends StatefulWidget {
  final String specialistId;

  const SpecialistDetailsPopup({
    super.key,
    required this.specialistId,
  });

  @override
  State<SpecialistDetailsPopup> createState() => _SpecialistDetailsPopupState();
}

class _SpecialistDetailsPopupState extends State<SpecialistDetailsPopup> {
  final ApiService _apiService = ApiService();
  SpecialistProfileDetails? _profile;
  List<SpecialistOffer>? _offers;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final profileFuture = _apiService.getSpecialistProfileDetails(
        widget.specialistId,
      );
      final offersFuture = _apiService.getSpecialistFullOffer(
        widget.specialistId,
      );

      final results = await Future.wait([profileFuture, offersFuture]);
      setState(() {
        _profile = results[0] as SpecialistProfileDetails;
        _offers = results[1] as List<SpecialistOffer>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
              ? SizedBox(
                  height: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Błąd ładowania profilu',
                        style: TextStyle(color: AppColors.error),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Zamknij'),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                          child: ClipOval(
                            child: _profile!.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty
                                ? Image.network(
                                    _profile!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.person, color: AppColors.primary, size: 36),
                                  )
                                : const Icon(Icons.person, color: AppColors.primary, size: 36),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profile!.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              if (_profile!.professionalTitle != null)
                                Text(
                                  _profile!.professionalTitle!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              if (_profile!.profession != null)
                                Text(
                                  _profile!.profession!,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_profile!.phoneNumber != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _profile!.phoneNumber!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (_profile!.bio != null) ...[
                      const Text(
                        'O specjaliście:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _profile!.bio!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      const Expanded(child: SizedBox()),
                    const SizedBox(height: 16),
                    const Text(
                      'Dostępne usługi:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_offers!.isEmpty)
                      const Text(
                        'Brak usług w ofercie.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _offers!.length,
                          itemBuilder: (context, index) {
                            final offer = _offers![index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(offer.name),
                              subtitle: Text(
                                '${offer.durationMinutes} min • ${offer.category}',
                              ),
                              trailing: Text(
                                '${offer.price} zł',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Zamknij',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
