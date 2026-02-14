// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionTemplateAdapter extends TypeAdapter<TransactionTemplate> {
  @override
  final int typeId = 1;

  @override
  TransactionTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionTemplate(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      isIncome: fields[3] as bool,
      category: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionTemplate obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.isIncome)
      ..writeByte(4)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
