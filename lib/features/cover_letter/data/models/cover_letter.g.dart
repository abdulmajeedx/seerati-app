// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cover_letter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CoverLetterAdapter extends TypeAdapter<CoverLetter> {
  @override
  final int typeId = 6;

  @override
  CoverLetter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CoverLetter(
      id: fields[0] as String,
      language: fields[1] as String,
      senderName: fields[2] as String,
      recipientName: fields[3] as String,
      companyName: fields[4] as String,
      jobTitle: fields[5] as String,
      body: fields[6] as String,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CoverLetter obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.language)
      ..writeByte(2)
      ..write(obj.senderName)
      ..writeByte(3)
      ..write(obj.recipientName)
      ..writeByte(4)
      ..write(obj.companyName)
      ..writeByte(5)
      ..write(obj.jobTitle)
      ..writeByte(6)
      ..write(obj.body)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoverLetterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
