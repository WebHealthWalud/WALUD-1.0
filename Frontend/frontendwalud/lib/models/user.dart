// lib/models/user.dart
class User {
  final int? id;
  final String name;
  final String email;
  final String? document;      
  final String? lastName;   
  final String? birthDate;    
  final String? userType;      // paciente o medico
  final String? token;

  User({
    this.id,
    required this.name,        // Solo name y email son required
    required this.email,
    this.document,             
    this.lastName,             
    this.birthDate,            
    this.userType,             
    this.token,               
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      document: json['document'],
      lastName: json['last_name'] ?? json['apellido'],
      birthDate: json['birth_date'],
      userType: json['tipo_usuario'] ?? json['user_type'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'document': document,
      'last_name': lastName,
      'birth_date': birthDate,
      'tipo_usuario': userType,
    };
  }

  String get fullName => '$name ${lastName ?? ''}'.trim();
  bool get isDoctor => userType == 'medico';
  bool get isPatient => userType == 'paciente';
}