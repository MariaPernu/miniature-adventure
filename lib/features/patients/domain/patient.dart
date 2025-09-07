class Patient {
  final String id;              
  final String displayName;     
  final int? birthYear;         
  final bool isTest;            
  final String? notes;        
  final List<String> careTeamUserIds; 

  Patient({
    required this.id,
    required this.displayName,
    this.birthYear,
    required this.isTest,
    this.notes,
    this.careTeamUserIds = const [],
  });

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'birthYear': birthYear,
        'isTest': isTest,
        'notes': notes,
        'careTeamUserIds': careTeamUserIds,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

  factory Patient.fromDoc(String id, Map<String, dynamic> m) => Patient(
        id: id,
        displayName: (m['displayName'] as String?) ?? '',
        birthYear: m['birthYear'] as int?,
        isTest: (m['isTest'] as bool?) ?? false,
        notes: m['notes'] as String?,
        careTeamUserIds: (m['careTeamUserIds'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            const [],
      );
}
