import 'package:flutter/material.dart';
import 'package:prodspace/board/domain/utils/board_backend_connection_utils.dart';
import 'package:prodspace/l10n/app_localizations.dart';
import 'dart:math';
import '../../domain/models/board_models.dart';
import '../../domain/utils/board_utils.dart';
import '../widgets/toolbar.dart';
import '../widgets/selection_actions.dart';
import '../widgets/draw_color_picker.dart';
import '../widgets/board_object_widget.dart';
import '../widgets/board_painter.dart';
import '../widgets/dashed_rect.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:prodspace/settings/presentations/widgets/settings_btn.dart';
import 'package:hive/hive.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BordPageState();
}

class _BordPageState extends State<BoardPage> {
  final List<BoardObject> _objects = [];
  final List<DrawPath> _paths = [];
  // Очередь на отправку
  final List<BoardAction> _actionQueue = [];
  ToolType _selectedTool = ToolType.selection;
  int? _draggingObjectIndex;
  Set<int> _selectedObjectIndices = {};
  Offset? _dragStartLocal;
  Offset? _dragStartObjectPos;
  bool _isDrawing = false;
  DrawPath? _currentPath;
  Offset? _selectionBoxStart;
  Offset? _selectionBoxEnd;
  Map<int, Offset>? _dragStartPositions;
  Offset? _dragStartPointer;
  Set<int> _selectedPathIndices = {};
  Map<int, List<Offset>>? _dragStartPathPoints;
  Color _colorPickerValue = Colors.blue;
  Color _drawColor = Colors.blue;
  Color _rectColor = Colors.blue;
  Color _circleColor = Colors.green;
  Color _textColor = Colors.black;
  static const Size _boardSize = Size(2000, 2000);
  Offset _canvasOffset = Offset.zero;
  double _canvasScale = 1.0;
  double _initialScale = 1.0;
  int _nextObjZPos = 1;
  bool _isSending = false;
  bool _isDownloading = false;
  bool _isDownloaded = false;

  void _onToolSelected(ToolType tool) {
    setState(() {
      _selectedTool = tool;
    });
  }

  void _addObject(Offset pos) async {
    final Offset boardPos = pos;
    switch (_selectedTool) {
      case ToolType.rectangle:
        setState(() {
          final obj = BoardObject(
            type: BoardObjectType.rectangle,
            position: boardPos,
            zPos: _nextObjZPos,
            size: const Size(120, 80),
            color: _rectColor,
          );
          _objects.add(obj);
          _actionQueue.add(BoardAction(BoardItemObject(obj), BoardItemAction.create));
        });
        _nextObjZPos++;
        break;
      case ToolType.circle:
        setState(() {
          final obj = BoardObject(
            type: BoardObjectType.circle,
            position: boardPos,
            zPos: _nextObjZPos,
            size: const Size(90, 90),
            color: _circleColor,
          );
          _objects.add(obj);
          _actionQueue.add(BoardAction(BoardItemObject(obj), BoardItemAction.create));
        });
        _nextObjZPos++;
        break;
      case ToolType.text:
        final text = await _showTextInputDialog();
        if (text != null && text.isNotEmpty) {
          setState(() {
            final obj = BoardObject(
              type: BoardObjectType.text,
              position: boardPos,
              zPos: _nextObjZPos,
              size: const Size(160, 50),
              color: _textColor,
              text: text,
            );
            _nextObjZPos++;
            _objects.add(obj);
            _actionQueue.add(BoardAction(BoardItemObject(obj), BoardItemAction.create));
          });
        }
        break;
      case ToolType.draw:
        // Рисование начинается по onPanStart
        break;
      case ToolType.selection:
        // Не добавляем объект
        break;
      case ToolType.pan:
        // Не добавляем объект
        break;
      case ToolType.image:
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            final obj = BoardObject(
              type: BoardObjectType.image,
              position: boardPos,
              zPos: _nextObjZPos,
              size: const Size(160, 120),
              color: Colors.transparent,
              imageBytes: bytes,
            );
            _nextObjZPos++;
            _objects.add(obj);
            _actionQueue.add(BoardAction(BoardItemObject(obj), BoardItemAction.create));
          });
        }
        break;
    }
  }

  Future<String?> _showTextInputDialog() async {
    String value = '';
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.inputText),
          content: TextField(
            autofocus: true,
            onChanged: (v) => value = v,
            onSubmitted: (v) => Navigator.of(context).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(value),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_selectedTool == ToolType.draw) {
      setState(() {
        _isDrawing = true;
        final Offset boardPos =
            details.localFocalPoint / _boardSize.width * 2000;
        _currentPath = DrawPath(points: [boardPos], color: _drawColor, strokeWidth: 3.0);
        _paths.add(_currentPath!);
      });
      return;
    }
    _draggingObjectIndex = BoardUtils.findObjectAt(
      details.localFocalPoint,
      _objects,
    );
    if (_draggingObjectIndex != null) {
      _dragStartLocal = details.localFocalPoint;
      _dragStartObjectPos = _objects[_draggingObjectIndex!].position;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_selectedTool == ToolType.draw && _isDrawing && _currentPath != null) {
      setState(() {
        final Offset boardPos =
            details.localFocalPoint / _boardSize.width * 2000;
        _currentPath!.points.add(boardPos);
      });
      return;
    }
    if (_draggingObjectIndex != null &&
        _dragStartLocal != null &&
        _dragStartObjectPos != null &&
        details.pointerCount == 1) {
      setState(() {
        final delta =
            (details.localFocalPoint - _dragStartLocal!) /
            _boardSize.width *
            2000;
        _objects[_draggingObjectIndex!] = _objects[_draggingObjectIndex!]
            .copyWith(position: _dragStartObjectPos! + delta);
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_selectedTool == ToolType.draw && _isDrawing) {
      setState(() {
        _isDrawing = false;
        if (_currentPath != null) {
          _actionQueue.add(BoardAction(BoardItemPath(_currentPath!), BoardItemAction.create));
        }
        _currentPath = null;
      });
      return;
    }
    _draggingObjectIndex = null;
    _dragStartLocal = null;
    _dragStartObjectPos = null;
  }

  void _onTapBoard(Offset localPosition) {
    if (_selectedTool == ToolType.selection) {
      final objIdx = BoardUtils.findObjectAt(localPosition, _objects);
      final pathIdx = BoardUtils.findPathAt(localPosition, _paths);
      setState(() {
        if (objIdx != null) {
          _selectedObjectIndices = {objIdx};
          _selectedPathIndices.clear();
        } else if (pathIdx != null) {
          _selectedPathIndices = {pathIdx};
          _selectedObjectIndices.clear();
        } else {
          _selectedObjectIndices.clear();
          _selectedPathIndices.clear();
        }
      });
    } else {
      setState(() {
        _selectedObjectIndices.clear();
        _selectedPathIndices.clear();
      });
      if (_selectedTool != ToolType.draw) {
        _addObject(localPosition);
      }
    }
  }

  void _onSelectionBoxStart(Offset localPosition) {
    if (_selectedTool == ToolType.selection) {
      setState(() {
        _selectionBoxStart = localPosition;
        _selectionBoxEnd = localPosition;
      });
    }
  }

  void _onSelectionBoxUpdate(Offset localPosition) {
    if (_selectedTool == ToolType.selection && _selectionBoxStart != null) {
      setState(() {
        _selectionBoxEnd = localPosition;
        _updateSelectionByBox();
      });
    }
  }

  void _onSelectionBoxEnd() {
    if (_selectedTool == ToolType.selection) {
      setState(() {
        _selectionBoxStart = null;
        _selectionBoxEnd = null;
      });
    }
  }

  void _updateSelectionByBox() {
    if (_selectionBoxStart == null || _selectionBoxEnd == null) return;
    final box = Rect.fromPoints(_selectionBoxStart!, _selectionBoxEnd!);
    final selectedObjs = <int>{};
    for (int i = 0; i < _objects.length; i++) {
      final objRect = _objects[i].position & _objects[i].size;
      if (box.overlaps(objRect) ||
          box.contains(objRect.topLeft) ||
          box.contains(objRect.bottomRight)) {
        selectedObjs.add(i);
      }
    }
    final selectedPaths = <int>{};
    for (int i = 0; i < _paths.length; i++) {
      final pathBox = BoardUtils.boundingBoxForPath(_paths[i]);
      if (box.overlaps(pathBox)) {
        selectedPaths.add(i);
      }
    }
    _selectedObjectIndices = selectedObjs;
    _selectedPathIndices = selectedPaths;
  }

  void _deleteSelected() {
    setState(() {
      _selectedObjectIndices.toList()
        ..sort((a, b) => b.compareTo(a))
        ..forEach((i) {
          _objects.removeAt(i);
           _actionQueue.add(BoardAction(BoardItemObject(_objects[i]), BoardItemAction.delete));
           });
      _selectedPathIndices.toList()
        ..sort((a, b) => b.compareTo(a))
        ..forEach((i) {
           _paths.removeAt(i);
           _actionQueue.add(BoardAction(BoardItemPath(_paths[i]), BoardItemAction.delete));
          });
      _selectedObjectIndices.clear();
      _selectedPathIndices.clear();
    });
  }

  void _setColorForSelected(Color color) {
    setState(() {
      for (final i in _selectedObjectIndices) {
        _objects[i] = _objects[i].copyWith(color: color);
      }
      for (final i in _selectedPathIndices) {
        _paths[i] = DrawPath(points: _paths[i].points, color:  color, strokeWidth: _paths[i].strokeWidth);
      }
      _colorPickerValue = color;
    });
  }

  // Преобразование координат экрана в координаты доски
  Offset _screenToBoardCoordinates(Offset screenPos) {
    return BoardUtils.screenToBoardCoordinates(
      screenPos,
      _canvasOffset,
      _canvasScale,
    );
  }

  void _handleResize(
    int idx,
    ResizeDirection direction,
    DragUpdateDetails details,
  ) {
    setState(() {
      final obj = _objects[idx];
      final delta = details.delta;
      Offset newPosition = obj.position;
      Size newSize = obj.size;
      switch (direction) {
        case ResizeDirection.topLeft:
          newPosition += delta;
          newSize = Size(
            (obj.size.width - delta.dx).clamp(20, double.infinity),
            (obj.size.height - delta.dy).clamp(20, double.infinity),
          );
          break;
        case ResizeDirection.topRight:
          newPosition += Offset(0, delta.dy);
          newSize = Size(
            (obj.size.width + delta.dx).clamp(20, double.infinity),
            (obj.size.height - delta.dy).clamp(20, double.infinity),
          );
          break;
        case ResizeDirection.bottomLeft:
          newPosition += Offset(delta.dx, 0);
          newSize = Size(
            (obj.size.width - delta.dx).clamp(20, double.infinity),
            (obj.size.height + delta.dy).clamp(20, double.infinity),
          );
          break;
        case ResizeDirection.bottomRight:
          newSize = Size(
            (obj.size.width + delta.dx).clamp(20, double.infinity),
            (obj.size.height + delta.dy).clamp(20, double.infinity),
          );
          break;
      }
      _objects[idx] = obj.copyWith(position: newPosition, size: newSize);
    });
  }


  // Функция отправки только объектов из очереди
  Future<void> _sendBoardToBackend() async {
    var localization = AppLocalizations.of(context)!;
    if (_isSending) return; // Prevent multiple sends
    
    // Show loading icon
    setState(() {
      _isSending = true;
    });

    final box = await Hive.openBox('user_parameters');

    // Save in guest mode
    if (box.get('username') == "Guest Mode") {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.saveInGuestMode)),
      );
      setState(() {
        _isSending = false;
      });
      return;
    }

    final token = box.get('token');
    // Token is missed
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.noToken)),
      );
      setState(() {
        _isSending = false;
      });
      return;
    }

    // Копируем очередь, чтобы не было проблем при изменении во время отправки
    final List<BoardAction> queueCopy = List.from(_actionQueue);
    for (int i = 0; i < queueCopy.length; i++) {
      try {
        String? message;
        // Send request and recive error message
        switch (queueCopy[i].action) {
          case BoardItemAction.create:
            message = await BoardBackendConnectionUtils.sendBoardItem(queueCopy[i].item, token);
            break;
          case BoardItemAction.delete:
            message = await BoardBackendConnectionUtils.deleteItem(queueCopy[i].item.getId(), token);
            break;
          default:
            break;
        }
        if (message == null) {
              setState(() {
                _actionQueue.remove(queueCopy[i]); // Удаляем из очереди после успешной отправки
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localization.changeSuccess), duration: Duration(milliseconds: 500)));
            } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${localization.changeErr}: $message')),
            );
            }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localization.changeErr}: ${e.toString()}')),
        );
      }
    }
    setState(() {
      _isSending = false;
    });
  }

  Future<void> _getBoardFromDB() async {
    // Set downloading state
    setState(() {
      _isDownloading = true;
    });

    final box = await Hive.openBox('user_parameters');
    final token = box.get('token');
    // Token is missed
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noToken)),
      );
      setState(() {
        _isDownloading = false;
        _isDownloaded = true;
      });
      return;
    }

    // Get items in json
    final items = await BoardBackendConnectionUtils.getWorkspaceItems(token);
    if (items == []) {
        setState(() {
        _isDownloading = false;
        _isDownloaded = true;
      });
      return;
    }
    for (int i = 0; i < items.length; i++) {
      final item = await BoardBackendConnectionUtils.createBoardItem(items[i]);
      if (item is BoardItemObject) {
        _objects.add(item.object);
      }
      else if (item is BoardItemPath) {
        _paths.add(item.path);
      }
      else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.parseErr} ${items[i].toString()}')),
      );
      }
    }
    setState(() {
      _isDownloading = false;
      _isDownloaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations.of(context)!;
    if (!_isDownloaded) {
      _getBoardFromDB();
    }
    if (_isDownloading) {
      return Scaffold(
      appBar: AppBar(title: Text(localization.workspaceLoading),),
      body: Center(child: CircularProgressIndicator()));
    }
    final hasSelection =
        _selectedObjectIndices.isNotEmpty || _selectedPathIndices.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.workspace),
        actions: [
        if (_isSending)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: localization.saveBoard,
            onPressed: _sendBoardToBackend,
          ),
        settingsButton(context),
      ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final Offset effectiveOffset = _canvasOffset;
          return Stack(
            children: [
              // Доска и взаимодействия
              Positioned.fill(
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      setState(() {
                        if (pointerSignal.scrollDelta.dy < 0) {
                          _canvasScale = (_canvasScale * 1.1).clamp(0.5, 3.0);
                        } else {
                          _canvasScale = (_canvasScale / 1.1).clamp(0.5, 3.0);
                        }
                      });
                    }
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final boardPos = _screenToBoardCoordinates(
                        details.localPosition,
                      );
                      if (!BoardUtils.isInsideBoard(boardPos, _boardSize)) return;
                      _onTapBoard(boardPos);
                    },
                    onScaleStart: (details) {
                      if (_selectedTool == ToolType.pan) {
                        _dragStartLocal = details.focalPoint;
                        _dragStartObjectPos = _canvasOffset;
                        _initialScale = _canvasScale;
                      } else if (_selectedTool == ToolType.selection) {
                        final boardPos = _screenToBoardCoordinates(
                          details.localFocalPoint,
                        );
                        if (!BoardUtils.isInsideBoard(boardPos, _boardSize)) return;
                        final idx = BoardUtils.findObjectAt(boardPos, _objects);
                        final pathIdx = BoardUtils.findPathAt(boardPos, _paths);
                        if (idx != null &&
                            _selectedObjectIndices.contains(idx)) {
                          _dragStartPointer = boardPos;
                          _dragStartPositions = {
                            for (final i in _selectedObjectIndices)
                              i: _objects[i].position,
                          };
                          _dragStartPathPoints = {
                            for (final i in _selectedPathIndices)
                              i: List<Offset>.from(_paths[i].points),
                          };
                        } else if (pathIdx != null &&
                            _selectedPathIndices.contains(pathIdx)) {
                          _dragStartPointer = boardPos;
                          _dragStartPositions = {};
                          _dragStartPathPoints = {
                            for (final i in _selectedPathIndices)
                              i: List<Offset>.from(_paths[i].points),
                          };
                        } else if (idx == null && pathIdx == null) {
                          _onSelectionBoxStart(boardPos);
                        }
                      } else if (_selectedTool == ToolType.draw) {
                        _onScaleStart(
                          ScaleStartDetails(
                            localFocalPoint: _screenToBoardCoordinates(
                              details.localFocalPoint,
                            ),
                          ),
                        );
                      } else {
                        _onScaleStart(
                          ScaleStartDetails(
                            localFocalPoint: _screenToBoardCoordinates(
                              details.localFocalPoint,
                            ),
                          ),
                        );
                      }
                    },
                    onScaleUpdate: (details) {
                      if (_selectedTool == ToolType.pan &&
                          _dragStartLocal != null &&
                          _dragStartObjectPos != null) {
                        setState(() {
                          _canvasScale = (_initialScale * details.scale).clamp(
                            0.5,
                            3.0,
                          );
                          final Offset rawOffset =
                              _dragStartObjectPos! +
                              (details.focalPoint - _dragStartLocal!);
                          _canvasOffset = rawOffset;
                        });
                      } else if (_selectedTool == ToolType.selection &&
                          _dragStartPointer != null &&
                          (_dragStartPositions != null ||
                              _dragStartPathPoints != null)) {
                        final boardPos = _screenToBoardCoordinates(
                          details.localFocalPoint,
                        );
                        if (!BoardUtils.isInsideBoard(boardPos, _boardSize)) return;
                        final delta = (boardPos - _dragStartPointer!);
                        setState(() {
                          if (_dragStartPositions != null) {
                            for (final i in _selectedObjectIndices) {
                              final start = _dragStartPositions![i]!;
                              _objects[i] = _objects[i].copyWith(
                                position: start + delta,
                              );
                            }
                          }
                          if (_dragStartPathPoints != null) {
                            for (final i in _selectedPathIndices) {
                              final startPoints = _dragStartPathPoints![i]!;
                              _paths[i] = DrawPath(
                                points: startPoints.map((p) => p + delta).toList(),
                                color: _paths[i].color,
                                strokeWidth: _paths[i].strokeWidth,
                              );
                            }
                          }
                        });
                      } else if (_selectedTool == ToolType.selection &&
                          _selectionBoxStart != null) {
                        final boardPos = _screenToBoardCoordinates(
                          details.localFocalPoint,
                        );
                        if (!BoardUtils.isInsideBoard(boardPos, _boardSize)) return;
                        _onSelectionBoxUpdate(boardPos);
                      } else if (_selectedTool == ToolType.draw && _isDrawing) {
                        _onScaleUpdate(
                          ScaleUpdateDetails(
                            localFocalPoint: _screenToBoardCoordinates(
                              details.localFocalPoint,
                            ),
                          ),
                        );
                      } else if (_draggingObjectIndex != null &&
                          _dragStartLocal != null) {
                        _onScaleUpdate(
                          ScaleUpdateDetails(
                            localFocalPoint: _screenToBoardCoordinates(
                              details.localFocalPoint,
                            ),
                          ),
                        );
                      }
                    },
                    onScaleEnd: (details) {
                      if (_selectedTool == ToolType.pan) {
                        _dragStartLocal = null;
                        _dragStartObjectPos = null;
                      } else if (_selectedTool == ToolType.selection &&
                          _dragStartPointer != null &&
                          (_dragStartPositions != null ||
                              _dragStartPathPoints != null)) {
                        _dragStartPointer = null;
                        _dragStartPositions = null;
                        _dragStartPathPoints = null;
                      } else if (_selectedTool == ToolType.selection &&
                          _selectionBoxStart != null) {
                        _onSelectionBoxEnd();
                      } else if (_selectedTool == ToolType.draw && _isDrawing) {
                        _onScaleEnd(ScaleEndDetails());
                      } else if (_draggingObjectIndex != null &&
                          _dragStartLocal != null) {
                        _onScaleEnd(ScaleEndDetails());
                      }
                    },
                    child: Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..translate(effectiveOffset.dx, effectiveOffset.dy)
                            ..scale(_canvasScale),
                          child: Stack(
                            children: [
                              // Доска
                              Container(
                                width: _boardSize.width,
                                height: _boardSize.height,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              // Paths (рисование)
                              ..._paths.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final path = entry.value;
                                final isSelected = _selectedPathIndices
                                    .contains(idx);
                                return Stack(
                                  children: [
                                    CustomPaint(
                                      size: _boardSize,
                                      painter: BoardPainter([path]),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        left: BoardUtils.boundingBoxForPath(
                                          path,
                                        ).left,
                                        top: BoardUtils.boundingBoxForPath(
                                          path,
                                        ).top,
                                        child: DashedRect(
                                          color: Colors.blue,
                                          strokeWidth: 2,
                                          gap: 6,
                                          width: BoardUtils.boundingBoxForPath(
                                            path,
                                          ).width,
                                          height: BoardUtils.boundingBoxForPath(
                                            path,
                                          ).height,
                                        ),
                                      ),
                                  ],
                                );
                              }),
                              // Board objects
                              ..._objects.asMap().entries.map((entry) {
                                final obj = entry.value;
                                final idx = entry.key;
                                final isSelected = _selectedObjectIndices
                                    .contains(idx);
                                return Positioned(
                                  left: obj.position.dx,
                                  top: obj.position.dy,
                                  child: BoardObjectWidget(
                                    object: obj,
                                    isSelected: isSelected,
                                    onResize: isSelected
                                        ? (direction, details) {
                                            _handleResize(
                                              idx,
                                              direction,
                                              details,
                                            );
                                          }
                                        : null,
                                  ),
                                );
                              }),
                              // Selection box
                              if (_selectionBoxStart != null &&
                                  _selectionBoxEnd != null)
                                Positioned(
                                  left: min(
                                    _selectionBoxStart!.dx,
                                    _selectionBoxEnd!.dx,
                                  ),
                                  top: min(
                                    _selectionBoxStart!.dy,
                                    _selectionBoxEnd!.dy,
                                  ),
                                  child: IgnorePointer(
                                    child: DashedRect(
                                      color: Colors.blue,
                                      strokeWidth: 2,
                                      gap: 6,
                                      width:
                                          (_selectionBoxStart!.dx -
                                                  _selectionBoxEnd!.dx)
                                              .abs(),
                                      height:
                                          (_selectionBoxStart!.dy -
                                                  _selectionBoxEnd!.dy)
                                              .abs(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Панель инструментов и действия всегда поверх
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToolbar(),
                    if (_selectedTool == ToolType.draw)
                      _buildDrawColorPicker(context),
                    if (hasSelection) _buildSelectionActions(context),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar() {
    return Toolbar(
      selectedTool: _selectedTool,
      onToolSelected: _onToolSelected,
      rectColor: _rectColor,
      circleColor: _circleColor,
      textColor: _textColor,
      onRectColorChanged: (color) => setState(() => _rectColor = color),
      onCircleColorChanged: (color) => setState(() => _circleColor = color),
      onTextColorChanged: (color) => setState(() => _textColor = color),
    );
  }

  Widget _buildDrawColorPicker(BuildContext context) {
    return DrawColorPicker(
      drawColor: _drawColor,
      onColorChanged: (color) => setState(() => _drawColor = color),
    );
  }

  Widget _buildSelectionActions(BuildContext context) {
    return SelectionActions(
      onDelete: _deleteSelected,
      currentColor: _colorPickerValue,
      onColorChanged: _setColorForSelected,
    );
  }
}
