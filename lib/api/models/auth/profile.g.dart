// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
  id: const IntParser().fromJson(json['id']),
  email: json['email'] as String?,
  username: json['username'] as String?,
  token: json['access_token'] as String,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
  'id': const IntParser().toJson(instance.id),
  'email': instance.email,
  'username': instance.username,
  'access_token': instance.token,
  'phone': instance.phone,
};
