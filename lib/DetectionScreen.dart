import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pose_detection_realtime/Model/ExerciseDataModel.dart';

import 'Model/Exercise.dart';
import 'main.dart';

class DetectionScreen extends StatefulWidget {
  DetectionScreen({Key? key, required this.exerciseDataModel})
      : super(key: key);
  ExerciseDataModel exerciseDataModel;
  @override
  _DetectionScreenState createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  dynamic controller;
  bool isBusy = false;
  late Size size;
  late List<Exercise> squatPoseList;
  int repCount = 0;
  int repPhase = 0; // 0=initial, 1=mid, 2=endX

  final List<String> repSequence = ["initial", "mid", "end1", "end2", "end3"];
  //TODO declare detector
  late PoseDetector poseDetector;
  @override
  void initState() {
    super.initState();
    initializeCamera();
    loadSquatData();
  }
  void loadSquatData(){
    final String squatJsonString = '''
    [{
    "label":"squat",
    "position":"start",
    "vector":[0.29969244384765625,0.42238278198242185,-0.40909197998046876,0.999982476234436,0.42413873291015625,0.30886270141601563,-0.3421209411621094,0.9909096360206604,0.4213676452636719,0.43780499267578127,0.08292404937744141,0.9997407793998718,0.6138564453125,0.3476544189453125,-0.37023617553710936,0.9677167534828186,0.5911268920898437,0.515589599609375,-0.1857498779296875,0.9964756369590759,0.49379360961914065,0.44095974731445314,-0.2591968994140625,0.9832144975662231,0.47139865112304685,0.5149550170898437,-0.5629358520507812,0.9990673661231995,0.6732677612304687,0.20329916381835939,-0.16521630859375,0.9962638020515442,0.675756591796875,0.28123065185546875,0.16584809875488282,0.9993147850036621,0.8659994506835937,0.3777025756835938,-0.2362940673828125,0.9914224743843079,0.8487767944335938,0.429387451171875,0.1413657684326172,0.9961305856704712,1.04480322265625,0.3009394836425781,-0.05536167526245117,0.9479621648788452,1.0111114501953125,0.332512451171875,0.2590389404296875,0.9833430051803589,0.8627551706295616,0.9324615773110302]
},
{
    "label":"squat",
    "position":"mid",
    "vector":[0.31526678466796876,0.430674072265625,-0.3303450317382812,0.9999719858169556,0.426669189453125,0.3136556396484375,-0.2993851928710938,0.9948603510856628,0.4276584167480469,0.43786895751953125,0.13309553527832033,0.9997640252113342,0.6224207763671875,0.35537081909179685,-0.2845435791015625,0.9762200117111206,0.5992315673828125,0.4999781799316406,-0.12336074066162109,0.9967523813247681,0.5175713500976562,0.4384302673339844,-0.11163109588623046,0.9870794415473938,0.47724481201171876,0.5115770874023438,-0.5014223022460937,0.9990302324295044,0.6810482177734375,0.20773483276367188,-0.17299227905273437,0.9951702952384949,0.6729324951171874,0.29437411499023436,0.17331146240234374,0.9989182949066162,0.890818603515625,0.389996337890625,-0.24352973937988281,0.985496461391449,0.8550306396484375,0.4465130310058594,0.18480172729492186,0.991455614566803,1.05296240234375,0.29225448608398436,-0.061919750213623045,0.8951566815376282,0.9679735107421875,0.34320654296875,0.28486276245117187,0.9675332307815552,0.8599571222349903,0.9296340992739658]
},
{
    "label":"squat",
    "position":"end1",
    "vector":[0.29645318603515625,0.5214968872070312,-0.3306563720703125,0.9999645948410034,0.43038995361328125,0.35806143188476564,-0.3421185607910156,0.9926826357841492,0.43170648193359373,0.4984537353515625,0.20088052368164064,0.9997817873954773,0.6616483154296875,0.3992745666503906,-0.256831787109375,0.9779677391052246,0.6170006103515625,0.6039285278320312,0.003302677869796753,0.9980276226997375,0.494212646484375,0.5147614135742188,0.07518449401855469,0.9898695349693298,0.48250320434570315,0.6199401245117188,-0.30850897216796874,0.9986489415168762,0.7431025390625,0.1555069122314453,-0.21040000915527343,0.9986646175384521,0.73057666015625,0.2671229248046875,0.21098283386230468,0.9997584223747253,0.8426119995117187,0.415493408203125,-0.5218231201171875,0.9974787831306458,0.7868580322265625,0.5527686767578125,0.10500572967529297,0.9990673661231995,1.1053668212890626,0.30184564208984377,-0.3609632873535156,0.9816655516624451,1.0374434814453124,0.3761570739746094,0.1463863525390625,0.9931228756904602,0.8758325822455576,0.8987812164668239]
},{
    "label":"squat",
    "position":"end2",
    "vector":[0.244159423828125,0.49357760620117186,-0.23699658203125,0.9999008178710938,0.3778153076171875,0.3451416625976563,-0.23043611145019532,0.9741412401199341,0.3803232116699219,0.5060277099609375,0.19958145141601563,0.9998058676719666,0.5927307739257812,0.4010126037597656,-0.2037842559814453,0.9304582476615906,0.6001674194335938,0.5844896240234375,-0.05350873947143555,0.9959927201271057,0.45359765625,0.5194171752929687,0.014761032104492188,0.9680808186531067,0.4298423767089844,0.5846204833984375,-0.3624653625488281,0.9995326995849609,0.6271846313476562,0.1235493392944336,-0.1853329620361328,0.9947391152381897,0.6458245239257813,0.2188717346191406,0.1853329620361328,0.9992903470993042,0.6881580200195313,0.39138485717773436,-0.445701171875,0.9900636076927185,0.6826299438476563,0.5064667663574218,0.14279248046875,0.9982038736343384,0.9349925537109375,0.3135122985839844,-0.25216763305664064,0.9502266049385071,0.90725830078125,0.3906478576660156,0.20993467712402344,0.9816655516624451,0.8473033943290992,0.9453183595938015]
},{
    "label":"squat",
    "position":"end3",
    "vector": [0.15254864501953125,0.4928428039550781,-0.16968096923828124,0.9998944997787476,0.34845440673828126,0.3399385681152344,-0.2987673645019531,0.9857181310653687,0.3298958740234375,0.48553082275390624,0.32991134643554687,0.9996923208236694,0.6028118896484375,0.4101864013671875,-0.10868173217773437,0.9156582355499268,0.5621392211914062,0.5870394897460938,0.06298600006103515,0.9921233057975769,0.4647403259277344,0.4905856018066406,0.38274871826171875,0.9540517926216125,0.41754339599609375,0.5905906982421875,-0.336999267578125,0.9991735816001892,0.67274365234375,0.14688484191894532,-0.2349759063720703,0.9937100410461426,0.6597615966796875,0.23280514526367188,0.2349759063720703,0.9989995360374451,0.7413178100585938,0.4883518981933594,-0.4317199401855469,0.9881309270858765,0.6889417724609375,0.5627310791015625,0.23733856201171874,0.9976769089698792,0.94422412109375,0.3335279846191406,-0.11244049072265624,0.9711290597915649,0.8817867431640625,0.3293966369628906,0.2938272705078125,0.9912885427474976,0.8731909946879721,0.9305111128620914]
}
]


  ''';
    List<dynamic> decodedSquatData = jsonDecode(squatJsonString);
    squatPoseList = decodedSquatData.map((e) => Exercise.fromJson(e)).toList();
  }

  //TODO code to initialize the camera feed
  initializeCamera() async {
    //TODO initialize detector
    final options = PoseDetectorOptions(mode: PoseDetectionMode.stream);
    poseDetector = PoseDetector(options: options);

    controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      imageFormatGroup:
      Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream(
            (image) => {
          if (!isBusy) {isBusy = true, img = image, doPoseEstimationOnFrame()},
        },
      );
    });
  }

  //TODO pose detection on a frame
  dynamic _scanResults;
  CameraImage? img;
  doPoseEstimationOnFrame() async {
    var inputImage = _inputImageFromCameraImage();
    if (inputImage != null) { print("input image is detected"); }
    if (inputImage != null) {
      final List<Pose> poses = await poseDetector.processImage(inputImage!);
      _scanResults = poses;
      if (poses.length > 0) {
        if (widget.exerciseDataModel.type == ExerciseType.PushUps) {
          detectPushUp(poses.first.landmarks);
        } else if (widget.exerciseDataModel.type == ExerciseType.Squats) {
          processPoseVector(poses.first);
        } else if (widget.exerciseDataModel.type ==
            ExerciseType.DownwardDogPlank) {
          detectPlankToDownwardDog(poses.first);
        } else if (widget.exerciseDataModel.type == ExerciseType.JumpingJack) {
          detectJumpingJack(poses.first);
        }
      }
    }
    setState(() {
      _scanResults;
      isBusy = false;
    });
  }

  //close all resources
  @override
  void dispose() {
    controller?.dispose();
    poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];
    size = MediaQuery.of(context).size;
    if (controller != null) {
      stackChildren.add(
        Positioned(
          top: 0.0,
          left: 0.0,
          width: size.width,
          height: size.height,
          child: Container(
            child:
            (controller.value.isInitialized)
                ? AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(controller),
            )
                : Container(),
          ),
        ),
      );

      stackChildren.add(
        Positioned(
          top: 0.0,
          left: 0.0,
          width: size.width,
          height: size.height,
          child: buildResult(),
        ),
      );
      stackChildren.add(
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.black,
            ),
            child: Center(
              child: Text(
                widget.exerciseDataModel.type == ExerciseType.PushUps
                    ? "$pushUpCount"
                    : widget.exerciseDataModel.type == ExerciseType.Squats
                    ? "$squatCount"
                    : widget.exerciseDataModel.type ==
                    ExerciseType.DownwardDogPlank
                    ? "$plankToDownwardDogCount"
                    : "$jumpingJackCount",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            width: 70,
            height: 70,
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 0),
        color: Colors.black,
        child: Stack(children: stackChildren),
      ),
    );
  }

  int pushUpCount = 0;
  bool isLowered = false;
  void detectPushUp(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftElbow == null ||
        rightElbow == null ||
        leftWrist == null ||
        rightWrist == null ||
        leftHip == null ||
        rightHip == null) {
      return; // Skip if any landmark is missing
    }

    // Calculate elbow angles
    double leftElbowAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
    double rightElbowAngle = calculateAngle(
      rightShoulder,
      rightElbow,
      rightWrist,
    );
    double avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    // Calculate torso alignment (ensuring a straight plank)
    double torsoAngle = calculateAngle(
      leftShoulder,
      leftHip,
      leftKnee ?? rightKnee!,
    );
    bool inPlankPosition =
        torsoAngle > 160 && torsoAngle < 180; // Slight flexibility

    if (avgElbowAngle < 90 && inPlankPosition) {
      // User is in the lowered push-up position
      isLowered = true;
    } else if (avgElbowAngle > 160 && isLowered && inPlankPosition) {
      // User returns to the starting position
      pushUpCount++;
      isLowered = false;

      // Update UI
      setState(() {});
    }
  }

  int squatCount = 0;
  bool isSquatting = false;
  void detectSquat(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null ||
        leftAnkle == null ||
        rightAnkle == null ||
        leftShoulder == null ||
        rightShoulder == null) {
      return; // Skip detection if any key landmark is missing
    }

    // Calculate angles
    double leftKneeAngle = calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightKneeAngle = calculateAngle(rightHip, rightKnee, rightAnkle);
    double avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    double hipY = (leftHip.y + rightHip.y) / 2;
    double kneeY = (leftKnee.y + rightKnee.y) / 2;

    bool deepSquat = avgKneeAngle < 90; // Ensuring squat is deep enough

    if (deepSquat && hipY > kneeY) {
      if (!isSquatting) {
        isSquatting = true;
      }
    } else if (!deepSquat && isSquatting) {
      squatCount++;
      isSquatting = false;

      // Update UI
      setState(() {});
    }
  }
  /// Cosine similarity
  double cosineSimilarity(List<double> v1, List<double> v2) {
    double dot = 0, mag1 = 0, mag2 = 0;
    for (int i = 0; i < v1.length; i++) {
      dot += v1[i] * v2[i];
      mag1 += v1[i] * v1[i];
      mag2 += v2[i] * v2[i];
    }
    return dot / (sqrt(mag1) * sqrt(mag2));
  }
  /// Process live pose vector for rep detection
  void processPoseVector(Pose pose) {
    print('processposevector called');
    // Filter references for current exercise
    final expectedPositions = switch (repPhase) {
      0 => ["initial"],
      1 => ["mid"],
      2 => ["end1", "end2", "end3"],
      _ => []
    };
    final idealVectors = squatPoseList.where((e) => e.label == 'squat').toList();
    List<double>? currentVector = getPoseVector(pose);
    if(currentVector == null){
      print("current vector is null");
      return;
    }
    if (idealVectors.isEmpty) {
      print('ideal vectors are empty');
      return;
    };

    //Find best match
    Exercise? bestMatch;
    double bestSim = -1.0;

    for (var ref in idealVectors) {
      if(ref.position == "end2" || ref.position == "end3")
        continue;
      print('cosine similarity for ${ref.position} is ');
      double sim = cosineSimilarity(currentVector, ref.vector);
      print('$sim');
      if (sim > bestSim) {
        bestSim = sim;
        bestMatch = ref;
      }
    }

    if (bestMatch == null)
    {
      print('bestmatch is null or less than threshold');
      return;
    }

    // State machine for phase transitions
    String matched = bestMatch.position;

    if (repPhase == 0 && matched == "initial") {
      print('repphase is 0');
      // Stay in start phase
    } else if (repPhase == 0 && matched == "mid") {
      repPhase = 1;
      print(" Mid reached");
    } else if (repPhase == 1 && matched.startsWith("end")) {
      repPhase = 2;
      print("End reached");
    } else if (repPhase == 2 && matched == "initial") {
      repCount++;
      squatCount++;
      setState(() {

      });
      repPhase = 0;
      print("squat rep completed. Total: $repCount");
    }
    else{
      print('nothing is matching');
    }
    print('repphase is $repPhase');
    print('matched values is $matched');
  }

  List<double>? getPoseVector(Pose pose) {
    if (pose.landmarks.isEmpty) return null;

    // Create a normalized pose vector for vector DB storage
    final landmarks = pose.landmarks;
    final List<double> vector = [];

    // Key pose landmarks for exercise analysis
    final keyLandmarks = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    // Extract normalized coordinates for key landmarks
    for (final landmarkType in keyLandmarks) {
      if (landmarks.containsKey(landmarkType)) {
        final landmark = landmarks[landmarkType]!;
        // Normalize coordinates and add to vector
        vector.add(landmark.x / 1000.0); // Normalize x
        vector.add(landmark.y / 1000.0); // Normalize y
        vector.add(landmark.z / 1000.0); // Normalize z
        vector.add(landmark.likelihood); // Confidence score
      } else {
        // Add zeros if landmark not detected
        vector.addAll([0.0, 0.0, 0.0, 0.0]);
      }
    }

    // Add pose angles/relationships for better vector representation
    if (landmarks.containsKey(PoseLandmarkType.leftShoulder) &&
        landmarks.containsKey(PoseLandmarkType.leftElbow) &&
        landmarks.containsKey(PoseLandmarkType.leftWrist)) {

      final shoulder = landmarks[PoseLandmarkType.leftShoulder]!;
      final elbow = landmarks[PoseLandmarkType.leftElbow]!;
      final wrist = landmarks[PoseLandmarkType.leftWrist]!;

      // Calculate left arm angle
      final armAngle = _calculateAngle(shoulder, elbow, wrist);
      vector.add(armAngle);
    } else {
      vector.add(0.0);
    }

    // Right arm angle
    if (landmarks.containsKey(PoseLandmarkType.rightShoulder) &&
        landmarks.containsKey(PoseLandmarkType.rightElbow) &&
        landmarks.containsKey(PoseLandmarkType.rightWrist)) {

      final shoulder = landmarks[PoseLandmarkType.rightShoulder]!;
      final elbow = landmarks[PoseLandmarkType.rightElbow]!;
      final wrist = landmarks[PoseLandmarkType.rightWrist]!;

      final armAngle = _calculateAngle(shoulder, elbow, wrist);
      vector.add(armAngle);
    } else {
      vector.add(0.0);
    }
    print("here is current vector allhua");
    print(vector);
    return vector;
  }

  double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    // Calculate angle at point b between points a and c
    final double radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
    double angle = radians * 180 / pi;
    if (angle < 0) angle += 360;
    return angle / 360.0; // Normalize to 0-1
  }

  int plankToDownwardDogCount = 0;
  bool isInDownwardDog = false;
  void detectPlankToDownwardDog(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftHip == null ||
        rightHip == null ||
        leftShoulder == null ||
        rightShoulder == null ||
        leftAnkle == null ||
        rightAnkle == null ||
        leftWrist == null ||
        rightWrist == null) {
      return; // Skip detection if any key landmark is missing
    }

    // **Step 1: Detect Plank Position**
    bool isPlank =
        (leftHip.y - leftShoulder.y).abs() < 30 &&
            (rightHip.y - rightShoulder.y).abs() < 30 &&
            (leftHip.y - leftAnkle.y).abs() > 100 &&
            (rightHip.y - rightAnkle.y).abs() > 100;

    // **Step 2: Detect Downward Dog Position**
    bool isDownwardDog =
        (leftHip.y < leftShoulder.y - 50) &&
            (rightHip.y < rightShoulder.y - 50) &&
            (leftAnkle.y > leftHip.y) &&
            (rightAnkle.y > rightHip.y);

    // **Step 3: Count Repetitions**
    if (isDownwardDog && !isInDownwardDog) {
      isInDownwardDog = true;
    } else if (isPlank && isInDownwardDog) {
      plankToDownwardDogCount++;
      isInDownwardDog = false;

      // Print count
      print("Plank to Downward Dog Count: $plankToDownwardDogCount");
    }
  }

  int jumpingJackCount = 0;
  bool isJumping = false;
  bool isJumpingJackOpen = false;
  void detectJumpingJack(Pose pose) {
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftAnkle == null ||
        rightAnkle == null ||
        leftHip == null ||
        rightHip == null ||
        leftShoulder == null ||
        rightShoulder == null ||
        leftWrist == null ||
        rightWrist == null) {
      return; // Skip detection if any landmark is missing
    }

    // Calculate distances
    double legSpread = (rightAnkle.x - leftAnkle.x).abs();
    double armHeight = (leftWrist.y + rightWrist.y) / 2; // Average wrist height
    double hipHeight = (leftHip.y + rightHip.y) / 2; // Average hip height
    double shoulderWidth = (rightShoulder.x - leftShoulder.x).abs();

    // Define thresholds based on shoulder width
    double legThreshold =
        shoulderWidth * 1.2; // Legs should be ~1.2x shoulder width apart
    double armThreshold =
        hipHeight - shoulderWidth * 0.5; // Arms should be above shoulders

    // Check if arms are raised and legs are spread
    bool armsUp = armHeight < armThreshold;
    bool legsApart = legSpread > legThreshold;

    // Detect full jumping jack cycle
    if (armsUp && legsApart && !isJumpingJackOpen) {
      isJumpingJackOpen = true;
    } else if (!armsUp && !legsApart && isJumpingJackOpen) {
      jumpingJackCount++;
      isJumpingJackOpen = false;

      // Print the count
      print("Jumping Jack Count: $jumpingJackCount");
    }
  }

  // Function to calculate angle between three points (shoulder, elbow, wrist)
  double calculateAngle(
      PoseLandmark shoulder,
      PoseLandmark elbow,
      PoseLandmark wrist,
      ) {
    double a = distance(elbow, wrist);
    double b = distance(shoulder, elbow);
    double c = distance(shoulder, wrist);

    double angle = acos((b * b + a * a - c * c) / (2 * b * a)) * (180 / pi);
    return angle;
  }

  // Helper function to calculate Euclidean distance
  double distance(PoseLandmark p1, PoseLandmark p2) {
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
  InputImage? _inputImageFromCameraImage() {
    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
    final camera = cameras[0];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
      _orientations[controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;
    // get image format
    final format = InputImageFormatValue.fromRawValue(img!.format.raw);

    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      if (Platform.isAndroid && format == InputImageFormat.yuv_420_888) {
        return convertYUV420ToInputImage(img, rotation);
      }
    }

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (img!.planes.length != 1) return null;
    final plane = img!.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(img!.width.toDouble(), img!.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format!, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  InputImage? convertYUV420ToInputImage(CameraImage? img, InputImageRotation rotation) {
    if (Platform.isAndroid && img!.format.group != ImageFormatGroup.yuv420) return null;

    final width = img!.width;
    final height = img.height;

    final yPlane = img.planes[0];
    final uPlane = img.planes[1];
    final vPlane = img.planes[2];

    final ySize = yPlane.bytes.length;
    final uvSize = width * height ~/ 2;
    final nv21Bytes = Uint8List(ySize + uvSize);

    // Copy Y
    nv21Bytes.setRange(0, ySize, yPlane.bytes);

    // Interleave V and U (NV21 expects V first, then U)
    int offset = ySize;
    final pixelStride = uPlane.bytesPerPixel ?? 2; // typically 2
    final rowStride = uPlane.bytesPerRow;

    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        final uvIndex = row * rowStride + col * pixelStride;
        nv21Bytes[offset++] = vPlane.bytes[uvIndex]; // V
        nv21Bytes[offset++] = uPlane.bytes[uvIndex]; // U
      }
    }

    return InputImage.fromBytes(
      bytes: nv21Bytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21, // must match the bytes layout
        bytesPerRow: width, // optional on Android
      ),
    );
  }

  //Show rectangles around detected objects
  Widget buildResult() {
    if (_scanResults == null ||
        controller == null ||
        !controller.value.isInitialized) {
      return Text('');
    }
    final Size imageSize = Size(
      controller.value.previewSize!.height,
      controller.value.previewSize!.width,
    );
    CustomPainter painter = PosePainter(imageSize, _scanResults);
    return CustomPaint(painter: painter);
  }
}