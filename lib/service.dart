import 'dart:io';
import 'dart:convert';

import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

import 'package:path_provider/path_provider.dart';

final dio = Dio();

void initService() async {
  Directory dir = await getTemporaryDirectory();

  dir.deleteSync(recursive: true);
  dir.create();
}

String formatReelUrl(String url) {
  String formattedUrl = url;

  if (formattedUrl.contains('?')) {
    formattedUrl = url.split('?')[0];
  }

  if (formattedUrl.endsWith('/')) {
    formattedUrl = formattedUrl.substring(0, formattedUrl.length - 1);
  }

  return formattedUrl;
}

Future<String> getVideoUrl(String reelUrl) async {
  final requestUrl = '${formatReelUrl(reelUrl)}/?__a=1&__d=dis';

  final response = await http.get(Uri.parse(requestUrl), headers: {
    'Cookie':
        'sessionid=67142864476%3Aux7UILK2SpzfnW%3A16%3AAYfgpCuyvOiQdAB5LFS88Lq7gEIGyKYp3Ll9XPUfGA;ds_user_id=67142864476;'
  });

  if (response.statusCode == 200) {
    Map<String, dynamic> data = json.decode(response.body);

    final videoUrl = data['items'][0]['video_versions'][0]['url'];

    // http.Response r = await http.head(Uri.parse(videoUrl));

    // print('remote size: ${r.headers['content-length']}');

    return videoUrl;
  }

  return '';
}

Future<String> downloadVideo(String videoUrl) async {
  if (videoUrl.isEmpty) {
    return '';
  }

  final tmpDir = (await getTemporaryDirectory()).path;
  const filename = 'video.mp4';
  final localVideoPath = '$tmpDir/$filename';

  final response = await dio.download(
    videoUrl,
    localVideoPath,
  );

  // print('local size: ${await File(localVideoPath).length()}');

  return localVideoPath;
}

Future<String> convertVideo(String videoPath) async {
  if (videoPath.isEmpty) {
    return '';
  }

  final outputPath = '${(await getTemporaryDirectory()).path}/output.mp4';
  final session = await FFmpegKit.execute(
    '-i $videoPath -vcodec libx264 -y $outputPath',
  );

  // print(session.getFailStackTrace());

  // print('converted size: ${await File(outputPath).length()}');

  return outputPath;
}

Future<String> uploadLocalVideo(String videoPath) async {
  if (videoPath.isEmpty) {
    return '';
  }

  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(videoPath),
  });

  final response =
      await dio.post('https://tmpfiles.org/api/v1/upload', data: formData);

  if (response.statusCode == 200) {
    final sharedUrl = response.data['data']['url'].toString();
    final uploadedUrl =
        '${sharedUrl.substring(0, 20)}/dl${sharedUrl.substring(20)}';

    return uploadedUrl;
  }

  return '';
}

Future<bool> uploadReel(String videoUrl) async {
  if (videoUrl.isEmpty) {
    return false;
  }

  const accId = '17841466974302858';
  const caption =
      'No+problem%21+Here%E2%80%99s+the+information+about+the+Mercedes+CLR+GTR%3A%0D%0AThe+Mercedes+CLR+GTR+is+a+remarkable+racing+car+celebrated+for+its+outstanding+performance+and+sleek+design.+Powered+by+a+potent+6.0-liter+V12+engine%2C+it+delivers+over+600+horsepower.%0D%0AAcceleration+from+0+to+100+km%2Fh+takes+approximately+3.7+seconds%2C+with+a+remarkable+top+speed+surprising%0D%0A320+km%2Fh.+%F0%9F%A5%87+%0D%0A%0D%0AIncorporating+adventure+aerodynamic+features+and+cutting-edge+stability+technologies%2C+the+CLR+GTR+ensures+exceptional+stability+and+control%2C+particularly+during+high-speed+maneuvers.%F0%9F%92%A8%0D%0A%0D%0AOriginally+priced+at+around+%241.5+million%2C+the+Mercedes+CLR+GTR+is+considered+one+of+the+most+exclusive+and+prestigious+racing+cars+ever+produced.%F0%9F%92%B0+%0D%0A%0D%0AIts+limited+production+run+of+just+five+units+adds+to+its+rarity%2C+making+it+highly+sought+after+by+racing+enthusiasts+and+collectors+worldwide.+%F0%9F%8C%8E%0D%0A%0D%0A%23brainrot+%23memes+';
  const accessToken =
      'EAAG5ZC4BORDwBO1TMbDlyJGIbnhroteFF1FykylOtd6VqgZAUPxUn9sWxNwRQ2Q4xEPJAEzh9v4Fnp4JOXRed0lEaC53W5dqdHbaBnHiN0a609q3h3gZCOVqTBUhaF8arLMSgatiJKeSufjgbUYWTustVP8pr547tOZCcSVPYA2P4EKDMdIiQ2lr';
  const apiUrl = 'https://graph.facebook.com/v20.0';
  final requestUrl =
      '$apiUrl/$accId/media?media_type=REELS&video_url=$videoUrl&caption=$caption&access_token=$accessToken';

  final response = await http.post(Uri.parse(requestUrl));

  if (response.statusCode == 200) {
    Map<String, dynamic> data = json.decode(response.body);

    final mediaId = data['id'];
    final publishUrl =
        '$apiUrl/$accId/media_publish?creation_id=$mediaId&access_token=$accessToken';

    while (true) {
      await Future.delayed(const Duration(seconds: 3));

      final result = await http.post(Uri.parse(publishUrl));

      if (result.statusCode != 200 && result.statusCode != 400) {
        break;
      }

      Map<String, dynamic> data = json.decode(result.body);

      if (data.containsKey('id')) {
        return true;
      }
    }
  }

  return false;
}
