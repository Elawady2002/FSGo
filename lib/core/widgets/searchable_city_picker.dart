import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/city_provider.dart';
import '../domain/entities/city_entity.dart';

class SearchableCityPicker extends ConsumerStatefulWidget {
  final String? initialCityId;
  final Function(CityEntity) onCitySelected;

  const SearchableCityPicker({
    super.key,
    this.initialCityId,
    required this.onCitySelected,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialCityId,
    required Function(CityEntity) onCitySelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchableCityPicker(
        initialCityId: initialCityId,
        onCitySelected: onCitySelected,
      ),
    );
  }

  @override
  ConsumerState<SearchableCityPicker> createState() => _SearchableCityPickerState();
}

class _SearchableCityPickerState extends ConsumerState<SearchableCityPicker> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGovernorate;

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(citiesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedGovernorate == null ? 'اختر المحافظة' : 'اختر المدينة',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'ابحث عن مدينة...',
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.cairo(fontSize: 14),
              placeholderStyle: GoogleFonts.cairo(
                color: CupertinoColors.systemGrey,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // List Content
          Expanded(
            child: citiesAsync.when(
              data: (allCities) {
                List<Widget> items = [];

                if (_searchQuery.isNotEmpty) {
                  // Global Search
                  final filtered = allCities.where((c) =>
                      c.nameAr.contains(_searchQuery) ||
                      c.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()));
                  
                  for (var city in filtered) {
                    items.add(_buildCityTile(city, city.governorate ?? ''));
                  }
                } else if (_selectedGovernorate != null) {
                  // Show Cities in Selected Governorate
                  items.add(_buildBackButton());
                  final govCities = allCities.where((c) => c.governorate == _selectedGovernorate);
                  for (var city in govCities) {
                    items.add(_buildCityTile(city, _selectedGovernorate!));
                  }
                } else {
                  // Show unique Governorates
                  final governorates = allCities
                      .map((c) => c.governorate)
                      .whereType<String>()
                      .toSet()
                      .toList()
                    ..sort();
                  
                  for (var gov in governorates) {
                    items.add(_buildGovernorateTile(gov));
                  }
                }

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد نتائج',
                      style: GoogleFonts.cairo(color: Colors.grey),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  children: items,
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'فشل تحميل البيانات: $err',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return ListTile(
      onTap: () => setState(() => _selectedGovernorate = null),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppTheme.primaryColor),
      title: Text(
        'العودة للمحافظات',
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildGovernorateTile(String gov) {
    return Column(
      children: [
        ListTile(
          onTap: () => setState(() => _selectedGovernorate = gov),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          title: Text(
            gov,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ),
        Divider(color: Colors.grey.shade100, height: 1),
      ],
    );
  }

  Widget _buildCityTile(CityEntity city, String gov) {
    final isSelected = widget.initialCityId == city.id;
    return Column(
      children: [
        ListTile(
          onTap: () {
            widget.onCitySelected(city);
            Navigator.pop(context);
          },
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          title: Text(
            city.nameAr,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: _searchQuery.isNotEmpty
              ? Text(
                  gov,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                )
              : null,
          trailing: isSelected
              ? const Icon(CupertinoIcons.check_mark, color: AppTheme.primaryColor, size: 20)
              : const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
        ),
        Divider(color: Colors.grey.shade100, height: 1),
      ],
    );
  }
}
