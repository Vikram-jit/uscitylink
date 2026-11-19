import 'package:flutter_test/flutter_test.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/views/driver/views/chats/attachement_ui.dart';

void main() {
  test('a file not in S3 yet is opened from the API server', () {
    expect(serverFileUrl('${Constant.aws}/uscitylink/1795062059274-1795062058768.jpg'),
        '${Constant.tempImageUrl}uscitylink/1795062059274-1795062058768.jpg');
    expect(serverFileUrl('${Constant.aws}/uscitylink/video/a.mp4'), '${Constant.tempImageUrl}uscitylink/video/a.mp4');
  });

  test('links that are not S3 links are left alone', () {
    const server = '${Constant.tempImageUrl}uscitylink/x.jpg';
    expect(serverFileUrl(server), server);
    expect(serverFileUrl(''), '');
  });
}
