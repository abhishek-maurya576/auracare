import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../utils/app_colors.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../providers/auth_provider.dart';
import 'journal_editor_screen.dart';
import 'journal_entry_detail_screen.dart';

/// Main Journal Screen with encrypted journaling and AI prompts
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<JournalEntry> _entries = [];
  JournalStatistics? _statistics;
  bool _isLoading = true;
  String _searchQuery = '';
  JournalEntryType? _filterType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadJournalData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJournalData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final entries = await JournalService.getUserJournalEntries(userId);
      final statistics = await JournalService.getJournalStatistics(userId);
      
      setState(() {
        _entries = entries;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading journal data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
        title: const Text(
          'My Journal',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showSearchDialog,
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
          ),
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list, color: AppColors.textPrimary),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryColor,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Entries'),
            Tab(text: 'Statistics'),
            Tab(text: 'Prompts'),
          ],
        ),
      ),
      body: Stack(
        children: [
          const AuraBackground(),
          SafeArea(
            child: _isLoading ? _buildLoadingState() : _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewEntry,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit),
        label: const Text('Write'),
      ).animate().scale(delay: 300.ms, duration: 600.ms),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildEntriesTab(),
        _buildStatisticsTab(),
        _buildPromptsTab(),
      ],
    );
  }

  Widget _buildEntriesTab() {
    final filteredEntries = _getFilteredEntries();
    
    if (filteredEntries.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadJournalData,
      color: AppColors.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filteredEntries.length,
        itemBuilder: (context, index) {
          final entry = filteredEntries[index];
          return _buildEntryCard(entry, index);
        },
      ),
    );
  }

  Widget _buildEntryCard(JournalEntry entry, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: InkWell(
          onTap: () => _openEntryDetail(entry),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.type.icon,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.title.isEmpty ? 'Untitled Entry' : entry.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleEntryAction(value, entry),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entry.preview,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    entry.readingTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  )).toList(),
                ),
              ],
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 100).ms).slideX(begin: 0.3).fadeIn();
  }

  Widget _buildStatisticsTab() {
    if (_statistics == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildStatCard(
            'Writing Streak',
            _statistics!.streakText,
            Icons.local_fire_department,
            Colors.orange,
          ).animate().slideY(begin: 0.3).fadeIn(),
          const SizedBox(height: 16),
          _buildStatCard(
            'Total Entries',
            '${_statistics!.totalEntries}',
            Icons.book,
            Colors.blue,
          ).animate(delay: 100.ms).slideY(begin: 0.3).fadeIn(),
          const SizedBox(height: 16),
          _buildStatCard(
            'Words Written',
            '${_statistics!.totalWords}',
            Icons.text_fields,
            Colors.green,
          ).animate(delay: 200.ms).slideY(begin: 0.3).fadeIn(),
          const SizedBox(height: 16),
          _buildStatCard(
            'This Month',
            '${_statistics!.monthlyEntries} entries',
            Icons.calendar_month,
            Colors.purple,
          ).animate(delay: 300.ms).slideY(begin: 0.3).fadeIn(),
          const SizedBox(height: 24),
          if (_statistics!.mostUsedTags.isNotEmpty) ...[
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Most Used Tags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _statistics!.mostUsedTags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 400.ms).slideY(begin: 0.3).fadeIn(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptsTab() {
    final prompts = JournalPrompt.getAgeAppropriatePrompts('young_adult');
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: prompts.length + 1, // +1 for AI prompt generator
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildAIPromptGenerator();
        }
        
        final prompt = prompts[index - 1];
        return _buildPromptCard(prompt, index - 1);
      },
    );
  }

  Widget _buildAIPromptGenerator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI Writing Prompt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Get a personalized writing prompt based on your current mood and recent entries.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateAIPrompt,
                icon: const Icon(Icons.psychology),
                label: const Text('Generate Prompt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 0.3).fadeIn();
  }

  Widget _buildPromptCard(JournalPrompt prompt, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: InkWell(
          onTap: () => _usePrompt(prompt),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  Text(
                    prompt.type.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prompt.type.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Level ${prompt.difficulty}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                prompt.prompt,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _usePrompt(prompt),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Use Prompt'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 100).ms).slideX(begin: 0.3).fadeIn();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.book,
                size: 48,
                color: AppColors.primaryColor,
              ),
            ).animate().scale(delay: 200.ms),
            const SizedBox(height: 24),
            const Text(
              'Start Your Journey',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ).animate(delay: 300.ms).fadeIn(),
            const SizedBox(height: 12),
            Text(
              'Your journal is a safe space to explore your thoughts, feelings, and experiences. Start writing your first entry today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                height: 1.4,
              ),
            ).animate(delay: 400.ms).fadeIn(),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createNewEntry,
              icon: const Icon(Icons.edit),
              label: const Text('Write First Entry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ).animate(delay: 500.ms).slideY(begin: 0.3).fadeIn(),
          ],
        ),
      ),
    );
  }

  List<JournalEntry> _getFilteredEntries() {
    var filtered = _entries;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((entry) {
        final searchText = '${entry.title} ${entry.content} ${entry.tags.join(' ')}'.toLowerCase();
        return searchText.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    if (_filterType != null) {
      filtered = filtered.where((entry) => entry.type == _filterType).toList();
    }
    
    return filtered;
  }

  void _createNewEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JournalEditorScreen(),
      ),
    ).then((_) => _loadJournalData());
  }

  void _openEntryDetail(JournalEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEntryDetailScreen(entry: entry),
      ),
    ).then((_) => _loadJournalData());
  }

  void _usePrompt(JournalPrompt prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEditorScreen(
          initialPrompt: prompt.prompt,
          entryType: prompt.type,
        ),
      ),
    ).then((_) => _loadJournalData());
  }

  void _generateAIPrompt() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    
    if (userId == null) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          backgroundColor: Colors.transparent,
          content: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
        ),
      );

      final prompt = await JournalService.generateWritingPrompt(userId: userId);
      
      Navigator.of(context).pop(); // Close loading dialog
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JournalEditorScreen(
            initialPrompt: prompt,
            entryType: JournalEntryType.prompted,
          ),
        ),
      ).then((_) => _loadJournalData());
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorSnackBar('Error generating prompt: $e');
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Search Journal', style: TextStyle(color: Colors.white)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search entries...',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Filter Entries', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Entries', style: TextStyle(color: Colors.white)),
              leading: Radio<JournalEntryType?>(
                value: null,
                groupValue: _filterType,
                onChanged: (value) {
                  setState(() => _filterType = value);
                  Navigator.of(context).pop();
                },
              ),
            ),
            ...JournalEntryType.values.map((type) => ListTile(
              title: Text(type.displayName, style: const TextStyle(color: Colors.white)),
              leading: Radio<JournalEntryType?>(
                value: type,
                groupValue: _filterType,
                onChanged: (value) {
                  setState(() => _filterType = value);
                  Navigator.of(context).pop();
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _handleEntryAction(String action, JournalEntry entry) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JournalEditorScreen(existingEntry: entry),
          ),
        ).then((_) => _loadJournalData());
        break;
      case 'delete':
        _showDeleteConfirmation(entry);
        break;
    }
  }

  void _showDeleteConfirmation(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Entry', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this journal entry? This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteEntry(entry);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    
    if (userId == null) return;

    try {
      final success = await JournalService.deleteJournalEntry(userId, entry.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal entry deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _loadJournalData();
      } else {
        _showErrorSnackBar('Failed to delete entry');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting entry: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}