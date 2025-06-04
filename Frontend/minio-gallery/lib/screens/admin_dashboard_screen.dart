import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_user.dart';
import '../models/admin_image.dart';
import '../models/system_stats.dart';
import '../services/admin_service.dart';
import '../providers/auth_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();

  SystemStats? _systemStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSystemStats();
  }

  Future<void> _loadSystemStats() async {
    try {
      final stats = await _adminService.getSystemStats();
      setState(() {
        _systemStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel caricamento statistiche: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Check if user is admin
    if (authProvider.user?.role != 'ADMIN') {
      return Scaffold(
        appBar: AppBar(title: const Text('Accesso Negato')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Accesso riservato agli amministratori',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Statistiche'),
            Tab(icon: Icon(Icons.people), text: 'Utenti'),
            Tab(icon: Icon(Icons.photo_library), text: 'Immagini'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildStatsTab(), _buildUsersTab(), _buildImagesTab()],
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_systemStats == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Errore nel caricamento delle statistiche'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Panoramica Sistema',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive grid: più colonne su schermi più larghi
              int crossAxisCount = 2;
              if (constraints.maxWidth > 600) crossAxisCount = 3;
              if (constraints.maxWidth > 900) crossAxisCount = 4;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9, // Rendiamo le card meno alte
                children: [
                  _buildStatCard(
                    'Utenti Totali',
                    _systemStats!.totalUsers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  // _buildStatCard(
                  //   'Utenti Attivi',
                  //   _systemStats!.activeUsers.toString(),
                  //   Icons.verified_user,
                  //   Colors.green,
                  // ),
                  _buildStatCard(
                    'Immagini Totali',
                    _systemStats!.totalImages.toString(),
                    Icons.photo_library,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Storage Utilizzato',
                    _systemStats!.totalStorageUsed,
                    Icons.storage,
                    Colors.purple,
                  ),
                  _buildStatCard(
                    'Amministratori',
                    _systemStats!.totalAdmins.toString(),
                    Icons.admin_panel_settings,
                    Colors.red,
                  ),
                  _buildStatCard(
                    'Like Totali',
                    _systemStats!.totalLikes.toString(),
                    Icons.favorite,
                    Colors.pink,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loadSystemStats,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Aggiorna Statistiche'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12), // Riduciamo il padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color), // Riduciamo l'icona
            const SizedBox(height: 6), // Riduciamo lo spazio
            Text(
              value,
              style: TextStyle(
                fontSize: 18, // Riduciamo il font del valore
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2), // Riduciamo lo spazio
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ), // Riduciamo il font del titolo
              maxLines: 2, // Permettiamo due righe per il titolo
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return AdminUsersTab(adminService: _adminService);
  }

  Widget _buildImagesTab() {
    return AdminImagesTab(adminService: _adminService);
  }
}

// Users Tab Component
class AdminUsersTab extends StatefulWidget {
  final AdminService adminService;

  const AdminUsersTab({super.key, required this.adminService});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  List<AdminUser> _users = [];
  bool _isLoading = true;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _hasNext = false;
  bool _hasPrevious = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({int page = 0}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await widget.adminService.getAllUsers(
        page: page,
        size: 20,
      );
      setState(() {
        _users = result['users'];
        _currentPage = result['currentPage'];
        _totalPages = result['totalPages'];
        _hasNext = result['hasNext'];
        _hasPrevious = result['hasPrevious'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel caricamento utenti: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Conferma Eliminazione'),
            content: Text(
              'Sei sicuro di voler eliminare l\'utente "${user.username}"?\nQuesto eliminerà anche tutte le sue immagini.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annulla'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Elimina'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final success = await widget.adminService.deleteUser(user.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utente eliminato con successo')),
          );
          _loadUsers(page: _currentPage);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore nell\'eliminazione: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleUserStatus(AdminUser user) async {
    try {
      final success = await widget.adminService.toggleUserStatus(
        user.id,
        !user.enabled,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Utente ${!user.enabled ? 'abilitato' : 'disabilitato'} con successo',
            ),
          ),
        );
        _loadUsers(page: _currentPage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore nell\'operazione: $e')));
      }
    }
  }

  Future<void> _changeUserRole(AdminUser user) async {
    final newRole = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Cambia Ruolo - ${user.username}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Utente'),
                  leading: Radio<String>(
                    value: 'USER',
                    groupValue: user.role,
                    onChanged: (value) => Navigator.of(context).pop(value),
                  ),
                ),
                ListTile(
                  title: const Text('Amministratore'),
                  leading: Radio<String>(
                    value: 'ADMIN',
                    groupValue: user.role,
                    onChanged: (value) => Navigator.of(context).pop(value),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
            ],
          ),
    );

    if (newRole != null && newRole != user.role) {
      try {
        final success = await widget.adminService.changeUserRole(
          user.id,
          newRole,
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ruolo utente modificato con successo'),
            ),
          );
          _loadUsers(page: _currentPage);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore nella modifica del ruolo: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        user.role == 'ADMIN' ? Colors.red : Colors.blue,
                    child: Icon(
                      user.role == 'ADMIN'
                          ? Icons.admin_panel_settings
                          : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(user.username),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email),
                      Text(
                        '${user.role} • ${user.imageCount} immagini',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'toggle_status':
                          _toggleUserStatus(user);
                          break;
                        case 'change_role':
                          _changeUserRole(user);
                          break;
                        case 'delete':
                          _deleteUser(user);
                          break;
                      }
                    },
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'toggle_status',
                            child: Row(
                              children: [
                                Icon(
                                  user.enabled
                                      ? Icons.block
                                      : Icons.check_circle,
                                ),
                                const SizedBox(width: 8),
                                Text(user.enabled ? 'Disabilita' : 'Abilita'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'change_role',
                            child: Row(
                              children: [
                                Icon(Icons.admin_panel_settings),
                                SizedBox(width: 8),
                                Text('Cambia Ruolo'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Elimina',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed:
                      _hasPrevious
                          ? () => _loadUsers(page: _currentPage - 1)
                          : null,
                  child: const Text('Precedente'),
                ),
                Text('Pagina ${_currentPage + 1} di $_totalPages'),
                ElevatedButton(
                  onPressed:
                      _hasNext
                          ? () => _loadUsers(page: _currentPage + 1)
                          : null,
                  child: const Text('Successiva'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Images Tab Component
class AdminImagesTab extends StatefulWidget {
  final AdminService adminService;

  const AdminImagesTab({super.key, required this.adminService});

  @override
  State<AdminImagesTab> createState() => _AdminImagesTabState();
}

class _AdminImagesTabState extends State<AdminImagesTab> {
  List<AdminImage> _images = [];
  bool _isLoading = true;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _hasNext = false;
  bool _hasPrevious = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages({int page = 0}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await widget.adminService.getAllImages(
        page: page,
        size: 20,
      );
      setState(() {
        _images = result['images'];
        _currentPage = result['currentPage'];
        _totalPages = result['totalPages'];
        _hasNext = result['hasNext'];
        _hasPrevious = result['hasPrevious'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel caricamento immagini: $e')),
        );
      }
    }
  }

  Future<void> _deleteImage(AdminImage image) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Conferma Eliminazione'),
            content: Text(
              'Sei sicuro di voler eliminare l\'immagine "${image.title}" di ${image.username}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annulla'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Elimina'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final success = await widget.adminService.deleteImage(image.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Immagine eliminata con successo')),
          );
          _loadImages(page: _currentPage);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore nell\'eliminazione: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final image = _images[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                  title: Text(image.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Proprietario: ${image.username}'),
                      Text('File: ${image.fileName}'),
                      Text(
                        '${image.fileSizeFormatted} • ${image.likes} like • ${image.uploadedAt.day}/${image.uploadedAt.month}/${image.uploadedAt.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteImage(image),
                  ),
                ),
              );
            },
          ),
        ),
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed:
                      _hasPrevious
                          ? () => _loadImages(page: _currentPage - 1)
                          : null,
                  child: const Text('Precedente'),
                ),
                Text('Pagina ${_currentPage + 1} di $_totalPages'),
                ElevatedButton(
                  onPressed:
                      _hasNext
                          ? () => _loadImages(page: _currentPage + 1)
                          : null,
                  child: const Text('Successiva'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
