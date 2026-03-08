import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class AddCustomerScreen extends StatefulWidget {
  final DocumentSnapshot? existingCustomer;
  final bool isEditing;

  const AddCustomerScreen({
    super.key,
    this.existingCustomer,
    this.isEditing = false,
  });

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _regNoController = TextEditingController();
  final _chassisNoController = TextEditingController();
  final _doorNoController = TextEditingController();
  final _streetController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  
  DateTime? _issueDate;
  DateTime? _renewalDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.existingCustomer != null) {
      final data = widget.existingCustomer!.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _mobileController.text = data['mobile'] ?? '';
      _regNoController.text = data['vehicle_reg_no'] ?? '';
      _chassisNoController.text = data['chassis_no'] ?? '';
      _doorNoController.text = data['door_no'] ?? '';
      _streetController.text = data['street'] ?? '';
      _districtController.text = data['district'] ?? '';
      _stateController.text = data['state'] ?? '';
      if (data['issue_date'] != null) {
        _issueDate = DateTime.parse(data['issue_date']);
      }
      if (data['renewal_date'] != null) {
        _renewalDate = DateTime.parse(data['renewal_date']);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _regNoController.dispose();
    _chassisNoController.dispose();
    _doorNoController.dispose();
    _streetController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _renewalDate = picked;
        }
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _mobileController.clear();
    _regNoController.clear();
    _chassisNoController.clear();
    _doorNoController.clear();
    _streetController.clear();
    _districtController.clear();
    _stateController.clear();
    setState(() {
      _issueDate = null;
      _renewalDate = null;
    });
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_renewalDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select renewal date'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() => _isSaving = true);

    final customerData = {
      'name': _nameController.text,
      'email': _emailController.text.isNotEmpty ? _emailController.text : null,
      'mobile': _mobileController.text.isNotEmpty ? _mobileController.text : null,
      'vehicle_reg_no': _regNoController.text,
      'chassis_no': _chassisNoController.text.isNotEmpty ? _chassisNoController.text : null,
      'issue_date': _issueDate?.toIso8601String().split('T')[0],
      'renewal_date': _renewalDate!.toIso8601String().split('T')[0],
      'door_no': _doorNoController.text.isNotEmpty ? _doorNoController.text : null,
      'street': _streetController.text.isNotEmpty ? _streetController.text : null,
      'district': _districtController.text.isNotEmpty ? _districtController.text : null,
      'state': _stateController.text.isNotEmpty ? _stateController.text : null,
      'country': 'India',
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.isEditing) {
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(widget.existingCustomer!.id)
            .update(customerData);
      } else {
        await FirebaseFirestore.instance
            .collection('customers')
            .add(customerData);
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? 'Customer updated successfully' : 'Customer added successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      // Clear form and stay on same screen
      _clearForm();
      
      setState(() {
        _isSaving = false;
      });

    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Customer' : 'Add Customer'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('CUSTOMER DETAILS', [
                _buildTextField('Customer Name', _nameController, required: true),
                _buildTextField('Email', _emailController),
                _buildTextField('Mobile No', _mobileController),
              ]),
              const SizedBox(height: 20),
              _buildSection('VEHICLE DETAILS', [
                _buildTextField('Registration Number', _regNoController, required: true),
                _buildTextField('Chassis Number', _chassisNoController),
              ]),
              const SizedBox(height: 20),
              _buildSection('INSURANCE DETAILS', [
                _buildDateField('Issue Date', _issueDate, true),
                _buildDateField('Renewal Date', _renewalDate, false, required: true),
              ]),
              const SizedBox(height: 20),
              _buildSection('ADDRESS', [
                _buildTextField('Door No', _doorNoController),
                _buildTextField('Street', _streetController),
                _buildTextField('District', _districtController),
                _buildTextField('State', _stateController),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Text('Country: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('India', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.isEditing ? 'UPDATE CUSTOMER' : 'SAVE CUSTOMER',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, bool isIssueDate,
      {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _selectDate(context, isIssueDate),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date == null
                    ? (required ? '$label *' : label)
                    : '${date.day}/${date.month}/${date.year}',
                style: TextStyle(
                  color: date == null ? Colors.grey : Colors.black,
                ),
              ),
              const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}