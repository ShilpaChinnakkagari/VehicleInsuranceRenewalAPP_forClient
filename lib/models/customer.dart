class Customer {
  final String? id;
  final String name;
  final String? email;
  final String? mobile;
  final String vehicleRegNo;
  final String? chassisNo;
  final DateTime? issueDate;
  final DateTime renewalDate;
  final String? doorNo;
  final String? street;
  final String? district;
  final String? state;
  final String country;
  final String status;
  final DateTime? lastContactedDate;
  final DateTime? createdAt;

  Customer({
    this.id,
    required this.name,
    this.email,
    this.mobile,
    required this.vehicleRegNo,
    this.chassisNo,
    this.issueDate,
    required this.renewalDate,
    this.doorNo,
    this.street,
    this.district,
    this.state,
    this.country = 'India',
    this.status = 'not_contacted',
    this.lastContactedDate,
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      email: json['email'],
      mobile: json['mobile'],
      vehicleRegNo: json['vehicle_reg_no'] ?? '',
      chassisNo: json['chassis_no'],
      issueDate: json['issue_date'] != null ? DateTime.parse(json['issue_date']) : null,
      renewalDate: DateTime.parse(json['renewal_date']),
      doorNo: json['door_no'],
      street: json['street'],
      district: json['district'],
      state: json['state'],
      country: json['country'] ?? 'India',
      status: json['status'] ?? 'not_contacted',
      lastContactedDate: json['last_contacted_date'] != null 
          ? DateTime.parse(json['last_contacted_date']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'vehicle_reg_no': vehicleRegNo,
      'chassis_no': chassisNo,
      'issue_date': issueDate?.toIso8601String().split('T')[0],
      'renewal_date': renewalDate.toIso8601String().split('T')[0],
      'door_no': doorNo,
      'street': street,
      'district': district,
      'state': state,
      'country': country,
      'status': status,
      'last_contacted_date': lastContactedDate?.toIso8601String().split('T')[0],
    };
  }
}