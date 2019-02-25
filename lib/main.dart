import 'package:bloc/bloc.dart';
import 'package:blocks/LoadingIndicator.dart';
import 'package:blocks/blocks/PostBloc.dart';
import 'package:blocks/events/PostEvent.dart';
import 'package:blocks/models/Post.dart';
import 'package:blocks/states/PostState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'package:http/http.dart' as http;

class SimpleBlocDelegate extends BlocDelegate {
  @override
  void onTransition(Transition transition) {
    print(transition);
  }
}


void main() {
  BlocSupervisor().delegate = SimpleBlocDelegate();
  //runApp(App(userRepository: UserRepository()));
  runApp(InfinityBlocApp());
}

class App extends StatefulWidget {
  final UserRepository userRepository;

  App({Key key, @required this.userRepository}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}



class _AppState extends State<App> {
  AuthenticationBloc authenticationBloc;
  UserRepository get userRepository => widget.userRepository;

  @override
  void initState() {
    authenticationBloc = AuthenticationBloc(userRepository: userRepository);
    authenticationBloc.dispatch(AppStarted());
    super.initState();
  }

  @override
  void dispose() {
    authenticationBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthenticationBloc>(
      bloc: authenticationBloc,
      child: MaterialApp(
        home: BlocBuilder<AuthenticationEvent, AuthenticationState>(
          bloc: authenticationBloc,
          builder: (BuildContext context, AuthenticationState state) {
            if (state is AuthenticationUninitialized) {
              return SplashPage();
            }
            if (state is AuthenticationAuthenticated) {
              return HomePage();
            }
            if (state is AuthenticationUnauthenticated) {
              return LoginPage(userRepository: userRepository);
            }
            if (state is AuthenticationLoading) {
              return LoadingIndicator();
            }
          },
        ),
      ),
    );
  }
}

class InfinityBlocApp extends StatelessWidget {
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'Flutter infinity scroll',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Posts'),
        ),
        body: InfinityPage(),
      ),
    );
  }
}

class InfinityPage extends StatefulWidget {
  @override
  InfinityPageState createState() => InfinityPageState();
}

class InfinityPageState extends State<InfinityPage>{
  final _scrollController =ScrollController();
  final PostBloc _postBloc = PostBloc(httpClient: http.Client());
  final _scrollThreshold = 200.0;

  InfinityPageState(){
    _scrollController.addListener(_onScroll);
    _postBloc.dispatch(Fetch());
  }
  @override
  Widget build(BuildContext context){
    return BlocBuilder(
      bloc: _postBloc,
      builder: (BuildContext context, PostState state){
        if(state is PostUninitialized){
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if(state is PostError){
          return Center(
            child: Text('failed to fetch posts'),
          );
        }

        if(state is PostLoaded){
          if(state.posts.isEmpty){
            return Center(
              child: Text('no posts'),
            );
          }
          return ListView.builder(
            itemBuilder: (BuildContext context, int index){
              return index >=state.posts.length ? BottomLoader() : PostWidget(post:state.posts[index]);
            },
            itemCount: state.hasReachedMax ? state.posts.length :state.posts.length + 1,
            controller: _scrollController,
          );
        }
      },
    );
  }

  @override
  void dispose(){
    _postBloc.dispose();
    super.dispose();
  }

  void _onScroll(){
    final maxScroll =_scrollController.position.maxScrollExtent;
    final currentScroll =_scrollController.position.pixels;

    if(maxScroll - currentScroll <=_scrollThreshold){
      _postBloc.dispatch(Fetch());
    }
  }
}

class BottomLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context){
    return Container(
      alignment: Alignment.center,
      child: Center(
        child: SizedBox(
          width: 33,
          height: 33,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
          ),
        ),
      ),
    );
  }
}

class PostWidget extends StatelessWidget {
  final Post post;

  const PostWidget({Key key, @required this.post}) : super(key:key);
  @override
  Widget build(BuildContext context){
    return ListTile(
      leading: Text('${post.id}',style: TextStyle(fontSize: 10.0),),
      title: Text(post.title),
      isThreeLine: true,
      subtitle: Text(post.body),
      dense: true,
    );
  }
}