import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../services/storage_service.dart';
import '../services/update_service.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/botanic_vector_decor.dart';
import '../widgets/shimmer_loading.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  final TextEditingController _ipController = TextEditingController(
    text: StorageService.defaultIp,
  );

  // Threshold values initialized with defaults
  double _tempMin = StorageService.defaultTempMin;
  double _tempMax = StorageService.defaultTempMax;
  double _humidityMin = StorageService.defaultHumidityMin;
  double _humidityMax = StorageService.defaultHumidityMax;
  double _gasMax = StorageService.defaultGasMax;
  String _userName = 'Pengguna Farmasi';
  String _userEmail = 'user@smartpharma.id';
  String _authProvider = 'Smart Pharma';
  String _userRole = 'operator';
  bool _isOperator = true;
  int? _currentUserId;
  String _userAvatar = '';
  bool _isLoading = true;
  bool _isCheckingUpdate = false;

  ImageProvider? _getAvatarImage(String base64Str) {
    if (base64Str.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(base64Str));
    } catch (_) {
      return null;
    }
  }

  final BiometricService _biometricService = BiometricService();
  bool _isBiometricSupported = false;
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final results = await Future.wait([
        _storageService.getServerIp(),
        _storageService.getThresholds(),
        _storageService.getUserProfile(),
        _storageService.isBiometricEnabled(),
        _biometricService.isDeviceSupported().timeout(
          const Duration(milliseconds: 500),
          onTimeout: () => false,
        ),
      ]);

      if (!mounted) return;

      final ip = results[0] as String;
      final thresholds = results[1] as Map<String, double>;
      final profile = results[2] as Map<String, String>;
      final isBioEnabled = results[3] as bool;
      final isBioSupported = results[4] as bool;
      final role = await _storageService.getUserRole();
      final uid = await _storageService.getUserId();

      setState(() {
        _ipController.text = ip;
        _userName = profile['name'] ?? 'Pengguna Farmasi';
        _userEmail = profile['email'] ?? 'user@smartpharma.id';
        _userRole = role;
        _isOperator = role == 'operator' || role == 'admin';
        _currentUserId = uid;
        _authProvider = profile['provider'] ?? 'Smart Pharma';
        _userAvatar = profile['avatar'] ?? '';
        _isBiometricEnabled = isBioEnabled;
        _isBiometricSupported = isBioSupported;
        _tempMin = (thresholds['tempMin'] ?? StorageService.defaultTempMin)
            .clamp(-20.0, 30.0);
        _tempMax = (thresholds['tempMax'] ?? StorageService.defaultTempMax)
            .clamp(-10.0, 50.0);
        _humidityMin =
            (thresholds['humidityMin'] ?? StorageService.defaultHumidityMin)
                .clamp(0.0, 80.0);
        _humidityMax =
            (thresholds['humidityMax'] ?? StorageService.defaultHumidityMax)
                .clamp(20.0, 100.0);
        _gasMax = (thresholds['gasMax'] ?? StorageService.defaultGasMax).clamp(
          0.0,
          500.0,
        );
        _isLoading = false;
      });

      _apiService.fetchMyProfile().then((myProfile) {
        if (mounted) {
          final r = myProfile['role']?.toString().toLowerCase() ?? _userRole;
          setState(() {
            _userRole = r;
            _isOperator = r == 'operator' || r == 'admin';
            _currentUserId = (myProfile['id'] as num?)?.toInt() ?? _currentUserId;
            _authProvider = 'Database MySQL ($r)';
          });
        }
      }).catchError((_) {});
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(BuildContext ctx, String message, {bool isError = false}) {
    if (isError) {
      AppToast.error(ctx, message);
    } else {
      AppToast.success(ctx, message);
    }
  }

  void _showManageUsersModal() {
    List<Map<String, dynamic>> users = [];
    bool loading = true;
    String? error;
    String searchQuery = '';
    final Set<int> updatingIds = {};
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void fetchUserList() async {
            setModalState(() {
              loading = true;
              error = null;
            });
            try {
              final result = await _apiService.fetchUsers();
              if (sheetCtx.mounted) {
                setModalState(() {
                  users = result;
                  loading = false;
                });
              }
            } catch (e) {
              if (sheetCtx.mounted) {
                setModalState(() {
                  error = e.toString().replaceAll('Exception: ', '');
                  loading = false;
                });
              }
            }
          }

          if (loading && error == null && users.isEmpty) {
            fetchUserList();
          }

          final filteredUsers = users.where((u) {
            final q = searchQuery.toLowerCase().trim();
            if (q.isEmpty) return true;
            final name = (u['full_name'] ?? u['name'] ?? '').toString().toLowerCase();
            final usr = (u['username'] ?? '').toString().toLowerCase();
            final em = (u['email'] ?? '').toString().toLowerCase();
            return name.contains(q) || usr.contains(q) || em.contains(q);
          }).toList();

          final int totalOp = users.where((u) => (u['role'] ?? '').toString().toLowerCase() == 'operator').length;
          final int totalReg = users.where((u) => (u['role'] ?? '').toString().toLowerCase() != 'operator').length;

          return ModalSheetTopDecor(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md + 4,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.containerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.pharmaNavy.withAlpha(20),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(
                            Icons.manage_accounts_rounded,
                            color: AppColors.pharmaNavy,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kelola Pengguna & Akses',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.pharmaNavy,
                                ),
                              ),
                              Text(
                                'Atur hak staf Operator dan User',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.pharmaNavy),
                          tooltip: 'Segarkan data',
                          onPressed: loading ? null : fetchUserList,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Summary counts
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.containerLow,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Total Akun', users.length.toString(), AppColors.textDark),
                          Container(width: 1, height: 24, color: AppColors.containerHigh),
                          _buildStatItem('Operator', totalOp.toString(), AppColors.pharmaNavy),
                          Container(width: 1, height: 24, color: AppColors.containerHigh),
                          _buildStatItem('User Biasa', totalReg.toString(), AppColors.textMuted),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    // Search bar
                    TextField(
                      controller: searchCtrl,
                      onChanged: (val) => setModalState(() => searchQuery = val),
                      style: AppTypography.body.copyWith(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cari nama, username, atau email...',
                        hintStyle: AppTypography.caption,
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  searchCtrl.clear();
                                  setModalState(() => searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          borderSide: const BorderSide(color: AppColors.containerLow),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          borderSide: const BorderSide(color: AppColors.containerLow),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          borderSide: const BorderSide(color: AppColors.pharmaNavy, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    Expanded(
                      child: loading
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: AppColors.pharmaNavy, strokeWidth: 2.5),
                                  SizedBox(height: 12),
                                  Text('Memuat daftar pengguna...', style: AppTypography.caption),
                                ],
                              ),
                            )
                          : error != null
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: AppColors.alertRed, size: 36),
                                      const SizedBox(height: 8),
                                      Text(error!, textAlign: TextAlign.center, style: AppTypography.caption),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: fetchUserList,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.pharmaNavy,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                          ),
                                        ),
                                        child: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                )
                              : filteredUsers.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Tidak ada pengguna ditemukan.',
                                        style: AppTypography.caption,
                                      ),
                                    )
                                  : ListView.separated(
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: filteredUsers.length,
                                      separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.sm),
                                      itemBuilder: (listCtx, idx) {
                                        final u = filteredUsers[idx];
                                        final uId = (u['id'] as num?)?.toInt() ?? 0;
                                        final uUsername = u['username']?.toString() ?? '';
                                        final uFullName = (u['full_name'] ?? u['name'] ?? uUsername).toString();
                                        final uEmail = u['email']?.toString() ?? '';
                                        final uRole = (u['role']?.toString() ?? 'user').toLowerCase();
                                        final isTargetOp = uRole == 'operator';
                                        final isSelf = (_currentUserId != null && uId == _currentUserId) ||
                                            uUsername.toLowerCase() == _userName.toLowerCase();
                                        final isUpdating = updatingIds.contains(uId);

                                        return Container(
                                          padding: const EdgeInsets.all(AppSpacing.md),
                                          decoration: BoxDecoration(
                                            color: isSelf ? AppColors.containerLow.withAlpha(80) : AppColors.cardWhite,
                                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                            border: Border.all(
                                              color: isSelf ? AppColors.pharmaNavy.withAlpha(50) : AppColors.containerLow,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: isTargetOp
                                                    ? AppColors.pharmaNavy.withAlpha(20)
                                                    : AppColors.containerHigh,
                                                child: Text(
                                                  uFullName.isNotEmpty ? uFullName.substring(0, 1).toUpperCase() : 'U',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                    color: isTargetOp ? AppColors.pharmaNavy : AppColors.textDark,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: AppSpacing.md),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            uFullName,
                                                            style: const TextStyle(
                                                              fontSize: 13.5,
                                                              fontWeight: FontWeight.bold,
                                                              color: AppColors.textDark,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        if (isSelf) ...[
                                                          const SizedBox(width: 6),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.pharmaNavy.withAlpha(20),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: const Text(
                                                              'Anda',
                                                              style: TextStyle(
                                                                fontSize: 9.5,
                                                                fontWeight: FontWeight.w700,
                                                                color: AppColors.pharmaNavy,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '@$uUsername • $uEmail',
                                                      style: AppTypography.caption.copyWith(fontSize: 11),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: AppSpacing.sm),
                                              if (isUpdating)
                                                const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppColors.pharmaNavy,
                                                  ),
                                                )
                                              else if (isSelf)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.pharmaNavy,
                                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                                  ),
                                                  child: const Text(
                                                    'OPERATOR',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                )
                                              else
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Switch(
                                                          value: isTargetOp,
                                                          activeThumbColor: AppColors.pharmaNavy,
                                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                          onChanged: (bool makeOp) async {
                                                            final targetRole = makeOp ? 'operator' : 'user';
                                                            setModalState(() => updatingIds.add(uId));
                                                            try {
                                                              await _apiService.updateUserRole(
                                                                userId: uId,
                                                                role: targetRole,
                                                              );
                                                              setModalState(() {
                                                                u['role'] = targetRole;
                                                                updatingIds.remove(uId);
                                                              });
                                                              if (mounted) {
                                                                _showSnack(
                                                                  context,
                                                                  'Role $uUsername diubah menjadi ${targetRole.toUpperCase()}',
                                                                );
                                                              }
                                                            } catch (err) {
                                                              setModalState(() => updatingIds.remove(uId));
                                                              if (mounted) {
                                                                _showSnack(
                                                                  context,
                                                                  err.toString().replaceAll('Exception: ', ''),
                                                                  isError: true,
                                                                );
                                                              }
                                                            }
                                                          },
                                                        ),
                                                        Text(
                                                          isTargetOp ? 'Operator' : 'User',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w700,
                                                            color: isTargetOp ? AppColors.pharmaNavy : AppColors.textMuted,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete_outline_rounded,
                                                        color: AppColors.alertRed,
                                                        size: 20,
                                                      ),
                                                      tooltip: 'Hapus Pengguna',
                                                      onPressed: () {
                                                        _confirmDeleteUser(
                                                          sheetCtx,
                                                          userId: uId,
                                                          username: uUsername,
                                                          fullName: uFullName,
                                                          onSuccess: () {
                                                            setModalState(() {
                                                              users.removeWhere((item) => item['id'] == uId);
                                                            });
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  void _confirmDeleteUser(
    BuildContext parentCtx, {
    required int userId,
    required String username,
    required String fullName,
    required VoidCallback onSuccess,
  }) {
    showDialog(
      context: parentCtx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.alertRed.withAlpha(20),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: AppColors.alertRed, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            const Text(
              'Hapus Pengguna',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun @$username ($fullName)? Tindakan ini tidak dapat dibatalkan.',
          style: AppTypography.body.copyWith(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await _apiService.deleteUser(userId);
                onSuccess();
                if (mounted) {
                  _showSnack(context, 'Pengguna @$username berhasil dihapus');
                }
              } catch (e) {
                if (mounted) {
                  _showSnack(context, e.toString().replaceAll('Exception: ', ''), isError: true);
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _userEmail);
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    String tempAvatar = _userAvatar;
    int activeTab = 0;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSavingProfile = false;
    bool isSavingPassword = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> pickAvatar(ImageSource source) async {
            try {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: source,
                maxWidth: 512,
                maxHeight: 512,
                imageQuality: 80,
              );
              if (picked != null) {
                final bytes = await picked.readAsBytes();
                setModalState(() {
                  tempAvatar = base64Encode(bytes);
                });
              }
            } catch (e) {
              if (mounted) {
                _showSnack(context, 'Gagal memilih foto: $e', isError: true);
              }
            }
          }

          void showAvatarSourcePicker() {
            showModalBottomSheet(
              context: ctx,
              backgroundColor: AppColors.cardWhite,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (pickerCtx) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.containerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pilih Foto Profil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pharmaNavy,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.pharmaNavy.withAlpha(20),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(Icons.photo_library_rounded, color: AppColors.pharmaNavy, size: 20),
                        ),
                        title: const Text('Buka Galeri Foto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        subtitle: const Text('Pilih foto dari penyimpanan perangkat', style: TextStyle(fontSize: 11)),
                        onTap: () {
                          Navigator.pop(pickerCtx);
                          pickAvatar(ImageSource.gallery);
                        },
                      ),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.pharmaTeal.withAlpha(20),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: AppColors.pharmaTeal, size: 20),
                        ),
                        title: const Text('Gunakan Kamera', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        subtitle: const Text('Ambil foto langsung dari kamera', style: TextStyle(fontSize: 11)),
                        onTap: () {
                          Navigator.pop(pickerCtx);
                          pickAvatar(ImageSource.camera);
                        },
                      ),
                      if (tempAvatar.isNotEmpty) ...[
                        const Divider(height: 16),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.alertRed.withAlpha(20),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: AppColors.alertRed, size: 20),
                          ),
                          title: const Text('Hapus Foto Profil', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.alertRed)),
                          onTap: () {
                            Navigator.pop(pickerCtx);
                            setModalState(() => tempAvatar = '');
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }

          return ModalSheetTopDecor(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md + 4,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.containerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.pharmaNavy.withAlpha(20),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Icon(
                            activeTab == 0 ? Icons.person_outline_rounded : Icons.lock_outline_rounded,
                            color: AppColors.pharmaNavy,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            activeTab == 0 ? 'Edit Profil Pengguna' : 'Ubah Kata Sandi',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.pharmaNavy,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: AppColors.containerLow, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeTab = 0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: activeTab == 0 ? AppColors.pharmaNavy : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Text(
                                  'Informasi Akun',
                                  style: TextStyle(
                                    color: activeTab == 0 ? Colors.white : AppColors.textMuted,
                                    fontWeight: activeTab == 0 ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeTab = 1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: activeTab == 1 ? AppColors.pharmaNavy : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Text(
                                  'Ganti Password',
                                  style: TextStyle(
                                    color: activeTab == 1 ? Colors.white : AppColors.textMuted,
                                    fontWeight: activeTab == 1 ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md + 4),

                    if (activeTab == 0) ...[
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: showAvatarSourcePicker,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.pharmaNavy.withAlpha(50), width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x140E555A),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 42,
                                  backgroundColor: AppColors.pharmaNavy.withAlpha(24),
                                  backgroundImage: _getAvatarImage(tempAvatar),
                                  child: tempAvatar.isEmpty
                                      ? Text(
                                          nameCtrl.text.isNotEmpty ? nameCtrl.text[0].toUpperCase() : 'A',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.pharmaNavy,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: showAvatarSourcePicker,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.pharmaNavy,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: TextButton.icon(
                          onPressed: showAvatarSourcePicker,
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text('Ganti Foto Profil', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(foregroundColor: AppColors.pharmaNavy),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      const Text(
                        'Nama Pengguna',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Nama lengkap / username',
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          filled: true,
                          fillColor: AppColors.inputBg,
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: const BorderSide(color: AppColors.containerHigh),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Alamat Email',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'email@domain.com',
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          filled: true,
                          fillColor: AppColors.inputBg,
                          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: const BorderSide(color: AppColors.containerHigh),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textMuted,
                                side: const BorderSide(color: AppColors.containerHigh),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                              ),
                              onPressed: () => Navigator.pop(sheetCtx),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.pharmaNavy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                              ),
                              onPressed: isSavingProfile
                                  ? null
                                  : () async {
                                      final newName = nameCtrl.text.trim();
                                      final newEmail = emailCtrl.text.trim();
                                      if (newName.isEmpty || newEmail.isEmpty) {
                                        return;
                                      }
                                      setModalState(() => isSavingProfile = true);
                                      try {
                                        await ApiService().updateProfile(
                                          fullName: newName,
                                          email: newEmail,
                                        );
                                      } catch (_) {}

                                      await _storageService.saveUserProfile(
                                        name: newName,
                                        email: newEmail,
                                        provider: _authProvider,
                                        avatar: tempAvatar,
                                      );

                                      if (!mounted) return;
                                      setState(() {
                                        _userName = newName;
                                        _userEmail = newEmail;
                                        _userAvatar = tempAvatar;
                                      });
                                      if (sheetCtx.mounted) {
                                        Navigator.pop(sheetCtx);
                                      }
                                      _showSnack(context, 'Profil & foto berhasil diperbarui');
                                    },
                              child: isSavingProfile
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Simpan Profil',
                                      style: TextStyle(fontWeight: FontWeight.w800),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.pharmaNavy.withAlpha(12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.pharmaNavy.withAlpha(30)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppColors.pharmaNavy, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Kata sandi baru minimal 6 karakter. Pastikan sandi aman & rahasia.',
                                style: TextStyle(fontSize: 11.5, color: AppColors.pharmaNavy, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      const Text(
                        'Password Saat Ini',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: oldPasswordCtrl,
                        obscureText: obscureOld,
                        decoration: InputDecoration(
                          hintText: 'Masukkan kata sandi lama',
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          filled: true,
                          fillColor: AppColors.inputBg,
                          prefixIcon: const Icon(Icons.lock_clock_outlined, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                            onPressed: () => setModalState(() => obscureOld = !obscureOld),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: const BorderSide(color: AppColors.containerHigh),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      const Text(
                        'Password Baru',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: newPasswordCtrl,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          hintText: 'Minimal 6 karakter',
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          filled: true,
                          fillColor: AppColors.inputBg,
                          prefixIcon: const Icon(Icons.lock_reset_rounded, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                            onPressed: () => setModalState(() => obscureNew = !obscureNew),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: const BorderSide(color: AppColors.containerHigh),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      const Text(
                        'Konfirmasi Password Baru',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: confirmPasswordCtrl,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          hintText: 'Ulangi kata sandi baru',
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          filled: true,
                          fillColor: AppColors.inputBg,
                          prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                            onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: const BorderSide(color: AppColors.containerHigh),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textMuted,
                                side: const BorderSide(color: AppColors.containerHigh),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                              ),
                              onPressed: () => Navigator.pop(sheetCtx),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.pharmaNavy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                              ),
                              onPressed: isSavingPassword
                                  ? null
                                  : () async {
                                      final oldP = oldPasswordCtrl.text;
                                      final newP = newPasswordCtrl.text;
                                      final confP = confirmPasswordCtrl.text;

                                      if (oldP.isEmpty) {
                                        _showSnack(context, 'Password lama tidak boleh kosong', isError: true);
                                        return;
                                      }
                                      if (newP.length < 6) {
                                        _showSnack(context, 'Password baru minimal 6 karakter', isError: true);
                                        return;
                                      }
                                      if (newP != confP) {
                                        _showSnack(context, 'Konfirmasi password baru tidak cocok', isError: true);
                                        return;
                                      }

                                      setModalState(() => isSavingPassword = true);
                                      try {
                                        await ApiService().changePassword(
                                          oldPassword: oldP,
                                          newPassword: newP,
                                        );
                                        if (sheetCtx.mounted) {
                                          Navigator.pop(sheetCtx);
                                        }
                                        if (!mounted) return;
                                        _showSnack(context, 'Password berhasil diperbarui di database');
                                      } catch (e) {
                                        setModalState(() => isSavingPassword = false);
                                        if (!mounted) return;
                                        final msg = e.toString().replaceAll('Exception: ', '');
                                        _showSnack(context, msg, isError: true);
                                      }
                                    },
                              child: isSavingPassword
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Perbarui Sandi',
                                      style: TextStyle(fontWeight: FontWeight.w800),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final authenticated = await _biometricService.authenticate(
        reason: 'Pindai sidik jari untuk mengaktifkan login biometrik',
      );
      if (!authenticated) {
        if (mounted) {
          AppToast.error(context, 'Verifikasi sidik jari tidak cocok / dibatalkan');
        }
        return;
      }
    }

    await _storageService.setBiometricEnabled(value);
    if (value) {
      await _storageService.storeBiometricToken();
    } else {
      await _storageService.removeBiometricToken();
    }
    if (mounted) {
      setState(() => _isBiometricEnabled = value);
      AppToast.info(
        context,
        value ? 'Login biometrik aktif' : 'Login biometrik dinonaktifkan',
      );
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  // ==========================================
  // PROGRESSIVE SETTINGS MODALS (Design Guide)
  // ==========================================

  void _showThresholdsModal() {
    double tempMin = _tempMin;
    double tempMax = _tempMax;
    double humidityMin = _humidityMin;
    double humidityMax = _humidityMax;
    double gasMax = _gasMax;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Widget buildModalSlider({
            required String label,
            required String unit,
            required double value,
            required double min,
            required double max,
            required ValueChanged<double> onChanged,
            required IconData icon,
          }) {
            final double safeMin = min;
            final double safeMax = max > min ? max : min + 1.0;
            final double safeValue = value.clamp(safeMin, safeMax);
            int divisions = ((safeMax - safeMin) * 2).round();
            if (divisions <= 0) divisions = 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18, color: AppColors.pharmaNavy),
                        const SizedBox(width: AppSpacing.xs + 2),
                        Text(label, style: AppTypography.caption),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 2,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pharmaNavy.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        '${safeValue.toStringAsFixed(1)} $unit',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.pharmaNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 6.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 18.0),
                    activeTrackColor: AppColors.pharmaNavy,
                    inactiveTrackColor: AppColors.containerLow,
                    thumbColor: AppColors.pharmaNavy,
                    overlayColor: AppColors.pharmaNavy.withAlpha(51),
                  ),
                  child: Slider(
                    min: safeMin,
                    max: safeMax,
                    divisions: divisions,
                    value: safeValue,
                    onChanged: (val) {
                      setModalState(() {
                        onChanged(val);
                      });
                    },
                  ),
                ),
              ],
            );
          }

          return ModalSheetTopDecor(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md + 4,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.containerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.pharmaNavy.withAlpha(20),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: AppColors.pharmaNavy,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ambang Batas Sensor',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.pharmaNavy,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Batas deteksi anomali suhu, kelembapan, & gas',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    buildModalSlider(
                      label: 'Suhu Minimum',
                      unit: '°C',
                      value: tempMin,
                      min: -20,
                      max: 30,
                      onChanged: (v) => tempMin = v,
                      icon: Icons.arrow_downward,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    buildModalSlider(
                      label: 'Suhu Maximum',
                      unit: '°C',
                      value: tempMax,
                      min: -10,
                      max: 50,
                      onChanged: (v) => tempMax = v,
                      icon: Icons.arrow_upward,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    buildModalSlider(
                      label: 'Kelembapan Minimum',
                      unit: '%',
                      value: humidityMin,
                      min: 0,
                      max: 80,
                      onChanged: (v) => humidityMin = v,
                      icon: Icons.water_drop_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    buildModalSlider(
                      label: 'Kelembapan Maximum',
                      unit: '%',
                      value: humidityMax,
                      min: 20,
                      max: 100,
                      onChanged: (v) => humidityMax = v,
                      icon: Icons.water_drop,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    buildModalSlider(
                      label: 'Kadar Gas Maximum',
                      unit: 'PPM',
                      value: gasMax,
                      min: 0,
                      max: 500,
                      onChanged: (v) => gasMax = v,
                      icon: Icons.cloud,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textDark,
                              side: const BorderSide(color: AppColors.containerHigh),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(sheetCtx),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.pharmaNavy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () async {
                              if (tempMin >= tempMax) {
                                AppToast.error(context, 'Suhu min harus kurang dari max');
                                return;
                              }
                              if (humidityMin >= humidityMax) {
                                AppToast.error(context, 'Kelembapan min harus kurang dari max');
                                return;
                              }
                              setState(() {
                                _tempMin = tempMin;
                                _tempMax = tempMax;
                                _humidityMin = humidityMin;
                                _humidityMax = humidityMax;
                                _gasMax = gasMax;
                              });
                              await _storageService.saveThresholds(
                                tempMin: tempMin,
                                tempMax: tempMax,
                                humidityMin: humidityMin,
                                humidityMax: humidityMax,
                                gasMax: gasMax,
                              );
                              if (!mounted) return;
                              context.read<SensorProvider>().updateThresholds(
                                tempMin: tempMin,
                                tempMax: tempMax,
                                humidityMin: humidityMin,
                                humidityMax: humidityMax,
                                gasMax: gasMax,
                              );
                              if (sheetCtx.mounted) {
                                Navigator.pop(sheetCtx);
                              }
                              AppToast.success(context, 'Batas threshold berhasil disimpan');
                            },
                            child: const Text(
                              'Simpan Ambang Batas',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNetworkConfigModal() {
    final ipCtrl = TextEditingController(text: _ipController.text);
    bool isSavingIp = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return ModalSheetTopDecor(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md + 4,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.containerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.pharmaNavy.withAlpha(20),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Icon(
                          Icons.dns_rounded,
                          color: AppColors.pharmaNavy,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Server & Jaringan Gudang',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.pharmaNavy,
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              'Alamat IP Host Telemetri & MQTT Broker',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'IP Server Host',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: ipCtrl,
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      hintText: '192.168.1.100',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      prefixIcon: const Icon(
                        Icons.wifi_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.restore, size: 20),
                        tooltip: 'Reset Default',
                        onPressed: () {
                          ipCtrl.text = StorageService.defaultIp;
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: const BorderSide(color: AppColors.containerHigh),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: const BorderSide(color: AppColors.containerHigh),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: const BorderSide(color: AppColors.pharmaNavy, width: 1.5),
                      ),
                      filled: true,
                      fillColor: AppColors.inputBg,
                      helperText: 'Format IPv4 standar: contoh 192.168.33.10',
                      helperStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textDark,
                            side: const BorderSide(color: AppColors.containerHigh),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(sheetCtx),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.pharmaNavy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: isSavingIp
                              ? null
                              : () async {
                                  final newIp = ipCtrl.text.trim();
                                  if (newIp.isEmpty) {
                                    AppToast.error(context, 'IP Server tidak boleh kosong');
                                    return;
                                  }
                                  setModalState(() => isSavingIp = true);
                                  await _storageService.saveServerIp(newIp);
                                  if (!mounted) return;
                                  setState(() {
                                    _ipController.text = newIp;
                                  });
                                  if (sheetCtx.mounted) {
                                    Navigator.pop(sheetCtx);
                                  }
                                  AppToast.success(context, 'Konfigurasi IP disimpan: $newIp');
                                },
                          child: isSavingIp
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Simpan IP',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showServicesModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => ModalSheetTopDecor(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md + 4,
            AppSpacing.lg,
            AppSpacing.lg + 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.containerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.pharmaNavy.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      color: AppColors.pharmaNavy,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Layanan IoT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pharmaNavy,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Protokol komunikasi broker MQTT & REST API',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildServiceStatusTile(
                icon: Icons.router_outlined,
                name: 'Broker MQTT Mosquitto',
                details: 'Host: ${_ipController.text} • Port: 1883 • Topic: pharma/sensor',
                status: 'Aktif',
                isOnline: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildServiceStatusTile(
                icon: Icons.api_rounded,
                name: 'Backend REST API FastAPI',
                details: 'Host: ${_ipController.text} • Port: 8001 • Endpoint: /sensor',
                status: 'Aktif',
                isOnline: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildServiceStatusTile(
                icon: Icons.storage_rounded,
                name: 'Database MySQL Telemetri',
                details: 'Host: ${_ipController.text} • Port: 3306 • DB: pharma_db',
                status: 'Terhubung',
                isOnline: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceStatusTile({
    required IconData icon,
    required String name,
    required String details,
    required String status,
    required bool isOnline,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.containerLow, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.cardWhite,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.pharmaNavy, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isOnline ? AppColors.activeGreen : AppColors.alertRed).withAlpha(22),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              '● $status',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isOnline ? AppColors.activeGreen : AppColors.alertRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => ModalSheetTopDecor(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md + 4,
            AppSpacing.lg,
            AppSpacing.lg + 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.containerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const PharmaBrandStamp(),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Pharma Medic IoT Monitoring',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pharmaNavy,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Versi 1.0.6 (Build +7)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.containerLow),
                ),
                child: const Text(
                  'Aplikasi monitoring lingkungan penyimpanan vaksin (Cold Storage 2–8°C) dan ruang steril (Cleanroom 15–25°C) terintegrasi dengan telemetri IoT, deteksi gas, sterilisasi UV-C, dan Digital Twin 3D.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: AppColors.textDark, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        backgroundColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.alertRed.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: AppColors.alertRed,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Keluar dari Aplikasi?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sesi login Anda akan diakhiri. Anda perlu memasukkan kredensial lagi untuk mengakses dashboard pemantauan gudang.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.containerHigh),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.alertRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      await StorageService().clearSession();
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('Ya, Keluar', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STRUCTURED GROUP UI BUILDERS (Design Guide)
  // ==========================================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildGroupCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.containerLow, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100E555A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    String? description,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + 2,
              vertical: AppSpacing.md - 3,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.containerLow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.pharmaNavy,
                    size: 19,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 1.5),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 52,
            endIndent: 16,
            color: AppColors.containerLow,
          ),
      ],
    );
  }

  Widget _buildHeroProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.containerLow, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140E555A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: BotanicVectorCardWatermark(
        size: 110,
        opacity: 0.045,
        alignment: Alignment.topRight,
        child: InkWell(
          onTap: _showEditProfileDialog,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md + 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.pharmaNavy.withAlpha(24),
                  backgroundImage: _getAvatarImage(_userAvatar),
                  child: _userAvatar.isEmpty
                      ? Text(
                          _userName.isNotEmpty
                              ? _userName.substring(0, 1).toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pharmaNavy,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: AppTypography.subtitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _userEmail,
                        style: AppTypography.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _isOperator ? AppColors.pharmaNavy : AppColors.containerHigh,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              _userRole.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: _isOperator ? Colors.white : AppColors.textDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _authProvider,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.pharmaNavy.withAlpha(180),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.pharmaNavy,
                  tooltip: 'Edit Profil',
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.containerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm + 4,
        bottom: AppSpacing.sm,
      ),
      children: [
        // 1. HIGHLIGHT CRITICAL SETTINGS: Top Profile Hero Card (Slide 03)
        _buildHeroProfileCard(),
        const SizedBox(height: AppSpacing.lg),

        // 2. GROUP 1: AKUN & KEAMANAN
        _buildSectionHeader('AKUN & KEAMANAN'),
        _buildGroupCard(
          children: [
            _buildSettingRow(
              icon: Icons.fingerprint_rounded,
              title: 'Login Biometrik',
              description: null,
              trailing: Switch(
                value: _isBiometricEnabled,
                onChanged: _isBiometricSupported ? _toggleBiometric : null,
                activeThumbColor: AppColors.pharmaNavy,
              ),
              showDivider: _isOperator,
            ),
            if (_isOperator)
              _buildSettingRow(
                icon: Icons.manage_accounts_rounded,
                title: 'Kelola Pengguna & Akses',
                description: null,
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
                onTap: _showManageUsersModal,
                showDivider: false,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 3. GROUP 2: JARINGAN & SENSOR
        _buildSectionHeader('JARINGAN & SENSOR'),
        _buildGroupCard(
          children: [
            _buildSettingRow(
              icon: Icons.dns_rounded,
              title: 'Server Jaringan',
              description: 'Host: ${_ipController.text}',
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
              onTap: _showNetworkConfigModal,
              showDivider: true,
            ),
            _buildSettingRow(
              icon: Icons.tune_rounded,
              title: 'Batas Ambang Sensor',
              description: '${_tempMin.toStringAsFixed(0)}–${_tempMax.toStringAsFixed(0)}°C • <${_gasMax.toStringAsFixed(0)} PPM',
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
              onTap: _showThresholdsModal,
              showDivider: true,
            ),
            _buildSettingRow(
              icon: Icons.hub_rounded,
              title: 'Layanan Telemetri',
              description: 'MQTT & REST API',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.activeGreen.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '● Aktif',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.activeGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
                ],
              ),
              onTap: _showServicesModal,
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 4. GROUP 3: APLIKASI
        _buildSectionHeader('APLIKASI'),
        _buildGroupCard(
          children: [
            _buildSettingRow(
              icon: Icons.system_update_alt_rounded,
              title: 'Pembaruan Aplikasi',
              description: 'Versi v1.0.2',
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pharmaNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(64, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                onPressed: _isCheckingUpdate
                    ? null
                    : () async {
                        setState(() => _isCheckingUpdate = true);
                        final info = await UpdateService.checkForUpdate();
                        if (!mounted) return;
                        setState(() => _isCheckingUpdate = false);
                        if (!context.mounted) return;
                        if (info.hasUpdate) {
                          UpdateService.showUpdateDialog(context, info);
                        } else {
                          AppToast.info(
                            context,
                            'Aplikasi sudah versi terbaru (v${info.currentVersion})',
                          );
                        }
                      },
                child: _isCheckingUpdate
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Periksa',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              showDivider: true,
            ),
            _buildSettingRow(
              icon: Icons.info_outline_rounded,
              title: 'Tentang Aplikasi',
              description: null,
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
              onTap: _showAboutModal,
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // 5. EDGE CASE: KELUAR AKUN (Slide 07)
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.alertRed,
            side: BorderSide(color: AppColors.alertRed.withAlpha(100)),
            backgroundColor: AppColors.alertRed.withAlpha(8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          onPressed: _showLogoutConfirmDialog,
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text(
            'Keluar dari Aplikasi',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const PharmaBrandStamp(),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm + 4,
        bottom: AppSpacing.lg,
      ),
      children: [
        // Network configuration card skeleton
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.containerLow, width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140E555A),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ShimmerLoading(
                    height: 36,
                    width: 36,
                    radius: AppSpacing.radiusPill,
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(
                        height: 16,
                        width: 180,
                        radius: AppSpacing.radiusSm,
                      ),
                      SizedBox(height: 6),
                      ShimmerLoading(
                        height: 12,
                        width: 220,
                        radius: AppSpacing.radiusSm,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const ShimmerLoading(height: 52, radius: AppSpacing.radiusMd),
              const SizedBox(height: AppSpacing.md),
              const ShimmerLoading(height: 44, radius: AppSpacing.radiusMd),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md - 2),
        // Threshold sensor card skeleton
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.containerLow, width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140E555A),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ShimmerLoading(
                    height: 36,
                    width: 36,
                    radius: AppSpacing.radiusPill,
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(
                        height: 16,
                        width: 140,
                        radius: AppSpacing.radiusSm,
                      ),
                      SizedBox(height: 6),
                      ShimmerLoading(
                        height: 12,
                        width: 200,
                        radius: AppSpacing.radiusSm,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ...List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          ShimmerLoading(
                            height: 14,
                            width: 110,
                            radius: AppSpacing.radiusSm,
                          ),
                          ShimmerLoading(
                            height: 18,
                            width: 60,
                            radius: AppSpacing.radiusSm,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs + 4),
                      const ShimmerLoading(
                        height: 14,
                        radius: AppSpacing.radiusPill,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md - 2),
        // Services info card skeleton
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.containerLow, width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140E555A),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const ShimmerLoading(
                    height: 32,
                    width: 32,
                    radius: AppSpacing.radiusPill,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(
                        height: 14,
                        width: 150,
                        radius: AppSpacing.radiusSm,
                      ),
                      SizedBox(height: 4),
                      ShimmerLoading(
                        height: 11,
                        width: 180,
                        radius: AppSpacing.radiusSm,
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.containerLow),
              Row(
                children: [
                  const ShimmerLoading(
                    height: 32,
                    width: 32,
                    radius: AppSpacing.radiusPill,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(
                        height: 14,
                        width: 160,
                        radius: AppSpacing.radiusSm,
                      ),
                      SizedBox(height: 4),
                      ShimmerLoading(
                        height: 11,
                        width: 170,
                        radius: AppSpacing.radiusSm,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const ShimmerLoading(height: 44, radius: AppSpacing.radiusMd),
      ],
    );
  }
}
