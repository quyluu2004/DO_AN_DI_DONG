
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [NEW]
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart'; // [NEW]
import '../product/product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // Filters
  RangeValues _priceRange = const RangeValues(0, 5000000);
  String? _selectedCategory;
  String _sortBy = 'newest'; // newest, price_asc, price_desc

  // Mock Data for Demo
  List<Product> _results = [];
  bool _isSearching = false;



  // Search History [NEW]
  List<String> _searchHistory = []; // Start empty, load from prefs

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
  }

  void _performSearch(String query) async {
    if (query.isEmpty) return;
    
    // Save to history
    if (!_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 5) _searchHistory.removeLast();
      });
      _saveHistory(); // Save persistence
    } else {
        // Move to top if already exists
        setState(() {
            _searchHistory.remove(query);
            _searchHistory.insert(0, query);
        });
        _saveHistory();
    }

    setState(() => _isSearching = true);

    try {
      // Use the existing searchProducts method from ProductService
      // Since it returns a Stream, we take the first emission for this search action
      final products = await ProductService.instance.searchProducts(searchQuery: query).first;
      
      setState(() {
        _results = products;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _results = [];
        _isSearching = false;
      });
    }
  }

  void _onTagSelected(String tag) {
    _searchController.text = tag;
    _performSearch(tag);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bộ lọc', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              
              // Price
              const Text('Khoảng giá', style: TextStyle(fontWeight: FontWeight.w600)),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 5000000,
                divisions: 50,
                labels: RangeLabels(
                  '${(_priceRange.start/1000).toStringAsFixed(0)}k', 
                  '${(_priceRange.end/1000).toStringAsFixed(0)}k'
                ),
                onChanged: (val) => setModalState(() => _priceRange = val),
                activeColor: AppColors.charcoal,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(_priceRange.start).toStringAsFixed(0)} đ'),
                  Text('${(_priceRange.end).toStringAsFixed(0)} đ'),
                ],
              ),
              const SizedBox(height: 24),

              // Category
              const Text('Danh mục', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Women', 'Men', 'Kids', 'Shoes', 'Bags'].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) => setModalState(() => _selectedCategory = selected ? cat : null),
                    selectedColor: AppColors.charcoal,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  );
                }).toList(),
              ),
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _performSearch(_searchController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.charcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm sản phẩm...',
            border: InputBorder.none,
          ),
          onSubmitted: _performSearch,
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {
                _results = [];
                _isSearching = false;
              });
            }
          },
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
              }
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),

      body: _isSearching 
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty && _searchController.text.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('Không tìm thấy kết quả', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : _results.isEmpty && _searchController.text.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Lịch sử tìm kiếm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _searchHistory.map((tag) => ActionChip(
                              label: Text(tag),
                              onPressed: () => _onTagSelected(tag),
                              avatar: const Icon(Icons.history, size: 16, color: Colors.grey),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey[300]!)),
                            )).toList(),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = _results[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                                image: product.images.isNotEmpty 
                                  ? DecorationImage(image: NetworkImage(product.images.first), fit: BoxFit.cover)
                                  : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(product.category ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('đ ${product.price}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.charcoal)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
