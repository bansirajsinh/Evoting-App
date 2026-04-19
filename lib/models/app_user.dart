class AppUser {
  final String id;
  final String name;
  final String dateOfBirth;
  final String voterId;
  final String aadhaar;
  final String email;
  final String phone;
  final String address;
  final String state;
  final String district;
  final String constituency;

  AppUser({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.voterId,
    required this.aadhaar,
    required this.email,
    required this.phone,
    required this.address,
    required this.state,
    required this.district,
    required this.constituency,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? '',
      voterId: data['voterId'] ?? '',
      aadhaar: data['aadhaar'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      state: data['state'] ?? '',
      district: data['district'] ?? '',
      constituency: data['constituency'] ?? '',
    );
  }

}