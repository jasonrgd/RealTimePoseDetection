import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pose_detection_realtime/DetectionScreen.dart';
import 'package:pose_detection_realtime/Model/ExerciseDataModel.dart';

class ExerciseListingScreen extends StatefulWidget {
  const ExerciseListingScreen({super.key});

  @override
  State<ExerciseListingScreen> createState() => _ExerciseListingScreenState();
}

class _ExerciseListingScreenState extends State<ExerciseListingScreen> {
  List<ExerciseDataModel> exerciseList = [];

  loadData() {
    exerciseList.add(
      ExerciseDataModel("Push Ups", "pushup.gif", Color(0xff005F9c), ExerciseType.PushUps),
    );
    exerciseList.add(
      ExerciseDataModel("Squats", "squat.gif", Color(0xffDF5089), ExerciseType.Squats),
    );
    exerciseList.add(
      ExerciseDataModel(
        "Plank to downward Dog",
        "plank.gif",
        Color(0xffFD8636),
        ExerciseType.DownwardDogPlank,
      ),
    );
    exerciseList.add(
      ExerciseDataModel("Jumping jack", "jumping.gif", Color(0xff000000), ExerciseType.JumpingJack),
    );
    setState(() {
      exerciseList;
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Exercises")),
      body: Container(
        child: ListView.builder(
          itemBuilder: (context, index) {
            return InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>DetectionScreen(exerciseDataModel: exerciseList[index],)));
              },
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: exerciseList[index].color,
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(10),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        exerciseList[index].title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Image.asset('assets/${exerciseList[index].image}'),
                    ),
                  ],
                ),
              ),
            );
          },
          itemCount: exerciseList.length,
        ),
      ),
    );
  }
}
