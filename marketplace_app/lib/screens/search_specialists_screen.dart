import 'package:flutter/material.dart';
import 'package:marketplace_app/widgets/screen_status_bar.dart';
import 'package:marketplace_app/widgets/specialist_card.dart';
import '../../services/api_service.dart';
import '../../services/google_places_service.dart';
import '../../models/nearby_specialist.dart';
import '../../models/specialist_profile_details.dart';
import '../../models/specialist_offer.dart';
import '../../theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import '../data/data.dart';

class SearchSpecialistsScreen extends StatefulWidget {
  final Future<List<NearbySpecialist>> Function(String address)? addressSearch;
  final Future<List<NearbySpecialist>> Function(double lat, double lng)?
      locationSearch;
  final Future<List<NearbySpecialist>> Function()? profileAddressSearch;
  final Future<List<String>> Function(String query)? autocompleteSearch;

  const SearchSpecialistsScreen({
    super.key,
    this.addressSearch,
    this.locationSearch,
    this.profileAddressSearch,
    this.autocompleteSearch,
  });

  @override
  State<SearchSpecialistsScreen> createState() =>
      _SearchSpecialistsScreenState();
}

class _SearchSpecialistsScreenState extends State<SearchSpecialistsScreen> {
  final TextEditingController _addressController = TextEditingController();
  final FocusNode _addressFocusNode = FocusNode();
  final ApiService _apiService = ApiService();

  List<NearbySpecialist> _specialists = [];
  bool _isLoading = false;
  String? _error;

  DateTime? _lastRequestTime;
  final Duration _cooldown = const Duration(seconds: 5);

  @override
  void dispose() {
    _addressController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  void _searchByAddress() {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;
    final search =
        widget.addressSearch ?? _apiService.getNearbySpecialistsByAddressText;
    _performSearch(
      () => search(address),
    );
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
        return SpecialistDetailsPopup(specialistId: specialist.id);
      },
    );
  }

  Future<void> _useDeviceLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usługi lokalizacji są wyłączone. Włącz lokalizację w ustawieniach.')));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uprawnienie do lokalizacji zostało odrzucone')));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uprawnienie do lokalizacji jest zablokowane. Włącz je w ustawieniach aplikacji.')));
        return;
      }

      final position = await Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.high));

      // Use coordinates to fetch nearby specialists
      if (!mounted) return;
      final search = widget.locationSearch ?? _apiService.getNearbySpecialists;
      _performSearch(() => search(position.latitude, position.longitude));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd pobierania lokalizacji: ${e.toString()}')));
    }
  }

  void _onFabPressed() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wyszukaj blisko mnie'),
        content: const Text('Wybierz źródło lokalizacji:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _useDeviceLocation();
            },
            child: const Text('Użyj lokalizacji telefonu'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final search = widget.profileAddressSearch ??
                  _apiService.getNearbySpecialistsMyAddress;
              _performSearch(() => search());
            },
            child: const Text('Użyj adresu z profilu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenStatusBar(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _onFabPressed,
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
              RawAutocomplete<String>(
                textEditingController: _addressController,
                focusNode: _addressFocusNode,
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.length < 4) return const Iterable<String>.empty();
                  final autocomplete = widget.autocompleteSearch ??
                      GooglePlacesService().getAutocompleteSuggestions;
                  return await autocomplete(textEditingValue.text);
                },
                onSelected: (selection) {
                  _addressController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Wpisz miasto lub adres...',
                      prefixIcon: const Icon(Icons.location_city_rounded),
                      filled: true,
                      fillColor: AppColors.surfaceContainerHighest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      suffixIcon: IconButton(icon: const Icon(Icons.search_rounded), onPressed: _searchByAddress),
                    ),
                    onSubmitted: (_) => _searchByAddress(),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: AppColors.surface,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200, maxWidth: 600),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(title: Text(option), onTap: () { onSelected(option); _searchByAddress(); });
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppColors.error),
                    ),
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
                    padding: const EdgeInsets.only(bottom: 52),
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
      ),
    );
  }
}
class SpecialistDetailsPopup extends StatefulWidget {
  final String specialistId;

  const SpecialistDetailsPopup({super.key, required this.specialistId});

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
      if (!mounted) return;
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

  String _formatPrice(double price) {
    final hasFraction = price % 1 != 0;
    return hasFraction
        ? '${price.toStringAsFixed(2).replaceAll('.', ',')} zł'
        : '${price.toStringAsFixed(0)} zł';
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildCoverageAreas(List<SpecialistProfileArea> areas) {
    if (areas.isEmpty) {
      return const Text(
        'Brak zdefiniowanego obszaru działania.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: areas
          .map(
            (area) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                [
                  if (area.city != null && area.city!.isNotEmpty) area.city,
                  if (area.postalCode != null && area.postalCode!.isNotEmpty)
                    area.postalCode,
                  '${area.maxDistanceKm} km',
                ].whereType<String>().join(' • '),
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildOfferItem(SpecialistOffer offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  offer.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Text(
                _formatPrice(offer.price),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            (offer.name == Data.localizedProfession(offer.category))
                ? '${offer.durationMinutes} min'
                : '${offer.durationMinutes} min • ${Data.localizedProfession(offer.category)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (offer.description != null && offer.description!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                offer.description!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width > 640 ? 600.0 : 520.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 680, maxWidth: maxWidth),
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
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _fetchDetails();
                        },
                        child: const Text('Spróbuj ponownie'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Zamknij'),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.12),
                          ),
                          child: ClipOval(
                            child:
                                _profile!.avatarUrl != null &&
                                    _profile!.avatarUrl!.isNotEmpty
                                ? Image.network(
                                    _profile!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                        size: 36,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                    size: 36,
                                  ),
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
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox.shrink(),
                              if (_profile!.qualifications.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: _profile!.qualifications
                                        .take(3)
                                        .map(
                                          (q) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              Data.localizedProfessionalTitle(q),
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      fit: FlexFit.loose,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildSectionCard(
                              title: 'O specjaliście',
                              icon: Icons.info_outline_rounded,
                              child: Text(
                                (_profile!.bio != null &&
                                        _profile!.bio!.trim().isNotEmpty)
                                    ? _profile!.bio!
                                    : 'Specjalista nie dodał jeszcze opisu profilu.',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ),
                            _buildSectionCard(
                              title: 'Obszar działania',
                              icon: Icons.location_on_outlined,
                              child: _buildCoverageAreas(_profile!.areas),
                            ),
                            _buildSectionCard(
                              title: 'Dostępne usługi',
                              icon: Icons.medical_services_outlined,
                              child: _offers!.isEmpty
                                  ? const Text(
                                      'Brak usług w ofercie.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    )
                                  : Column(
                                      children: _offers!
                                          .map((offer) => _buildOfferItem(offer))
                                          .toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
