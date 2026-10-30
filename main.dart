import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const bg = Color(0xFF090D1B);
const panel = Color(0xFF151D33);
const cyan = Color(0xFF43D9FF);
const violet = Color(0xFF8B6CFF);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    // The app remains playable offline until Firebase is configured.
  }
  runApp(BrainxApp(firebaseReady: firebaseReady));
}

class BrainxApp extends StatelessWidget {
  final bool firebaseReady;
  const BrainxApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'BRAINX',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: cyan, brightness: Brightness.dark),
      useMaterial3: true,
      fontFamily: 'Roboto',
    ),
    home: HomeScreen(firebaseReady: firebaseReady),
  );
}

class GameInfo {
  final String title, subtitle, icon, type;
  final Color color;
  const GameInfo(this.title, this.subtitle, this.icon, this.type, this.color);
}
const games = [
  GameInfo('Number Rush', 'Solve before time runs out', '⚡', 'math', cyan),
  GameInfo('Memory Matrix', 'Remember the pattern', '🧠', 'memory', violet),
  GameInfo('Odd One Out', 'Spot the different symbol', '🔎', 'odd', Color(0xFFFFB454)),
  GameInfo('Quick Logic', 'Choose the logical answer', '♟', 'logic', Color(0xFF52E0A1)),
];

class HomeScreen extends StatefulWidget {
  final bool firebaseReady;
  const HomeScreen({super.key, required this.firebaseReady});
  @override State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int points = 0, played = 0;
  String player = 'Guest Player';
  List<Map<String, dynamic>> scores = [];
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      points = p.getInt('points') ?? 0;
      played = p.getInt('played') ?? 0;
      player = p.getString('player') ?? 'Guest Player';
      scores = (p.getStringList('scores') ?? []).map((e) {
        final a = e.split('|'); return {'name': a[0], 'score': int.tryParse(a.length > 1 ? a[1] : '') ?? 0};
      }).toList()..sort((a,b) => (b['score'] as int).compareTo(a['score'] as int));
    });
  }
  Future<void> _saveResult(int score) async {
    final p = await SharedPreferences.getInstance();
    points += score; played++;
    scores.add({'name': player, 'score': score});
    scores.sort((a,b) => (b['score'] as int).compareTo(a['score'] as int));
    if (scores.length > 30) scores = scores.take(30).toList();
    await p.setInt('points', points); await p.setInt('played', played);
    await p.setStringList('scores', scores.map((e) => '${e['name']}|${e['score']}').toList());
    if (widget.firebaseReady && FirebaseAuth.instance.currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('scores').add({
          'uid': FirebaseAuth.instance.currentUser!.uid,
          'displayName': player, 'score': score,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }
  Future<void> _setName() async {
    final c = TextEditingController(text: player);
    final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      title: const Text('Your player name'),
      content: TextField(controller: c, maxLength: 18, decoration: const InputDecoration(hintText: 'Enter a nickname')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('SAVE'))],
    ));
    if (name != null && name.isNotEmpty) {
      final p = await SharedPreferences.getInstance(); await p.setString('player', name);
      if (mounted) setState(() => player = name);
    }
  }
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20,18,20,12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 46,height: 46,decoration: BoxDecoration(gradient: const LinearGradient(colors:[cyan,violet]),borderRadius: BorderRadius.circular(15)),child: const Icon(Icons.bolt_rounded,color:bg,size:30)),
          const SizedBox(width:12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start,children:[Text('BRAINX',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900,letterSpacing:2)),Text('GLOBAL ARENA',style:TextStyle(fontSize:10,letterSpacing:3,color:cyan,fontWeight:FontWeight.bold))]),
          const Spacer(), IconButton(onPressed:_setName,icon:const Icon(Icons.account_circle_outlined,size:30))
        ]),
        const SizedBox(height:24),
        Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF202B4B),Color(0xFF32265A)]),borderRadius:BorderRadius.circular(24),border:Border.all(color:Colors.white10)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('WELCOME BACK, ${player.toUpperCase()}',style:const TextStyle(color:Colors.white70,fontSize:11,letterSpacing:1.2)),
          const SizedBox(height:8),const Text('Train your brain.\nBeat the world.',style:TextStyle(fontSize:27,fontWeight:FontWeight.w900,height:1.15)),
          const SizedBox(height:18),Row(children:[
            _stat('TOTAL XP','$points',Icons.stars_rounded),const SizedBox(width:22),_stat('GAMES PLAYED','$played',Icons.sports_esports_rounded)
          ])
        ])),
        const SizedBox(height:24),
        Row(children:[const Text('CHOOSE YOUR CHALLENGE',style:TextStyle(fontSize:13,fontWeight:FontWeight.w800,letterSpacing:1)),const Spacer(),Text('${games.length} MODES',style:const TextStyle(color:cyan,fontSize:10,fontWeight:FontWeight.bold))]),
        const SizedBox(height:12),
      ]))),
      SliverPadding(padding:const EdgeInsets.symmetric(horizontal:20),sliver:SliverGrid(
        delegate:SliverChildBuilderDelegate((context,i){final g=games[i];return InkWell(
          borderRadius:BorderRadius.circular(20),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>GameScreen(game:g,onFinished:_saveResult))),
          child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(20),border:Border.all(color:g.color.withOpacity(.35))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Container(width:46,height:46,decoration:BoxDecoration(color:g.color.withOpacity(.14),borderRadius:BorderRadius.circular(14)),child:Center(child:Text(g.icon,style:const TextStyle(fontSize:25)))),
            const Spacer(),Text(g.title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16)),const SizedBox(height:4),Text(g.subtitle,style:const TextStyle(color:Colors.white60,fontSize:11),maxLines:2)
          ])));
        },childCount:games.length),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:1.18))),
      SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(20,24,20,30),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[const Text('LEADERBOARD',style:TextStyle(fontSize:15,fontWeight:FontWeight.w900,letterSpacing:1)),const Spacer(),Text(widget.firebaseReady?'CLOUD READY*':'LOCAL SCORES',style:const TextStyle(color:cyan,fontSize:9,fontWeight:FontWeight.bold))]),
        const SizedBox(height:10),
        Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(18)),child:Column(children:[
          if(scores.isEmpty) const Padding(padding:EdgeInsets.all(14),child:Text('Play a game to create your first score.',style:TextStyle(color:Colors.white60))),
          ...scores.take(5).toList().asMap().entries.map((e)=>Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(children:[
            Text('#${e.key+1}',style:TextStyle(color:e.key==0?const Color(0xFFFFD166):Colors.white54,fontWeight:FontWeight.bold)),
            const SizedBox(width:12),Expanded(child:Text(e.value['name'] as String,style:const TextStyle(fontWeight:FontWeight.w600))),
            Text('${e.value['score']} XP',style:const TextStyle(color:cyan,fontWeight:FontWeight.bold))
          ])))
        ])),
        const SizedBox(height:10),
        const Text('*Cloud scores require Firebase setup and authenticated accounts. This starter build does not claim a verified global ranking.',style:TextStyle(color:Colors.white38,fontSize:10)),
      ]))),
    ])),
  );
  Widget _stat(String label,String value,IconData icon)=>Row(children:[Icon(icon,color:cyan,size:20),const SizedBox(width:7),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)),Text(label,style:const TextStyle(fontSize:9,color:Colors.white60,letterSpacing:1))])]);
}

class GameScreen extends StatefulWidget {
  final GameInfo game; final Future<void> Function(int) onFinished;
  const GameScreen({super.key,required this.game,required this.onFinished});
  @override State<GameScreen> createState()=>_GameScreenState();
}
class _GameScreenState extends State<GameScreen> {
  final random=Random();
  int score=0, round=0, seconds=30, answer=0, a=0,b=0, correct=0;
  List<int> options=[]; List<int> pattern=[]; List<int> userPattern=[];
  Timer? timer; bool ended=false, showingPattern=false;
  @override void initState(){super.initState();_next();timer=Timer.periodic(const Duration(seconds:1),(t){if(!mounted||ended)return;if(seconds<=1){t.cancel();_finish();}else setState(()=>seconds--);});}
  void _next(){
    if(round>=9){_finish();return;}
    round++; userPattern=[];
    if(widget.game.type=='math'){
      a=random.nextInt(18)+2;b=random.nextInt(12)+2;correct=a+b;
      options={correct,correct+1,correct-1,correct+random.nextInt(5)+2}.toList()..shuffle();
    }else if(widget.game.type=='odd'){
      correct=random.nextInt(4); options=List.generate(4,(i)=>i==correct?9:7);
    }else if(widget.game.type=='logic'){
      a=random.nextInt(8)+2;correct=a*2;options=[correct,correct+2,correct-1,correct+4]..shuffle();
    }else{
      pattern=List.generate(5,(_)=>random.nextInt(9));
      showingPattern=true;
      Future.delayed(const Duration(milliseconds:1500),(){if(mounted&&!ended)setState(()=>showingPattern=false);});
    }
    setState((){});
  }
  void _choose(int value){
    if(ended)return;
    bool ok;
    if(widget.game.type=='odd') ok=value==correct;
    else ok=value==correct;
    if(ok)score+=10;
    if(round>=9){_finish();}else _next();
  }
  void _finish() async{
    if(ended)return;ended=true;timer?.cancel();
    await widget.onFinished(score);
    if(!mounted)return;
    showDialog(context:context,barrierDismissible:false,builder:(_)=>AlertDialog(
      backgroundColor:panel,title:const Text('CHALLENGE COMPLETE',style:TextStyle(fontWeight:FontWeight.w900)),
      content:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.emoji_events_rounded,color:Color(0xFFFFD166),size:54),const SizedBox(height:12),Text('$score XP',style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:cyan)),Text('You completed $round rounds.',style:const TextStyle(color:Colors.white60))]),
      actions:[FilledButton(onPressed:(){Navigator.pop(context);Navigator.pop(context);},child:const Text('CONTINUE'))],
    ));
  }
  @override void dispose(){timer?.cancel();super.dispose();}
  @override Widget build(BuildContext context){
    final memory=widget.game.type=='memory';
    return Scaffold(appBar:AppBar(title:Text(widget.game.title,style:const TextStyle(fontWeight:FontWeight.w800)),backgroundColor:bg),body:SafeArea(child:Padding(padding:const EdgeInsets.all(22),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Row(children:[Text('ROUND $round / 9',style:const TextStyle(color:Colors.white60,fontWeight:FontWeight.bold)),const Spacer(),const Icon(Icons.timer_outlined,color:cyan),const SizedBox(width:5),Text('${seconds}s',style:const TextStyle(fontWeight:FontWeight.w900,color:cyan,fontSize:18))]),
      const SizedBox(height:12),ClipRRect(borderRadius:BorderRadius.circular(9),child:LinearProgressIndicator(value:seconds/30,minHeight:7,backgroundColor:panel,color:cyan)),
      const SizedBox(height:28),
      Text(memory?'MEMORIZE THE NUMBERS':widget.game.type=='math'?'WHAT IS $a + $b?':widget.game.type=='logic'?'WHAT NUMBER COMES NEXT?':'TAP THE ODD SYMBOL',textAlign:TextAlign.center,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900,letterSpacing:1)),
      const SizedBox(height:24),
      if(memory) ...[
        if(showingPattern) Text(pattern.join('   '),textAlign:TextAlign.center,style:const TextStyle(fontSize:34,fontWeight:FontWeight.w900,color:cyan,letterSpacing:2))
        else const Text('Which number was in position 3?',textAlign:TextAlign.center,style:TextStyle(color:Colors.white70)),
        const SizedBox(height:18),
        if(!showingPattern) Wrap(alignment:WrapAlignment.center,spacing:10,children:List.generate(4,(i)=>_answerButton(i+1,()=>_choose(pattern[2]==i+1?pattern[2]:-100))))
      ] else Wrap(spacing:12,runSpacing:12,alignment:WrapAlignment.center,children:options.map((v)=>_answerButton(widget.game.type=='odd'?(v==9?'●':'○'):v.toString(),()=>_choose(v))).toList()),
      const Spacer(),
      Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(16)),child:Row(children:[const Icon(Icons.stars_rounded,color:Color(0xFFFFD166)),const SizedBox(width:8),const Text('YOUR SCORE'),const Spacer(),Text('$score XP',style:const TextStyle(color:cyan,fontWeight:FontWeight.w900,fontSize:18))]))
    ]))));
  }
  Widget _answerButton(Object label,VoidCallback action)=>SizedBox(width:MediaQuery.of(context).size.width*.36,height:62,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:panel,foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),side:const BorderSide(color:Colors.white12))),onPressed:action,child:Text('$label',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800))));
}
