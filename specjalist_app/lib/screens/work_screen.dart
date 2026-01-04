import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WorkScreen extends StatefulWidget {
  const WorkScreen({super.key});

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  
  bool isLoading = true;
  String? selectedService;
  bool customService = false;

  final TextEditingController customServiceController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  // przykładowe dane z API
  //specjalist servises - pobierać, cene i czas trwania
  //service types - nazwe usługi i kategorie
  final services = [
    {
      'name': 'Podstawowa opieka pielęgniarska',
      'price': '189',
      'time': '180'
    },
    {
      'name': 'Podanie zastrzyku dożylnego',
      'price': '20',
      'time': '30'
    },
    {
      'name': 'Zmiana opatrunku',
      'price': '50',
      'time': '30'
    },
    {
      'name': 'Pobieranie krwi',
      'price': '30',
      'time': '30'
    },
   
  ];
  final servicesfromdb= [
    {
      'name': 'Ogólne',
    },
    {
      'name': 'Zmiana opatrunku',
    },
    {
      'name': 'Pobieranie krwi',
    },
    {
      'name': 'Podanie zastrzyku domięśniowego',
    },
    {
      'name': 'Podanie zastrzyku podskórnego',
    },
    {
      'name': 'Podanie zastrzyku dożylnego',
    },
    {
      'name': 'Założenie kroplówki',
    },
    {
      'name':'Zmiana / prowadzenie kroplówki',
    },
    {
      'name': 'Pomiar poziomu glukozy we krwi',
    },
    {
      'name': 'Opatrunek specjalistyczny',
    },
    {
      'name': 'Pielęgnacja rany przewlekłej',
    },
    {
      'name': 'Zdjęcie szwów',
    },
    {
      'name': 'Pielęgnacja odleżyn',
    },
    {
      'name': 'Podstawowa opieka pielęgniarska',
    },
    {
      'name': 'Opieka nad pacjentem leżącym',
    },
     {
      'name': 'Pomoc w higienie osobistej pacjenta',
    },
     {
      'name': 'Profilaktyka przeciwodleżynowa',
    },
     {
      'name': 'Konsultacja pielęgniarska',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // symulacja pobrania danych
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoading = false);
  }
  
@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onBackground,
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40), // margines od góry
                    Column(
                      children: [
                        Container(
                          width: 350,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.background,
                                AppColors.onBackground,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12), // opcjonalnie zaokrąglone rogi
                          ),
                          child: _buildSection('Aktualne usługi', services),
                        ),
                        const SizedBox(height: 16),
                        Container(
  width: 350,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.background,
        AppColors.onBackground,
      ],
    ),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Dodaj usługę',
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
              
            ),
      ),
      const SizedBox(height: 16),

      DropdownButtonFormField<String>(
        
        initialValue: selectedService,
        isExpanded: true, 
        hint: const Text('Wybierz usługę'),
         dropdownColor: AppColors.onPrimary,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          fillColor: AppColors.onPrimary,
          filled: true, // <- ważne
        ),
        items: [
          ...servicesfromdb.map(
            (service) => DropdownMenuItem<String>(
              value: service['name'] as String,
              child: Text(service['name'] as String),
            ),
          ),
          const DropdownMenuItem<String>(
            value: 'custom',
            child: Text('Inna (wpisz nazwę)'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            selectedService = value;
            customService = value == 'custom';
          });
        },
        
      ),

      if (customService) ...[
        const SizedBox(height: 12),
        TextField(
          controller: customServiceController,
          decoration: const InputDecoration(
            labelText: 'Nazwa usługi',
            border: OutlineInputBorder(),
            fillColor: AppColors.onPrimary,
          filled: true, 
          ),
        ),
      ],

      const SizedBox(height: 12),

      TextField(
        controller: priceController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Cena (zł)',
          border: OutlineInputBorder(),
          fillColor: AppColors.onPrimary,
          filled: true, 
        ),
      ),

      const SizedBox(height: 12),

      TextField(
        controller: durationController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Czas trwania (min)',
          border: OutlineInputBorder(),
          fillColor: AppColors.onPrimary,
          filled: true, 
        ),
      ),

      const SizedBox(height: 16),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.onSurface,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              fixedSize: const Size(125, 29),
                            ),
          onPressed: () {
            final serviceName = customService
                ? customServiceController.text
                : selectedService;

            final price = priceController.text;
            final duration = durationController.text;

            debugPrint('Usługa: $serviceName');
            debugPrint('Cena: $price');
            debugPrint('Czas: $duration');
          },
          
          child: const Text('Dodaj usługę'),
        ),
      ),
    ],
  ),
),
                      ],
                    )
                  ],
                ),
              ),
      ),
      
    );
  }

  Widget _buildSection(String title, List<Map<String, String>> items) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400), // maksymalna szerokość
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontSize: 24,
                color: AppColors.onSurface,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Column(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                  child: SizedBox(
                    width: 310,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          item['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 20),
                        ),
                        const SizedBox(height: 8),
                          Text('Od: ${item['price']}  czas trwania: ${item['time']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}