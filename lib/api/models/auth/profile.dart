import '../../json_convertors/serializer.dart';

part 'profile.g.dart';

@CustomSerializerWithToJson
class Profile {
  Profile({
    required this.id,
    required this.email,
    required this.username,
    required this.token,
    required this.phone,
  });

  final int id;
   String? email;
   String? username;
  @JsonKey(name: 'access_token')
  final String token;
  @JsonKey(name: 'phone')
  final String? phone;
  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileToJson(this);
}
