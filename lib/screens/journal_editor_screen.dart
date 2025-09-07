import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../utils/app_colors.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../providers/auth_provider.dart';

/// Journal Editor Screen for writing and editing encrypted journal entries
class JournalEditorScreen extends StatefulWidget {
  final JournalEntry? existingEntry;
  final String? initialPrompt;
  final JournalEntryType entryType;

  const JournalEditorScreen({
    super.key,
    this.existingEntry,
    this.initialPrompt,
    this.entryType = JournalEntryType.freeform,
  });

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  
  JournalEntryType _selectedType = JournalEntryType.freeform;
  List<String> _tags = [];
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  int _wordCount = 0;
  
  @override
  void initState() {
    super.initState();
    
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();
    
    _selectedType = widget.entryType;
    
    // Initialize with existing entry data
    if (widget.existingEntry != null) {
      _titleController.text = widget.existingEntry!.title;
      _contentController.text = widget.existingEntry!.content;
      _selectedType = widget.existingEntry!.type;
      _tags = List.from(widget.existingEntry!.tags);
      _updateWordCount();
    }
    
    // Initialize with prompt if provided
    if (widget.initialPrompt != null && widget.existingEntry == null) {
      _contentController.text = '${widget.initialPrompt}\n\n';
      _contentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _contentController.text.length),
      );
      _updateWordCount();
    }
    
    // Listen for changes
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    
    // Auto-focus content field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.existingEntry == null) {
        _contentFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasUnsavedChanges = true;
      _updateWordCount();
    });
  }

  void _updateWordCount() {
    final text = _contentController.text;
    _wordCount = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => _handleBackPress(),
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
          ),
          title: Text(
            widget.existingEntry != null ? 'Edit Entry' : 'New Entry',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_hasUnsavedChanges)
              TextButton(
                onPressed: _isSaving ? null : _saveEntry,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
          ],
        ),
        body: Stack(
          children: [
            const AuraBackground(),
            SafeArea(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Entry type and options bar
        _buildOptionsBar(),
        
        // Main editor
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Title field
                _buildTitleField(),
                const SizedBox(height: 20),
                
                // Content field
                _buildContentField(),
                const SizedBox(height: 20),
                
                // Tags section
                _buildTagsSection(),
                const SizedBox(height: 100), // Extra space for keyboard
              ],
            ),
          ),
        ),
        
        // Bottom toolbar
        _buildBottomToolbar(),
      ],
    );
  }

  Widget _buildOptionsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Entry type selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 51),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedType.icon,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedType.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              
              // Word count
              Text(
                '$_wordCount words',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 179),
                ),
              ),
              const SizedBox(width: 12),
              
              // More options
              PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'change_type',
                    child: Row(
                      children: [
                        Icon(Icons.category, size: 18),
                        SizedBox(width: 8),
                        Text('Change Type'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'add_tag',
                    child: Row(
                      children: [
                        Icon(Icons.tag, size: 18),
                        SizedBox(width: 8),
                        Text('Add Tag'),
                      ],
                    ),
                  ),
                  if (widget.existingEntry != null)
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
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return GlassCard(
      child: TextField(
        controller: _titleController,
        focusNode: _titleFocusNode,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: 'Entry title (optional)',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 128),
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        textCapitalization: TextCapitalization.sentences,
        maxLines: 2,
      ),
    );
  }

  Widget _buildContentField() {
    return GlassCard(
      child: TextField(
        controller: _contentController,
        focusNode: _contentFocusNode,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: widget.initialPrompt != null 
              ? 'Continue writing...'
              : 'What\'s on your mind?',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 128),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        textCapitalization: TextCapitalization.sentences,
        maxLines: null,
        minLines: 10,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
      ),
    );
  }

  Widget _buildTagsSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tag, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAddTagDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_tags.isEmpty)
              Text(
                'No tags added yet. Tags help you organize and find your entries.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 153),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) => _buildTagChip(tag)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 51),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: Icon(
              Icons.close,
              size: 16,
              color: Colors.white.withValues(alpha: 179),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Auto-save indicator
          if (_hasUnsavedChanges)
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: Colors.orange.withValues(alpha: 204),
                ),
                const SizedBox(width: 8),
                Text(
                  'Unsaved changes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 153),
                  ),
                ),
              ],
            )
          else if (widget.existingEntry != null)
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green.withValues(alpha: 204),
                ),
                const SizedBox(width: 8),
                Text(
                  'Saved',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 153),
                  ),
                ),
              ],
            ),
          
          const Spacer(),
          
          // Save button
          ElevatedButton.icon(
            onPressed: _isSaving || !_hasUnsavedChanges ? null : _saveEntry,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save Entry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Unsaved Changes', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You have unsaved changes. Do you want to save before leaving?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(false);
              await _saveEntry();
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _handleBackPress() async {
    if (await _onWillPop()) {
      Navigator.of(context).pop();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'change_type':
        _showTypeSelector();
        break;
      case 'add_tag':
        _showAddTagDialog();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showTypeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Entry Type', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: JournalEntryType.values.map((type) => ListTile(
            leading: Text(type.icon, style: const TextStyle(fontSize: 20)),
            title: Text(type.displayName, style: const TextStyle(color: Colors.white)),
            subtitle: Text(type.description, style: TextStyle(color: Colors.white.withValues(alpha: 179))),
            onTap: () {
              setState(() {
                _selectedType = type;
                _hasUnsavedChanges = true;
              });
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Add Tag', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter tag name',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _addTag(value);
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addTag(controller.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addTag(String tag) {
    final cleanTag = tag.trim().toLowerCase();
    if (cleanTag.isNotEmpty && !_tags.contains(cleanTag)) {
      setState(() {
        _tags.add(cleanTag);
        _hasUnsavedChanges = true;
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    
    if (userId == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      _showErrorSnackBar('Please write something before saving');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await JournalService.saveJournalEntry(
        userId: userId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        tags: _tags,
        existingEntryId: widget.existingEntry?.id,
      );

      setState(() {
        _isSaving = false;
        _hasUnsavedChanges = false;
      });

      // Provide haptic feedback
      HapticFeedback.lightImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingEntry != null ? 'Entry updated' : 'Entry saved'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Error saving entry: $e');
    }
  }

  void _showDeleteConfirmation() {
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
              await _deleteEntry();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry() async {
    if (widget.existingEntry == null) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    
    if (userId == null) return;

    try {
      final success = await JournalService.deleteJournalEntry(userId, widget.existingEntry!.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal entry deleted'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
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