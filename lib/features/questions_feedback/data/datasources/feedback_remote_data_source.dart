import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_processor.dart';
import '../../../../core/network/multipart_api_executor.dart';
import '../../domain/entities/feedback_image_attachment.dart';
import '../../domain/entities/feedback_post_create_draft.dart';
import '../models/feedback_post_model.dart';
import '../models/feedback_post_page_model.dart';
import '../models/feedback_comment_model.dart';
import '../models/feedback_comment_page_model.dart';

class FeedbackRemoteDataSource {
  FeedbackRemoteDataSource({
    ApiCallExecutor? apiCallExecutor,
    MultipartApiExecutor? multipartApiExecutor,
  }) : _apiCallExecutor = apiCallExecutor ?? const ApiCallExecutor(),
       _multipartApiExecutor =
           multipartApiExecutor ?? const MultipartApiExecutor();

  final ApiCallExecutor _apiCallExecutor;
  final MultipartApiExecutor _multipartApiExecutor;

  Future<FeedbackPostPageModel> getFeedbackPosts({
    required int page,
    int pageSize = 10,
    String search = '',
  }) {
    return _apiCallExecutor.processApi<FeedbackPostPageModel>(
      apiCallType: ApiCallType.get,
      endpoint: ApiEndPoints.feedbacks,
      parameters: <String, dynamic>{
        'page': page,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
      decoder: (json) {
        if (json is! Map<String, dynamic>) {
          throw const ApiError.invalidResponse();
        }

        return FeedbackPostPageModel.fromApiJson(json, pageSize: pageSize);
      },
    );
  }

  Future<void> updateFeedbackPostLike({
    required String feedbackId,
    required bool isLiked,
  }) {
    return _apiCallExecutor.processApi<void>(
      apiCallType: ApiCallType.post,
      endpoint: ApiEndPoints.feedbackLike(feedbackId),
      parameters: <String, dynamic>{'is_liked': isLiked},
      decoder: (_) {},
    );
  }

  Future<FeedbackPostModel?> updateFeedbackPost({
    required String feedbackId,
    required String title,
    required String description,
    List<FeedbackImageAttachment> attachments =
        const <FeedbackImageAttachment>[],
  }) {
    if (attachments.isEmpty) {
      return _apiCallExecutor.processApi<FeedbackPostModel?>(
        apiCallType: ApiCallType.patch,
        endpoint: ApiEndPoints.feedbackPost(feedbackId),
        parameters: <String, dynamic>{
          'title': title,
          'description': description,
        },
        decoder: _decodeUpdatedPost,
      );
    }

    return _multipartApiExecutor.process<FeedbackPostModel?>(
      method: 'PATCH',
      endpoint: ApiEndPoints.feedbackPost(feedbackId),
      fields: <String, String>{'title': title, 'description': description},
      files: attachments
          .map(
            (attachment) => MultipartApiFile(
              fieldName: 'attachments',
              fileName: attachment.fileName,
              bytes: attachment.bytes,
              contentType: attachment.contentType,
            ),
          )
          .toList(growable: false),
      decoder: _decodeUpdatedPost,
    );
  }

  Future<void> deleteFeedbackPost({required String feedbackId}) =>
      _apiCallExecutor.processApi<void>(
        apiCallType: ApiCallType.delete,
        endpoint: ApiEndPoints.feedbackPost(feedbackId),
        decoder: (_) {},
      );

  Future<FeedbackCommentPageModel> getFeedbackComments({
    required String feedbackId,
    required int page,
    int pageSize = 10,
    String? parentId,
  }) {
    return _apiCallExecutor.processApi<FeedbackCommentPageModel>(
      apiCallType: ApiCallType.get,
      endpoint: ApiEndPoints.feedbackComments(feedbackId),
      parameters: <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (parentId?.trim().isNotEmpty == true) 'parent': parentId!.trim(),
      },
      decoder: (json) {
        if (json is! Map<String, dynamic>) {
          throw const ApiError.invalidResponse();
        }
        return FeedbackCommentPageModel.fromApiJson(json, pageSize: pageSize);
      },
    );
  }

  Future<FeedbackCommentModel> addFeedbackComment({
    required String feedbackId,
    required String content,
    String? parentId,
  }) {
    return _apiCallExecutor.processApi<FeedbackCommentModel>(
      apiCallType: ApiCallType.post,
      endpoint: ApiEndPoints.addFeedbackComment(feedbackId),
      parameters: <String, dynamic>{
        'content': content,
        if (parentId?.trim().isNotEmpty == true) 'parent': parentId!.trim(),
      },
      decoder: (json) {
        if (json is! Map<String, dynamic>) {
          throw const ApiError.invalidResponse();
        }
        return FeedbackCommentModel.fromApiJson(json);
      },
    );
  }

  Future<void> deleteFeedbackComment({required String commentId}) {
    return _apiCallExecutor.processApi<void>(
      apiCallType: ApiCallType.delete,
      endpoint: ApiEndPoints.feedbackComment(commentId),
      decoder: (_) {},
    );
  }

  Future<FeedbackCommentModel> updateFeedbackComment({
    required String commentId,
    required String content,
  }) => _apiCallExecutor.processApi<FeedbackCommentModel>(
    apiCallType: ApiCallType.patch,
    endpoint: ApiEndPoints.editFeedbackComment(commentId),
    parameters: <String, dynamic>{'content': content},
    decoder: (json) {
      if (json is! Map<String, dynamic>) throw const ApiError.invalidResponse();
      return FeedbackCommentModel.fromApiJson(json);
    },
  );

  Future<FeedbackPostModel?> createFeedbackPost(FeedbackPostCreateDraft draft) {
    return _multipartApiExecutor.process<FeedbackPostModel?>(
      endpoint: ApiEndPoints.feedbacks,
      fields: <String, String>{
        'title': draft.title,
        'description': draft.description,
      },
      files: draft.attachments
          .map(
            (attachment) => MultipartApiFile(
              fieldName: 'attachments',
              fileName: attachment.fileName,
              bytes: attachment.bytes,
              contentType: attachment.contentType,
            ),
          )
          .toList(growable: false),
      decoder: (json) {
        if (json == null) {
          return null;
        }
        final response = _extractCreatedPostJson(json);
        return FeedbackPostModel.fromApiJson(response);
      },
    );
  }
}

FeedbackPostModel? _decodeUpdatedPost(dynamic json) {
  if (json is! Map<String, dynamic>) {
    return null;
  }

  final postJson = json.containsKey('uuid')
      ? json
      : json['data'] is Map<String, dynamic>
      ? json['data'] as Map<String, dynamic>
      : json['feedback'] is Map<String, dynamic>
      ? json['feedback'] as Map<String, dynamic>
      : null;
  return postJson == null ? null : FeedbackPostModel.fromApiJson(postJson);
}

Map<String, dynamic> _extractCreatedPostJson(dynamic json) {
  if (json is! Map<String, dynamic>) {
    throw const ApiError.invalidResponse();
  }

  if (json.containsKey('uuid')) {
    return json;
  }

  for (final key in const <String>['data', 'result', 'feedback']) {
    final value = json[key];
    if (value is Map<String, dynamic> && value.containsKey('uuid')) {
      return value;
    }
  }

  throw const ApiError.invalidResponse();
}

FeedbackRemoteDataSource createFeedbackRemoteDataSource() {
  return FeedbackRemoteDataSource();
}
