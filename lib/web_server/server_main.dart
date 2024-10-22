import 'dart:io';
import 'package:home_cinema_app/repository/db.dart';
import 'package:home_cinema_app/service/movie_detail_generator.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
Future<void> startServer() async  {
  // Create a router
  final router = Router();

  // Define a simple GET endpoint
  router.get('/hello', (Request request) async {
    List<Map<String, dynamic>> folders = await loadAllUserDefaultDESCInTime();
    return Response.ok('Hello, World! $folders');
  });

  // Define a POST endpoint
  router.post('/echo', (Request request) async {
    final payload = await request.readAsString();
    return Response.ok('Received: $payload');
  });

  // Define a PUT endpoint
  router.put('/update', (Request request) async {
    final payload = await request.readAsString();
    return Response.ok('Updated: $payload');
  });

  // Define a DELETE endpoint
  router.delete('/delete', (Request request) {
    return Response.ok('Deleted');
  });

  // Create a handler that includes the router
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  // Start the server on port 8080
  final server = await io.serve(handler, InternetAddress.anyIPv4, 12138);
  print('Server listening on port ${server.port}');
}