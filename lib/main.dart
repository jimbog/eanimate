import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

enum FileMenu { save, saveAs, share }

const double EMOJI_SIZE = 100;
const double SIDEBARW = 100;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Animator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider<AnimationGame>(
        create: (_) => AnimationGame(),
        child: const MyHomePage(title: 'Animator 2'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FileMenu? selectedMenu;
  @override
  Widget build(BuildContext context) {
    return Consumer<AnimationGame>(builder: (context, gamep, child) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          actions: [
            IconButton(
              onPressed: () {
                gamep.isRecording = !gamep.isRecording;
              },
              tooltip: 'Record',
              icon: Icon(Icons.circle,
                  color: gamep.isRecording
                      ? Colors.red
                      : Color.fromARGB(190, 244, 67, 54)),
            ),
            IconButton(
              onPressed: () {
                gamep.isPlaying = !gamep.isPlaying;
                // gamep.setCurrentFrame(gamep.currentFrame);
              },
              tooltip: gamep.isPlaying ? 'Pause' : 'Play',
              icon: Icon(gamep.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              onPressed: () {
                gamep.isRecording = false;
                gamep.isPlaying = false;

                gamep.frameZero();
              },
              tooltip: 'Stop',
              icon: const Icon(Icons.stop),
            ),
            PopupMenuButton<FileMenu>(
              initialValue: selectedMenu,
              // Callback that sets the selected popup menu item.
              onSelected: (FileMenu item) {
                selectedMenu = item;
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<FileMenu>>[
                const PopupMenuItem<FileMenu>(
                  value: FileMenu.save,
                  child: Text('Save 💾'),
                ),
                const PopupMenuItem<FileMenu>(
                  value: FileMenu.saveAs,
                  child: Text('Save as'),
                ),
                const PopupMenuItem<FileMenu>(
                  value: FileMenu.share,
                  child: Text('Share 📣'),
                ),
              ],
            ),
          ],
          title: Slider(
            min: 0,
            max: gamep.lastRecordedFrame.toDouble(),
            value: gamep.currentFrame.toDouble(),
            onChanged: (value) {
              gamep.setCurrentFrame(value.toInt());
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    child: sideBar(gamep, context),
                    color: const Color.fromARGB(115, 33, 149, 243),
                    width: SIDEBARW,
                  ),
                  Expanded(
                    child: GameWidget(
                      game: gamep,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

Widget sideBar(AnimationGame provider, BuildContext context) {
  return Column(children: [
    Column(
      children: [
        //genAiIconButton
        IconButton.filledTonal(
          iconSize: 40,
          onPressed: () async {
            TextEditingController sceneDescriptionController =
                TextEditingController();
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Welcome to Generative Scene'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: [
                        const Text('Please describe your scene:'),
                        TextField(
                          controller: sceneDescriptionController,
                          maxLines: null,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Generate'),
                      onPressed: () async {
                        const apiKey =  String.fromEnvironment('GEMINI_API_KEY');
                        final model = GenerativeModel(
                          model: 'gemini-1.5-flash-latest',
                          apiKey: apiKey,
                        );

                        final prompt = '''
          give me a list of emojis that i need to generate a scene for the text in SCENE tags. the output should be in json with the name of each emoji next to the emoji itself.  It is important to reply only with the json data.
          Follow this example:
          INPUT: <SCENE>"a scene of a man and a woman outside of a house"</SCENE>
          OUTPUT: { "man": "👨", "woman": "👩", "house": "🏠", "tree": "🌳", "sun": "☀️", "cloud": "☁️"}
          
          INPUT: <SCENE>"${sceneDescriptionController.text}"</SCENE>
          ''';
                        final content = [Content.text(prompt)];
                        final response = await model.generateContent(content);

                        if (response.text!.isNotEmpty) {
                          final Map<String, dynamic> emojis =
                              jsonDecode(response.text!);
                          emojis.length;
                          int i = 0;
                          for (var key in emojis.keys) {
                            provider.addEmojiVO(
                                emoji: emojis[key],
                                game: provider,
                                position: provider.size -
                                    Vector2.all(i * EMOJI_SIZE / 2));
                            i++;
                          }
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
          icon: const Icon(
            //generate scene
            Icons.generating_tokens,
            // color: Colors.green,
          ),
        ),

        //emojiTextField
        TextField(
          maxLines: 1,
          // maxLength: 1,
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              fillColor: Color.fromARGB(102, 104, 128, 215),
              filled: true),
          onSubmitted: (value) {
            provider.addEmojiVO(
                emoji: value, game: provider, position: provider.size);
          },
        ),
      ],
    ),
    // Text(provider.visualObjects.length.toString()),
    if (provider.visualObjects.isEmpty)
      Text(".....")
    else
      Expanded(
        child: ListView(
          children: [
            for (var vo in provider.visualObjects)
              ListTile(
                leading: switch (vo) {
                  EmojiObject() => Text(vo.text),
                },
                // title: IconButton(onPressed: (){
                //   provider.selectedVOs.remove(vo);
                //   provider.remove(vo);
                // } , icon: const Icon(Icons.delete)) ,
                trailing: Checkbox(
                    onChanged: (value) {
                      if (provider.selectedVOs.contains(vo)) {
                        provider.selectedVOs.remove(vo);
                      } else {
                        provider.selectedVOs.add(vo);
                      }
                    },
                    value: provider.selectedVOs.contains(vo)),
              )
          ],
        ),
      ),
  ]);
}

class AnimationGame extends FlameGame with ScaleDetector, ChangeNotifier {
  var _isRecording = false;
  bool get isRecording => _isRecording;
  set isRecording(bool val) {
    _isRecording = val;
    notifyListeners();
  }

  var _isPlaying = false;
  bool get isPlaying => _isPlaying;
  set isPlaying(bool val) {
    _isPlaying = val;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  var _overridingRecordedStuff = <WhatToTransform>{}.lock;
  ISet<WhatToTransform> get overridingRecordedStuff => _overridingRecordedStuff;
  set overridingRecordedStuff(ISet<WhatToTransform> val) {
    _overridingRecordedStuff = val;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int _currentFrame = 0;
  int _lastRecordedFrame = 0;
  int get lastRecordedFrame => _lastRecordedFrame;
  bool get canBeginForwardPlaying =>
      isPlaying && (isRecording || (_currentFrame < _lastRecordedFrame));
  int get currentFrame => _currentFrame;

  void setCurrentFrame(int frame) {
    _currentFrame = frame;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int finalFrame = 0;
  VisualObject lastVO = EmojiObject();
  var selectedVOs = <VisualObject>{};
  var myVOs = <VisualObject>{};

  @override
  bool get debugMode => false;

  @override
  Future<void> onLoad() async {
    // camera.viewport.add(Hud());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (canBeginForwardPlaying) {
      if (isRecording && currentFrame + 1 > _lastRecordedFrame) {
        _lastRecordedFrame = currentFrame + 1;
      }
      setCurrentFrame(currentFrame + 1);
    }
  }

  void frameZero() {
    setCurrentFrame(0);
  }

  @override
  void render(Canvas canvas) {
    for (var vo in myVOs) {
      if (selectedVOs.contains(vo) &&
          isRecording &&
          overridingRecordedStuff.isNotEmpty) {
        vo.setTransformAtFrame(_currentFrame, vo.transform.clone());
      } else if (vo.history[_currentFrame] != null) {
        vo.transform.setFrom(vo.history[_currentFrame]!);
      }
    }
    super.render(canvas);
  }

  @override
  void onScaleStart(ScaleStartInfo info) {
    overridingRecordedStuff = {WhatToTransform.x, WhatToTransform.y}.lock;
    // for (var child in children) {
    //   if (child is VisualObject) {
    //     if (child.containsPoint(info.eventPosition.widget)) {
    //       selectedVOs.add(child);
    //     }
    //     // else {selectedVOs.remove(child);}
    //   }
    // }
  }

  @override
  void onScaleEnd(ScaleEndInfo info) {
    overridingRecordedStuff = ISet<WhatToTransform>();
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    var currentScale = info.scale.global;

    for (var vo in selectedVOs) {
      if (!currentScale.isIdentity()) {
        print(vo.scale);
        vo.scale = Vector2.all(info.scale.global.x);
      } else {
        vo.move(info.delta.global);
      }
    }
    notifyListeners();
  }

  var visualObjects = <VisualObject>[].lock;
  void addEmojiVO(
      {String emoji = '😀',
      required AnimationGame game,
      required Vector2 position}) {
    game.frameZero();
    var vo = EmojiObject()
      ..position = position
      ..anchor = Anchor.center
      ..text = emoji
      ..textRenderer = TextPaint(style: const TextStyle(fontSize: EMOJI_SIZE));

    vo.setTransformAtFrame(0, vo.transform.clone());
    game.add(vo);
    game.lastVO = vo;
    game.myVOs.add(vo);
    game.selectedVOs.add(vo);
    visualObjects = visualObjects.add(vo);
  }
}

enum WhatToTransform { x, y, scale, rot }

sealed class VisualObject extends PositionComponent {
  abstract Map<int, Transform2D> history;
  void setTransformAtFrame(int f, Transform2D transform2d);
  void move(Vector2 dxdy) {}
}

class EmojiObject extends TextComponent implements VisualObject {
  @override
  var history = <int, Transform2D>{};

  @override
  void move(Vector2 dxdy) {
    position.add(dxdy);
  }

  @override
  void setTransformAtFrame(int f, Transform2D transform2d) {
    history[f] = transform2d;
  }
}

class Hud extends PositionComponent with HasGameRef<AnimationGame> {
  Hud({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority = 5,
  });

  late TextComponent _currentFrameTextComponent;

  @override
  Future<void> onLoad() async {
    _currentFrameTextComponent = TextComponent(
      text:
          'play:${game.isPlaying} rec:${game.isRecording} ${game.currentFrame}',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Color.fromRGBO(119, 255, 0, 1),
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(game.size.x - 160, 20),
    );
    add(_currentFrameTextComponent);
  }

  @override
  void update(double dt) {
    _currentFrameTextComponent.text =
        'play:${game.isPlaying} rec:${game.isRecording} ${game.currentFrame}';
  }
}
