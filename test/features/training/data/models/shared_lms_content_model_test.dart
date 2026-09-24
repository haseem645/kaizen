import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/features/training/data/models/shared_lms_content_model.dart';

void main() {
  test(
    'shared LMS response retains the list metadata and public lesson IDs',
    () {
      final model = SharedLmsContentModel.fromApiJson({
        'view_type': 'lms',
        'content': {
          'title': 'YRL 3',
          'category_title': 'Iris Jacobson',
          'description': 'Dicta fugiat distinc',
          'modules': [
            {
              'public_id': 'b9a12982d92b57fe7c7d04d8584a445bae214055',
              'title': 'sdfs',
              'thumbnail_url':
                  'https://media-dev.kaizenteams.ai/media/images/first.jpg',
            },
            {
              'public_id': '2ea6df45ebb85d7e0ba7ab28b895868d222cdbb2',
              'title': 'MKAAL',
              'thumbnail_url': null,
            },
          ],
        },
      });

      expect(model.title, 'YRL 3');
      expect(model.categoryTitle, 'Iris Jacobson');
      expect(model.description, 'Dicta fugiat distinc');
      expect(model.lessons.map((lesson) => lesson.publicId), [
        'b9a12982d92b57fe7c7d04d8584a445bae214055',
        '2ea6df45ebb85d7e0ba7ab28b895868d222cdbb2',
      ]);
      expect(model.lessons.first.thumbnailUrl, endsWith('/first.jpg'));
    },
  );
}
