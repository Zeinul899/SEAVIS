import 'package:flutter/material.dart';

/// Model untuk foto tangkapan / laporan observasi nelayan
class FishermanPhoto {
  final String id;
  final String title;
  final String category;
  final String location;
  final DateTime timestamp;
  final int reward; // Rp 25.000
  final String status;
  final IconData sampleIcon;
  final Color iconColor;

  const FishermanPhoto({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.timestamp,
    this.reward = 25000,
    this.status = 'Disetujui',
    this.sampleIcon = Icons.set_meal_rounded,
    this.iconColor = const Color(0xFF0284C7),
  });
}

/// Model untuk riwayat penarikan tunai
class WithdrawalRecord {
  final String id;
  final int amount;
  final String channel;
  final String destinationNumber;
  final DateTime timestamp;
  final String status; // 'Berhasil', 'Diproses'

  const WithdrawalRecord({
    required this.id,
    required this.amount,
    required this.channel,
    required this.destinationNumber,
    required this.timestamp,
    this.status = 'Berhasil',
  });
}

/// Model untuk percakapan AI Nelayan
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
