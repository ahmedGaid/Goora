import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'backend.dart';
import 'backend_gateway.dart';

part 'backend_providers.g.dart';

/// Fake unless `Backend.init` went live (011 research D2). Tests override it.
@Riverpod(keepAlive: true)
BackendMode backendMode(Ref ref) => Backend.mode;

/// Only read in live mode; tests override it with an in-memory gateway.
@Riverpod(keepAlive: true)
BackendGateway backendGateway(Ref ref) => Backend.gateway;
