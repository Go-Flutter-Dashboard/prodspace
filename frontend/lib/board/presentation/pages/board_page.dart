import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import '../../domain/models/board_models.dart';
import '../../domain/utils/board_utils.dart';
import '../widgets/toolbar.dart';
import '../widgets/selection_actions.dart';
import '../widgets/draw_color_picker.dart';
import '../widgets/board_object_widget.dart';
import '../widgets/board_painter.dart';
import '../widgets/dashed_rect.dart';
import '../widgets/color_picker_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BordPageState();
}

class _BordPageState extends State<BoardPage> {
  final List<BoardObject> _objects = [];
  final List<DrawPath> _paths = [];
  ToolType _selectedTool = ToolType.selection;
  int? _draggingObjectIndex;
  Set<int> _selectedObjectIndices = {};
  Offset? _dragStartLocal;
  Offset? _dragStartObjectPos;
  String _pendingText = '';
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
  Color _objectColor = Colors.blue;
  Color _rectColor = Colors.blue;
  Color _circleColor = Colors.green;
  Color _textColor = Colors.black;
  static const Size _boardSize = Size(2000, 2000);
  Offset _canvasOffset = Offset.zero;
  double _canvasScale = 1.0;
  double _initialScale = 1.0;

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
          _objects.add(BoardObject(
            type: BoardObjectType.rectangle,
            position: boardPos,
            size: const Size(120, 80),
            color: _rectColor,
          ));
        });
        break;
      case ToolType.circle:
        setState(() {
          _objects.add(BoardObject(
            type: BoardObjectType.circle,
            position: boardPos,
            size: const Size(90, 90),
            color: _circleColor,
          ));
        });
        break;
      case ToolType.text:
        final text = await _showTextInputDialog();
        if (text != null && text.isNotEmpty) {
          setState(() {
            _objects.add(BoardObject(
              type: BoardObjectType.text,
              position: boardPos,
              size: const Size(160, 50),
              color: _textColor,
              text: text,
            ));
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
            _objects.add(BoardObject(
              type: BoardObjectType.image,
              position: boardPos,
              size: const Size(160, 120),
              color: Colors.transparent,
              imageBytes: bytes,
            ));
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
          title: const Text('Введите текст'),
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
        final Offset boardPos = details.localFocalPoint / _boardSize.width * 2000;
        _currentPath = DrawPath([
          boardPos
        ], _drawColor, 3.0);
        _paths.add(_currentPath!);
      });
      return;
    }
    _draggingObjectIndex = BoardUtils.findObjectAt(details.localFocalPoint, _objects);
    if (_draggingObjectIndex != null) {
      _dragStartLocal = details.localFocalPoint;
      _dragStartObjectPos = _objects[_draggingObjectIndex!].position;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_selectedTool == ToolType.draw && _isDrawing && _currentPath != null) {
      setState(() {
        final Offset boardPos = details.localFocalPoint / _boardSize.width * 2000;
        _currentPath!.points.add(boardPos);
      });
      return;
    }
    if (_draggingObjectIndex != null && _dragStartLocal != null && _dragStartObjectPos != null && details.pointerCount == 1) {
      setState(() {
        final delta = (details.localFocalPoint - _dragStartLocal!) / _boardSize.width * 2000;
        _objects[_draggingObjectIndex!] = _objects[_draggingObjectIndex!].copyWith(
          position: _dragStartObjectPos! + delta,
        );
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_selectedTool == ToolType.draw && _isDrawing) {
      setState(() {
        _isDrawing = false;
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
      if (box.overlaps(objRect) || box.contains(objRect.topLeft) || box.contains(objRect.bottomRight)) {
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
        ..forEach((i) => _objects.removeAt(i));
      _selectedPathIndices.toList()
        ..sort((a, b) => b.compareTo(a))
        ..forEach((i) => _paths.removeAt(i));
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
        _paths[i] = DrawPath(_paths[i].points, color, _paths[i].strokeWidth);
      }
      _colorPickerValue = color;
    });
  }

  // Преобразование координат экрана в координаты доски
  Offset _screenToBoardCoordinates(Offset screenPos) {
    return BoardUtils.screenToBoardCoordinates(screenPos, _canvasOffset, _canvasScale);
  }

  void _handleResize(int idx, ResizeDirection direction, DragUpdateDetails details) {
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

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedObjectIndices.isNotEmpty || _selectedPathIndices.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Интерактивная доска')),
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
                      final boardPos = _screenToBoardCoordinates(details.localPosition);
                      if (!BoardUtils.isInsideBoard(boardPos, _boardSize)) return;
                      _onTapBoard(boardPos);
                    },
                    onScaleStart: (details) {
                      if (_selectedTool == ToolType.pan) {
                        _dragStartLocal = details.focalPoint;
                        _dragStartObjectPos = _canvasOffset;
                        _initialScale = _canvasScale;
                      } else if (_selectedTool == ToolType.selection) {
                        final boardPos = _screenToBoardCoordinates(details.localFocalPoint);
                        if (!BoardUtils.isInsideBoard(boardPos, _boardSize)) return;
                        final idx = BoardUtils.findObjectAt(boardPos, _objects);
                        final pathIdx = BoardUtils.findPathAt(boardPos, _paths);
                        if (idx != null && _selectedObjectIndices.contains(idx)) {
                          _dragStartPointer = boardPos;
                          _dragStartPositions = {
                            for (final i in _selectedObjectIndices)
                              i: _objects[i].position
                          };
                          _dragStartPathPoints = {
                            for (final i in _selectedPathIndices)
                              i: List<Offset>.from(_paths[i].points)
                          };
                        } else if (pathIdx != null && _selectedPathIndices.contains(pathIdx)) {
                          _dragStartPointer = boardPos;
                          _dragStartPositions = {};
                          _dragStartPathPoints = {
                            for (final i in _selectedPathIndices)
                              i: List<Offset>.from(_paths[i].points)
                          };
                        } else if (idx == null && pathIdx == null) {
                          _onSelectionBoxStart(boardPos);
                        }
                      } else if (_selectedTool == ToolType.draw) {
                        _onScaleStart(ScaleStartDetails(localFocalPoint: _screenToBoardCoordinates(details.localFocalPoint)));
                      } else {
                        _onScaleStart(ScaleStartDetails(localFocalPoint: _screenToBoardCoordinates(details.localFocalPoint)));
                      }
                    },
                    onScaleUpdate: (details) {
                      if (_selectedTool == ToolType.pan && _dragStartLocal != null && _dragStartObjectPos != null) {
                        setState(() {
                          _canvasScale = (_initialScale * details.scale).clamp(0.5, 3.0);
                          final Offset rawOffset = _dragStartObjectPos! + (details.focalPoint - _dragStartLocal!);
                          _canvasOffset = rawOffset;
                        });
                      } else if (_selectedTool == ToolType.selection && _dragStartPointer != null && (_dragStartPositions != null || _dragStartPathPoints != null)) {
                        final boardPos = _screenToBoardCoordinates(details.localFocalPoint);
                        if (!BoardUtils.isInsideBoard(boardPos, _boardSize)) return;
                        final delta = (boardPos - _dragStartPointer!);
                        setState(() {
                          if (_dragStartPositions != null) {
                            for (final i in _selectedObjectIndices) {
                              final start = _dragStartPositions![i]!;
                              _objects[i] = _objects[i].copyWith(position: start + delta);
                            }
                          }
                          if (_dragStartPathPoints != null) {
                            for (final i in _selectedPathIndices) {
                              final startPoints = _dragStartPathPoints![i]!;
                              _paths[i] = DrawPath(
                                startPoints.map((p) => p + delta).toList(),
                                _paths[i].color,
                                _paths[i].strokeWidth,
                              );
                            }
                          }
                        });
                      } else if (_selectedTool == ToolType.selection && _selectionBoxStart != null) {
                        final boardPos = _screenToBoardCoordinates(details.localFocalPoint);
                        if (!BoardUtils.isInsideBoard(boardPos, _boardSize)) return;
                        _onSelectionBoxUpdate(boardPos);
                      } else if (_selectedTool == ToolType.draw && _isDrawing) {
                        _onScaleUpdate(ScaleUpdateDetails(localFocalPoint: _screenToBoardCoordinates(details.localFocalPoint)));
                      } else if (_draggingObjectIndex != null && _dragStartLocal != null) {
                        _onScaleUpdate(ScaleUpdateDetails(localFocalPoint: _screenToBoardCoordinates(details.localFocalPoint)));
                      }
                    },
                    onScaleEnd: (details) {
                      if (_selectedTool == ToolType.pan) {
                        _dragStartLocal = null;
                        _dragStartObjectPos = null;
                      } else if (_selectedTool == ToolType.selection && _dragStartPointer != null && (_dragStartPositions != null || _dragStartPathPoints != null)) {
                        _dragStartPointer = null;
                        _dragStartPositions = null;
                        _dragStartPathPoints = null;
                      } else if (_selectedTool == ToolType.selection && _selectionBoxStart != null) {
                        _onSelectionBoxEnd();
                      } else if (_selectedTool == ToolType.draw && _isDrawing) {
                        _onScaleEnd(ScaleEndDetails());
                      } else if (_draggingObjectIndex != null && _dragStartLocal != null) {
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
                                  border: Border.all(color: Colors.grey, width: 3),
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
                                final isSelected = _selectedPathIndices.contains(idx);
                                return Stack(
                                  children: [
                                    CustomPaint(
                                      size: _boardSize,
                                      painter: BoardPainter([path]),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        left: BoardUtils.boundingBoxForPath(path).left,
                                        top: BoardUtils.boundingBoxForPath(path).top,
                                        child: DashedRect(
                                          color: Colors.blue,
                                          strokeWidth: 2,
                                          gap: 6,
                                          width: BoardUtils.boundingBoxForPath(path).width,
                                          height: BoardUtils.boundingBoxForPath(path).height,
                                        ),
                                      ),
                                  ],
                                );
                              }).toList(),
                              // Board objects
                              ..._objects.asMap().entries.map((entry) {
                                final obj = entry.value;
                                final idx = entry.key;
                                final isSelected = _selectedObjectIndices.contains(idx);
                                return Positioned(
                                  left: obj.position.dx,
                                  top: obj.position.dy,
                                  child: BoardObjectWidget(
                                    object: obj,
                                    isSelected: isSelected,
                                    onResize: isSelected ? (direction, details) {
                                      _handleResize(idx, direction, details);
                                    } : null,
                                  ),
                                );
                              }).toList(),
                              // Selection box
                              if (_selectionBoxStart != null && _selectionBoxEnd != null)
                                Positioned(
                                  left: min(_selectionBoxStart!.dx, _selectionBoxEnd!.dx),
                                  top: min(_selectionBoxStart!.dy, _selectionBoxEnd!.dy),
                                  child: IgnorePointer(
                                    child: DashedRect(
                                      color: Colors.blue,
                                      strokeWidth: 2,
                                      gap: 6,
                                      width: (_selectionBoxStart!.dx - _selectionBoxEnd!.dx).abs(),
                                      height: (_selectionBoxStart!.dy - _selectionBoxEnd!.dy).abs(),
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
                    if (_selectedTool == ToolType.draw) _buildDrawColorPicker(context),
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
