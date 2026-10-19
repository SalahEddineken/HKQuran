import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/todo.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';

/// Floating "Today" to-do list card positioned on the bottom left.
class TodoCard extends StatefulWidget {
  const TodoCard({super.key});

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  bool _isAdding = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _hoveredTodoId;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startAdding() {
    setState(() {
      _isAdding = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _submitTodo(AppState s) {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      s.addTodo(text);
      _textController.clear();
      // Keep input focused for rapid multi-task entry
      _focusNode.requestFocus();
    } else {
      _cancelAdding();
    }
  }

  void _cancelAdding() {
    setState(() {
      _isAdding = false;
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final isLight = s.themeMode == AppThemeMode.light;
    final todos = s.todos;
    final collapsed = s.todoCollapsed;

    if (collapsed) {
      return _buildCollapsedPill(context, s, isLight, todos);
    }

    return _buildExpandedCard(context, s, isLight, todos);
  }

  Widget _buildCollapsedPill(
    BuildContext context,
    AppState s,
    bool isLight,
    List<TodoItem> todos,
  ) {
    final pendingCount = todos.where((t) => !t.completed).length;
    final size = MediaQuery.sizeOf(context);
    final isSmall = size.width < 600 || size.height < 760;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => s.setTodoCollapsed(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 10 : 14,
            vertical: isSmall ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF26282B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE4E4E7)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isLight
                    ? const Color(0x0F000000)
                    : const Color(0x55000000),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isSmall ? 14 : 16,
                height: isSmall ? 14 : 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isSmall ? 4 : 4.5),
                  border: Border.all(
                    color: isLight
                        ? const Color(0xFF71717A)
                        : Colors.white.withValues(alpha: 0.5),
                    width: isSmall ? 1.2 : 1.4,
                  ),
                ),
                child: pendingCount == 0 && todos.isNotEmpty
                    ? Icon(
                        Icons.check_rounded,
                        size: isSmall ? 9.5 : 11,
                        color: s.themeMode.accent,
                      )
                    : null,
              ),
              SizedBox(width: isSmall ? 6 : 8),
              Text(
                s.tr('today'),
                style: TextStyle(
                  fontSize: isSmall ? 12.0 : 13.5,
                  fontWeight: FontWeight.w600,
                  color: isLight ? const Color(0xFF18181B) : Colors.white,
                ),
              ),
              if (pendingCount > 0) ...[
                SizedBox(width: isSmall ? 5 : 6),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 5 : 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isLight
                        ? const Color(0xFFE4E4E7)
                        : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$pendingCount',
                    style: TextStyle(
                      fontSize: isSmall ? 10.0 : 11.0,
                      fontWeight: FontWeight.w700,
                      color: isLight ? const Color(0xFF18181B) : Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedCard(
    BuildContext context,
    AppState s,
    bool isLight,
    List<TodoItem> todos,
  ) {
    final hasCompleted = todos.any((t) => t.completed);
    final size = MediaQuery.sizeOf(context);
    final isSmall = size.width < 600 || size.height < 760;
    final cardW = (size.width - 28.0).clamp(200.0, 260.0);

    return Container(
      width: isSmall ? cardW : 250.0,
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF26282B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE4E4E7)
              : Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? const Color(0x12000000)
                : const Color(0x66000000),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Header: "Today" + actions ----
            Row(
              children: [
                Text(
                  s.tr('today'),
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: isLight ? const Color(0xFF18181B) : Colors.white,
                  ),
                ),
                const Spacer(),
                if (hasCompleted) ...[
                  Tooltip(
                    message: s.tr('clearCompleted'),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: s.clearCompletedTodos,
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Icon(
                          Icons.done_all_rounded,
                          size: 15,
                          color: isLight
                              ? const Color(0xFFA1A1AA)
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Tooltip(
                  message: s.tr('collapse'),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => s.setTodoCollapsed(true),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 17,
                        color: isLight
                            ? const Color(0xFFA1A1AA)
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ---- Todo Items List ----
            if (todos.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: isSmall ? 130 : 180),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final todo in todos)
                        _buildTodoRow(context, s, todo, isLight),
                    ],
                  ),
                ),
              ),

            // ---- "Add to-do" action row or inline input ----
            if (_isAdding)
              _buildInlineInput(context, s, isLight)
            else
              _buildAddButton(context, s, isLight),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoRow(
    BuildContext context,
    AppState s,
    TodoItem todo,
    bool isLight,
  ) {
    final isHovered = _hoveredTodoId == todo.id;
    final isDone = todo.completed;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredTodoId = todo.id),
      onExit: (_) => setState(() => _hoveredTodoId = null),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.5),
        child: Row(
          children: [
            // Rounded square checkbox matching mockup
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                s.toggleTodo(todo.id);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: isDone
                        ? (isLight
                            ? const Color(0xFF18181B)
                            : s.themeMode.accent)
                        : Colors.transparent,
                    border: Border.all(
                      color: isDone
                          ? (isLight
                              ? const Color(0xFF18181B)
                              : s.themeMode.accent)
                          : (isLight
                              ? const Color(0xFF71717A)
                              : Colors.white.withValues(alpha: 0.45)),
                      width: 1.5,
                    ),
                  ),
                  child: isDone
                      ? Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: isLight
                              ? Colors.white
                              : const Color(0xFF1B1B1D),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Item text
            Expanded(
              child: GestureDetector(
                onTap: () => s.toggleTodo(todo.id),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    todo.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDone
                          ? (isLight
                              ? const Color(0xFFA1A1AA)
                              : Colors.white.withValues(alpha: 0.38))
                          : (isLight
                              ? const Color(0xFF18181B)
                              : Colors.white.withValues(alpha: 0.92)),
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: isLight
                          ? const Color(0xFFA1A1AA)
                          : Colors.white.withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ),
            ),

            // Delete button (reveals on hover / low opacity otherwise)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: isHovered ? 1.0 : 0.0,
              child: GestureDetector(
                onTap: () => s.removeTodo(todo.id),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: isLight
                          ? const Color(0xFFA1A1AA)
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, AppState s, bool isLight) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.5),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _startAdding,
          child: Row(
            children: [
              // [+] Rounded square icon with plus inside matching mockup
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isLight
                        ? const Color(0xFF71717A)
                        : Colors.white.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 13,
                    color: isLight
                        ? const Color(0xFF71717A)
                        : Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                s.tr('addTodo'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isLight
                      ? const Color(0xFF71717A)
                      : Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineInput(BuildContext context, AppState s, bool isLight) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: isLight
                    ? const Color(0xFF18181B)
                    : s.themeMode.accent,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.edit_rounded,
                size: 11,
                color: isLight
                    ? const Color(0xFF18181B)
                    : s.themeMode.accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              autofocus: true,
              style: TextStyle(
                fontSize: 14,
                color: isLight ? const Color(0xFF18181B) : Colors.white,
              ),
              cursorColor: s.themeMode.accent,
              decoration: InputDecoration.collapsed(
                hintText: s.tr('todoHint'),
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isLight
                      ? const Color(0xFFA1A1AA)
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
              onSubmitted: (_) => _submitTodo(s),
            ),
          ),
          // Check/submit icon
          GestureDetector(
            onTap: () => _submitTodo(s),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: s.themeMode.accent,
                ),
              ),
            ),
          ),
          // Cancel icon
          GestureDetector(
            onTap: _cancelAdding,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: isLight
                      ? const Color(0xFFA1A1AA)
                      : Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
