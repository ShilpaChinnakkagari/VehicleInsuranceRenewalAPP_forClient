import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import 'add_customer_screen.dart';

class InsuranceRenewalScreen extends StatefulWidget {
  const InsuranceRenewalScreen({super.key});

  @override
  State<InsuranceRenewalScreen> createState() => _InsuranceRenewalScreenState();
}

class _InsuranceRenewalScreenState extends State<InsuranceRenewalScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  
  String _selectedFilter = 'Today';
  int? _selectedMonth;
  int? _selectedYear;
  
  // Store data as Maps with IDs for mutability
  List<Map<String, dynamic>> _allCustomers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  List<Map<String, dynamic>> _displayCustomers = [];
  
  // Store original documents for editing
  Map<String, DocumentSnapshot> _documents = {};
  
  bool _isSearching = false;
  
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalItems = 0;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _yearController.addListener(_onYearChanged);
    _selectedYear = DateTime.now().year;
    _yearController.text = _selectedYear.toString();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _yearController.removeListener(_onYearChanged);
    _searchController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_searchController.text.isNotEmpty) {
        _filterCustomers();
      } else {
        _clearSearch();
      }
    });
  }

  void _onYearChanged() {
    if (_yearController.text.isEmpty) {
      setState(() {
        _selectedYear = null;
        _currentPage = 1;
      });
      return;
    }
    
    final year = int.tryParse(_yearController.text);
    if (year != null && year > 2000 && year < 2100) {
      setState(() {
        _selectedYear = year;
        _currentPage = 1;
      });
    }
  }

  void _filterCustomers() {
    if (!mounted) return;
    
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = _allCustomers.where((data) {
        final name = data['name']?.toLowerCase() ?? '';
        final regNo = data['vehicle_reg_no']?.toLowerCase() ?? '';
        final mobile = data['mobile']?.toLowerCase() ?? '';
        return name.contains(query) || regNo.contains(query) || mobile.contains(query);
      }).toList();
      _isSearching = true;
      _currentPage = 1;
      _updateDisplayCustomers();
    });
  }

  void _clearSearch() {
    if (!mounted) return;
    setState(() {
      _filteredCustomers = [];
      _isSearching = false;
      _currentPage = 1;
      _updateDisplayCustomers();
    });
  }

  void _updateDisplayCustomers() {
    final sourceList = _isSearching ? _filteredCustomers : _allCustomers;
    _totalItems = sourceList.length;
    
    if (_totalItems == 0) {
      _displayCustomers = [];
      return;
    }
    
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    
    if (startIndex < _totalItems) {
      _displayCustomers = sourceList.sublist(
        startIndex,
        endIndex > _totalItems ? _totalItems : endIndex,
      );
    } else {
      _displayCustomers = [];
    }
  }

  void _nextPage() {
    if (!mounted) return;
    setState(() {
      _currentPage++;
      _updateDisplayCustomers();
    });
  }

  void _previousPage() {
    if (!mounted) return;
    setState(() {
      _currentPage--;
      _updateDisplayCustomers();
    });
  }

  // 🔥 INSTANT COLOR UPDATE
  void _updateStatus(String docId, String newStatus) {
    FirebaseFirestore.instance
        .collection('customers')
        .doc(docId)
        .update({'status': newStatus});
    
    setState(() {
      for (var data in _allCustomers) {
        if (data['id'] == docId) {
          data['status'] = newStatus;
          break;
        }
      }
      for (var data in _filteredCustomers) {
        if (data['id'] == docId) {
          data['status'] = newStatus;
          break;
        }
      }
      for (var data in _displayCustomers) {
        if (data['id'] == docId) {
          data['status'] = newStatus;
          break;
        }
      }
    });
  }

  Future<void> _deleteCustomer(String docId, String customerName) async {
    await FirebaseFirestore.instance
        .collection('customers')
        .doc(docId)
        .delete();
    
    if (mounted) {
      setState(() {
        _allCustomers.removeWhere((d) => d['id'] == docId);
        _filteredCustomers.removeWhere((d) => d['id'] == docId);
        _documents.remove(docId);
        _updateDisplayCustomers();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$customerName deleted'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // 🔥 FIXED: Edit using stored DocumentSnapshot
  void _editCustomer(String docId) {
    if (!mounted) return;
    
    final doc = _documents[docId];
    if (doc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Customer document not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomerScreen(
          existingCustomer: doc,
          isEditing: true,
        ),
      ),
    ).then((value) {
      if (value == true && mounted) {
        setState(() {
          _allCustomers = [];
          _filteredCustomers = [];
          _displayCustomers = [];
          _documents.clear();
          _currentPage = 1;
        });
      }
    });
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (!mounted) return;
        setState(() {
          _selectedFilter = label;
          _selectedMonth = null;
          _currentPage = 1;
        });
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    switch(_selectedFilter) {
      case 'Today':
        return FirebaseFirestore.instance
            .collection('customers')
            .where('renewal_date', isEqualTo: today)
            .orderBy('name')
            .snapshots();
            
      case 'Upcoming':
        final sevenDaysLater = DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0];
        return FirebaseFirestore.instance
            .collection('customers')
            .where('renewal_date', isGreaterThan: today)
            .where('renewal_date', isLessThanOrEqualTo: sevenDaysLater)
            .orderBy('renewal_date')
            .snapshots();
            
      case 'All':
        return FirebaseFirestore.instance
            .collection('customers')
            .orderBy('renewal_date', descending: true)
            .snapshots();
            
      default:
        return FirebaseFirestore.instance
            .collection('customers')
            .orderBy('renewal_date', descending: true)
            .snapshots();
    }
  }

  List<Map<String, dynamic>> _filterByDate(QuerySnapshot snapshot) {
    // Store documents for editing
    for (var doc in snapshot.docs) {
      _documents[doc.id] = doc;
    }
    
    // Convert to mutable maps with IDs
    var allData = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Map<String, dynamic>.from(data);
    }).toList();
    
    if (_selectedFilter == 'Month' && _selectedMonth != null) {
      return allData.where((data) {
        final dateStr = data['renewal_date'] as String?;
        if (dateStr == null) return false;
        try {
          final date = DateTime.parse(dateStr);
          return date.month == _selectedMonth && date.year == _selectedYear;
        } catch (e) {
          return false;
        }
      }).toList();
    } else if (_selectedFilter == 'Year' && _selectedYear != null) {
      return allData.where((data) {
        final dateStr = data['renewal_date'] as String?;
        if (dateStr == null) return false;
        try {
          final date = DateTime.parse(dateStr);
          return date.year == _selectedYear;
        } catch (e) {
          return false;
        }
      }).toList();
    }
    return allData;
  }

  int _getGlobalIndex(Map<String, dynamic> data) {
    final sourceList = _isSearching ? _filteredCustomers : _allCustomers;
    final index = sourceList.indexWhere((d) => d['id'] == data['id']);
    return index + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _clearSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Today', _selectedFilter == 'Today'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Upcoming', _selectedFilter == 'Upcoming'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Month', _selectedFilter == 'Month'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Year', _selectedFilter == 'Year'),
                      const SizedBox(width: 8),
                      _buildFilterChip('All', _selectedFilter == 'All'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_selectedFilter == 'Month' || _selectedFilter == 'Year')
                  Row(
                    children: [
                      if (_selectedFilter == 'Month')
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: DropdownButton<int>(
                              value: _selectedMonth,
                              hint: const Text('Month'),
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: List.generate(12, (index) {
                                return DropdownMenuItem(
                                  value: index + 1,
                                  child: Text(_months[index]),
                                );
                              }),
                              onChanged: (value) {
                                if (!mounted) return;
                                setState(() {
                                  _selectedMonth = value;
                                  _currentPage = 1;
                                });
                              },
                            ),
                          ),
                        ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextField(
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter year',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Pagination Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isSearching 
                      ? '${_filteredCustomers.length} results'
                      : '$_selectedFilter (${_allCustomers.length} total)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_totalItems > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          onPressed: _currentPage > 1 ? _previousPage : null,
                          color: _currentPage > 1 ? Colors.blue : Colors.grey,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          'Page $_currentPage/${(_totalItems / _itemsPerPage).ceil()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          onPressed: _currentPage * _itemsPerPage < _totalItems ? _nextPage : null,
                          color: _currentPage * _itemsPerPage < _totalItems ? Colors.blue : Colors.grey,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Customer List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No customers found'));
                }

                final filteredData = _filterByDate(snapshot.data!);
                
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  if (_allCustomers.length != filteredData.length || _allCustomers.isEmpty) {
                    setState(() {
                      _allCustomers = filteredData;
                      _updateDisplayCustomers();
                    });
                  }
                });

                if (_displayCustomers.isEmpty) {
                  return const Center(child: Text('No customers on this page'));
                }

                return ListView.builder(
                  key: ValueKey(_currentPage),
                  padding: const EdgeInsets.all(16),
                  itemCount: _displayCustomers.length,
                  itemBuilder: (context, index) {
                    final data = _displayCustomers[index];
                    final status = data['status'] ?? 'pending';
                    
                    final globalIndex = _getGlobalIndex(data);
                    final totalRecords = _isSearching ? _filteredCustomers.length : _allCustomers.length;
                    
                    Color backgroundColor;
                    switch(status) {
                      case 'contacted':
                        backgroundColor = Colors.green.shade100;
                        break;
                      case 'not_responded':
                        backgroundColor = Colors.red.shade100;
                        break;
                      default:
                        backgroundColor = Colors.blue.shade100;
                    }

                    return Dismissible(
                      key: Key(data['id']),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      secondaryBackground: Container(
                        color: Colors.blue,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Text(
                          'Edit',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          final confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete'),
                              content: Text('Delete ${data['name']}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('CANCEL'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('DELETE'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _deleteCustomer(data['id'], data['name'] ?? '');
                          }
                          return false;
                        } else {
                          // 🔥 FIXED: Pass ID to edit
                          _editCustomer(data['id']);
                          return false;
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: status == 'contacted' 
                                ? Colors.green.shade300
                                : status == 'not_responded'
                                    ? Colors.red.shade300
                                    : Colors.blue.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: Text(
                                  '$globalIndex / $totalRecords',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.check_circle,
                                          color: status == 'contacted' 
                                              ? Colors.green.shade700 
                                              : Colors.grey.shade400,
                                          size: 28,
                                        ),
                                        onPressed: () => _updateStatus(data['id'], 'contacted'),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.cancel,
                                          color: status == 'not_responded' 
                                              ? Colors.red.shade700 
                                              : Colors.grey.shade400,
                                          size: 28,
                                        ),
                                        onPressed: () => _updateStatus(data['id'], 'not_responded'),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.refresh,
                                          color: status == 'pending' 
                                              ? Colors.blue.shade700 
                                              : Colors.grey.shade400,
                                          size: 24,
                                        ),
                                        onPressed: () => _updateStatus(data['id'], 'pending'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '🚗 ${data['vehicle_reg_no'] ?? 'No Reg No'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    '📅 ${data['renewal_date'] ?? ''}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '📞 ${data['mobile'] ?? 'No Mobile'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  if (data['mobile'] != null)
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.phone, color: Colors.blue),
                                          onPressed: () {
                                            launchUrl(Uri.parse('tel:${data['mobile']}'));
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.message, color: Colors.green),
                                          onPressed: () {
                                            final message = 'Hello ${data['name']}, your vehicle ${data['vehicle_reg_no']} insurance is due.';
                                            launchUrl(Uri.parse('https://wa.me/${data['mobile']}?text=${Uri.encodeComponent(message)}'));
                                          },
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}