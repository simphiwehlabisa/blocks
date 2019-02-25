import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:blocks/events/PostEvent.dart';
import 'package:blocks/models/Post.dart';
import 'package:blocks/states/PostState.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

class  PostBloc extends Bloc<PostEvent, PostState> {
  final http.Client httpClient;

  PostBloc({@required this.httpClient});

  @override
  PostState get initialState => PostUninitialized();

  @override
  Stream<PostState> mapEventToState(
    PostState currentState,
    PostEvent event,
  ) async* {
    if(event is Fetch && !_hasReachedMax(currentState)){
      try {
        if(currentState is PostUninitialized){
          final posts = await _fetchPosts(0,20);
          yield PostLoaded(posts: posts, hasReachedMax: false);
        }
        if(currentState is PostLoaded){
          final posts = await _fetchPosts(currentState.posts.length, 20);
          yield posts.isEmpty ? currentState.copyWith(hasReachedMax: true)
          : PostLoaded(posts: currentState.posts + posts, hasReachedMax: false);
        }
      } catch (e) {
        yield PostError();
      }
    }
  }

  bool _hasReachedMax(PostState state) => state is PostLoaded && state.hasReachedMax;

  Future<List<Post>> _fetchPosts(int startIndex, int limit) async{
    final response =await httpClient.get("https://jsonplaceholder.typicode.com/posts?_start=$startIndex&_limit=$limit");
    if(response.statusCode == 200){
      final data = json.decode(response.body) as List;
      return data.map((rawPost) {
        return Post(
          id:rawPost['id'],
          title:rawPost['title'],
          body:rawPost['body'],
        );
      }).toList();
    }else{
      throw Exception('Error Fetching Posts');
    }
  }

  @override
  Stream<PostEvent> transform(Stream<PostEvent> events){
    return (events as Observable<PostEvent>).debounce(Duration(milliseconds: 500));
  }

}