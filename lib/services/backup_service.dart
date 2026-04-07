import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class BackupInfo {
  final DateTime date;
  final int sizeBytes;
  final String path;

  BackupInfo({required this.date, required this.sizeBytes, required this.path});
}

class BackupState {
  final bool isBackingUp;
  final bool isRestoring;
  final double progress;
  final String? lastBackupDate;
  final String? lastBackupSize;
  final String? error;

  const BackupState({
    this.isBackingUp = false,
    this.isRestoring = false,
    this.progress = 0,
    this.lastBackupDate,
    this.lastBackupSize,
    this.error,
  });

  BackupState copyWith({
    bool? isBackingUp,
    bool? isRestoring,
    double? progress,
    String? lastBackupDate,
    String? lastBackupSize,
    String? error,
  }) {
    return BackupState(
      isBackingUp: isBackingUp ?? this.isBackingUp,
      isRestoring: isRestoring ?? this.isRestoring,
      progress: progress ?? this.progress,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      lastBackupSize: lastBackupSize ?? this.lastBackupSize,
      error: error,
    );
  }
}

class BackupService extends StateNotifier<BackupState> {
  static const _prefLastBackupDate = 'backup_last_date';
  static const _prefLastBackupSize = 'backup_last_size';
  static const _prefAutoBackup = 'backup_auto_enabled';
  static const _backupDirName = 'backups';
  static const _dbFileName = 'gymtrack.db';

  BackupService() : super(const BackupState()) {
    _loadLastBackupInfo();
  }

  Future<void> _loadLastBackupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_prefLastBackupDate);
    final sizeStr = prefs.getString(_prefLastBackupSize);
    state = state.copyWith(
      lastBackupDate: dateStr,
      lastBackupSize: sizeStr,
    );
  }

  Future<Directory> _getBackupDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(appDir.path, _backupDirName));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  Future<File> _getDbFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return File(p.join(dbFolder.path, _dbFileName));
  }

  /// Create a backup of the database.
  /// Returns the backup file path on success.
  Future<String?> createBackup({bool isAutoBackup = false}) async {
    if (state.isBackingUp || state.isRestoring) return null;

    state = state.copyWith(isBackingUp: true, progress: 0, error: null);

    try {
      final dbFile = await _getDbFile();
      if (!await dbFile.exists()) {
        state = state.copyWith(isBackingUp: false, error: 'Database not found');
        return null;
      }

      state = state.copyWith(progress: 0.2);

      final backupDir = await _getBackupDir();

      // Delete previous auto-backups (keep only the latest)
      if (isAutoBackup) {
        await _cleanOldBackups(backupDir);
      }

      state = state.copyWith(progress: 0.4);

      // Copy database file
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final backupFileName = 'gymtrack_backup_$timestamp.db';
      final backupFile = File(p.join(backupDir.path, backupFileName));

      // Also copy avatar if exists
      final appDir = await getApplicationDocumentsDirectory();
      final avatarFile = File(p.join(appDir.path, 'profile_avatar.jpg'));

      await dbFile.copy(backupFile.path);
      state = state.copyWith(progress: 0.7);

      // Copy avatar alongside backup
      if (await avatarFile.exists()) {
        final avatarBackup = File(p.join(backupDir.path, 'profile_avatar_$timestamp.jpg'));
        await avatarFile.copy(avatarBackup.path);
      }

      state = state.copyWith(progress: 0.9);

      // Save backup metadata
      final sizeBytes = await backupFile.length();
      final sizeStr = _formatFileSize(sizeBytes);
      final dateStr = DateTime.now().toIso8601String();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLastBackupDate, dateStr);
      await prefs.setString(_prefLastBackupSize, sizeStr);

      state = state.copyWith(
        isBackingUp: false,
        progress: 1.0,
        lastBackupDate: dateStr,
        lastBackupSize: sizeStr,
      );

      return backupFile.path;
    } catch (e) {
      state = state.copyWith(
        isBackingUp: false,
        progress: 0,
        error: 'Backup failed: $e',
      );
      return null;
    }
  }

  /// Export the latest backup via share sheet
  Future<void> exportBackup() async {
    final backupDir = await _getBackupDir();
    final files = await backupDir.list().toList();
    final dbFiles = files
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList();

    if (dbFiles.isEmpty) {
      // Create a fresh backup first
      final path = await createBackup();
      if (path == null) return;
      await Share.shareXFiles([XFile(path)]);
      return;
    }

    // Sort by modification date, share the latest
    dbFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    final latestBackup = dbFiles.first;

    // Also include avatar if exists
    final avatarFiles = files
        .whereType<File>()
        .where((f) => f.path.endsWith('.jpg'))
        .toList();
    avatarFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    final filesToShare = <XFile>[XFile(latestBackup.path)];
    if (avatarFiles.isNotEmpty) {
      filesToShare.add(XFile(avatarFiles.first.path));
    }

    await Share.shareXFiles(filesToShare);
  }

  /// Restore from a backup file path
  Future<bool> restoreFromFile(String backupFilePath) async {
    if (state.isBackingUp || state.isRestoring) return false;

    state = state.copyWith(isRestoring: true, progress: 0, error: null);

    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        state = state.copyWith(isRestoring: false, error: 'Backup file not found');
        return false;
      }

      state = state.copyWith(progress: 0.3);

      final dbFile = await _getDbFile();

      // Create a safety backup before restoring
      if (await dbFile.exists()) {
        final safetyBackup = File('${dbFile.path}.pre_restore');
        await dbFile.copy(safetyBackup.path);
      }

      state = state.copyWith(progress: 0.6);

      // Copy backup over the existing database
      await backupFile.copy(dbFile.path);

      state = state.copyWith(progress: 0.9);

      // Check if there's an avatar in the same directory
      final backupDir = p.dirname(backupFilePath);
      final backupBasename = p.basenameWithoutExtension(backupFilePath);
      final timestamp = backupBasename.replaceFirst('gymtrack_backup_', '');
      final avatarBackup = File(p.join(backupDir, 'profile_avatar_$timestamp.jpg'));
      if (await avatarBackup.exists()) {
        final appDir = await getApplicationDocumentsDirectory();
        final avatarDest = File(p.join(appDir.path, 'profile_avatar.jpg'));
        await avatarBackup.copy(avatarDest.path);
      }

      state = state.copyWith(isRestoring: false, progress: 1.0);
      return true;
    } catch (e) {
      state = state.copyWith(
        isRestoring: false,
        progress: 0,
        error: 'Restore failed: $e',
      );
      return false;
    }
  }

  /// Get list of available local backups
  Future<List<BackupInfo>> getLocalBackups() async {
    final backupDir = await _getBackupDir();
    if (!await backupDir.exists()) return [];

    final files = await backupDir.list().toList();
    final dbFiles = files
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList();

    dbFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return dbFiles.map((f) {
      return BackupInfo(
        date: f.lastModifiedSync(),
        sizeBytes: f.lengthSync(),
        path: f.path,
      );
    }).toList();
  }

  /// Check if auto-backup should run (once per day)
  Future<void> checkAndRunAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final autoEnabled = prefs.getBool(_prefAutoBackup) ?? true; // enabled by default
    if (!autoEnabled) return;

    final lastDateStr = prefs.getString(_prefLastBackupDate);
    if (lastDateStr != null) {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null) {
        final now = DateTime.now();
        // Skip if already backed up today
        if (lastDate.year == now.year &&
            lastDate.month == now.month &&
            lastDate.day == now.day) {
          return;
        }
      }
    }

    // Run auto-backup
    await createBackup(isAutoBackup: true);
  }

  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefAutoBackup) ?? true;
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAutoBackup, enabled);
  }

  /// Remove old auto-backups, keeping only the latest one
  Future<void> _cleanOldBackups(Directory backupDir) async {
    final files = await backupDir.list().toList();
    final dbFiles = files
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList();

    if (dbFiles.length <= 1) return;

    // Sort newest first, delete all but the newest
    dbFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    for (var i = 1; i < dbFiles.length; i++) {
      try {
        await dbFiles[i].delete();
        // Also delete associated avatar backup
        final basename = p.basenameWithoutExtension(dbFiles[i].path);
        final timestamp = basename.replaceFirst('gymtrack_backup_', '');
        final avatarFile = File(p.join(backupDir.path, 'profile_avatar_$timestamp.jpg'));
        if (await avatarFile.exists()) {
          await avatarFile.delete();
        }
      } catch (_) {}
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

final backupServiceProvider = StateNotifierProvider<BackupService, BackupState>((ref) {
  return BackupService();
});
