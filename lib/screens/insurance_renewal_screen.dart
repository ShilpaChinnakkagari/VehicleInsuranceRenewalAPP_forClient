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
  
  String _selectedFilter = 'Today';
  int? _selectedMonth;
  int? _selectedYear;
  
  List<DocumentSnapshot> _allCustomers = [];
  List<DocumentSnapshot> _filteredCustomers = [];
  bool _isSearching = false;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCustomers);
    _selectedYear = DateTime.now().year;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredCustomers = _allCustomers;
        _isSearching = false;
      });
    } else {
      setState(() {
        _filteredCustomers = _allCustomers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toLowerCase() ?? '';
          final regNo = data['vehicle_reg_no']?.toLowerCase() ?? '';
          final mobile = data['mobile']?.toLowerCase() ?? '';
          return name.contains(query) || regNo.contains(query) || mobile.contains(query);
        }).toList();
        _isSearching = true;
      });
    }
  }

  Future<void> _deleteCustomer(String docId, String customerName) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text('Are you sure you want to delete $customerName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('customers')
                    .doc(docId)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$customerName deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }

  void _editCustomer(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomerScreen(
          existingCustomer: doc,
          isEditing: true,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _selectedMonth = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch(status) {
      case 'contacted':
        return Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 18),
        );
      case 'not_responded':
        return Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 18),
        );
      default:
        return Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.access_time, color: Colors.white, size: 16),
        );
    }
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
      default:
        return FirebaseFirestore.instance
            .collection('customers')
            .orderBy('renewal_date', descending: true)
            .snapshots();
    }
  }

  List<DocumentSnapshot> _filterByDate(List<DocumentSnapshot> docs) {
    if (_selectedFilter == 'Month' && _selectedMonth != null) {
      return docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
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
      return docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
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
    return docs;
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, vehicle number, or mobile...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Today', _selectedFilter == 'Today'),
                      _buildFilterChip('Upcoming', _selectedFilter == 'Upcoming'),
                      _buildFilterChip('Month', _selectedFilter == 'Month'),
                      _buildFilterChip('Year', _selectedFilter == 'Year'),
                      _buildFilterChip('All', _selectedFilter == 'All'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Month/Year selectors
                if (_selectedFilter == 'Month' || _selectedFilter == 'Year')
                  Row(
                    children: [
                      if (_selectedFilter == 'Month')
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedMonth,
                                hint: const Text('Select Month'),
                                isExpanded: true,
                                items: List.generate(12, (index) {
                                  return DropdownMenuItem(
                                    value: index + 1,
                                    child: Text(_months[index]),
                                  );
                                }),
                                onChanged: (value) => setState(() => _selectedMonth = value),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedYear,
                              hint: const Text('Select Year'),
                              isExpanded: true,
                              items: List.generate(5, (index) {
                                final year = DateTime.now().year - 2 + index;
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }),
                              onChanged: (value) => setState(() => _selectedYear = value),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Customer Count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    _isSearching 
                        ? '${_filteredCustomers.length} results found'
                        : '$_selectedFilter Customers',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (_isSearching)
                  TextButton(
                    onPressed: () => _searchController.clear(),
                    child: const Text('Clear Search'),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text('Error loading customers', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No customers found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  );
                }

                _allCustomers = snapshot.data!.docs;
                var displayCustomers = _filterByDate(_allCustomers);
                
                if (_isSearching) {
                  displayCustomers = _filteredCustomers;
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayCustomers.length,
                  itemBuilder: (context, index) {
                    final doc = displayCustomers[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'pending';
                    
                    Color rowColor;
                    switch(status) {
                      case 'contacted':
                        rowColor = Colors.green.shade50;
                        break;
                      case 'not_responded':
                        rowColor = Colors.red.shade50;
                        break;
                      default:
                        rowColor = Colors.blue.shade50;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: rowColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: status == 'contacted' 
                              ? Colors.green.shade200
                              : status == 'not_responded'
                                  ? Colors.red.shade200
                                  : Colors.blue.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
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
                            Row(
                              children: [
                                _buildStatusIcon(status),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? 'Unknown',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              data['vehicle_reg_no'] ?? 'No Reg No',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '📅 ${data['renewal_date'] ?? ''}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton(
                                  icon: const Icon(Icons.more_vert),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      onTap: () => _editCustomer(doc),
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue, size: 20),
                                          const SizedBox(width: 8),
                                          const Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      onTap: () => _deleteCustomer(doc.id, data['name'] ?? 'Unknown'),
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red, size: 20),
                                          const SizedBox(width: 8),
                                          const Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                if (data['mobile'] != null)
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              data['mobile']!,
                                              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                
                                const SizedBox(width: 8),
                                
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Green - Contacted
                                      IconButton(
                                        icon: Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                                        onPressed: () => _firestoreService.updateStatus(doc.id, 'contacted'),
                                        tooltip: 'Mark Contacted',
                                      ),
                                      // Red - Not Responded
                                      IconButton(
                                        icon: Icon(Icons.cancel, color: Colors.red.shade600, size: 20),
                                        onPressed: () => _firestoreService.updateStatus(doc.id, 'not_responded'),
                                        tooltip: 'Mark Not Responded',
                                      ),
                                      // Blue - Reset to Not Contacted
                                      IconButton(
                                        icon: Icon(Icons.refresh, color: Colors.blue.shade600, size: 20),
                                        onPressed: () => _firestoreService.updateStatus(doc.id, 'pending'),
                                        tooltip: 'Reset to Not Contacted',
                                      ),
                                      if (data['mobile'] != null) ...[
                                        // Call Button - FIXED
                                        IconButton(
                                          icon: Icon(Icons.phone, color: Colors.blue.shade600, size: 20),
                                          onPressed: () {
                                            final url = 'tel:${data['mobile']}';
                                            launchUrl(Uri.parse(url));
                                          },
                                          tooltip: 'Call',
                                        ),
                                        // WhatsApp Button
                                        IconButton(
                                          icon: Icon(Icons.message, color: Colors.green.shade700, size: 20),
                                          onPressed: () {
                                            final message = 'Hello ${data['name']}, your vehicle ${data['vehicle_reg_no']} insurance is due for renewal. Please contact us.';
                                            final url = 'https://wa.me/${data['mobile']}?text=${Uri.encodeComponent(message)}';
                                            launchUrl(Uri.parse(url));
                                          },
                                          tooltip: 'WhatsApp',
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
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