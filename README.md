![github_banner-removebg](https://github.com/user-attachments/assets/e6d8a6be-2bb3-48bf-a32d-4468f39f52d3)

# Peak Step Detection – Didactic Step Detection App

**Peak Step Detection** is a lightweight educational mobile application designed for collecting, visualizing, and contributing step detection data. It includes both classical step detection logic and multiple step length estimation models, making it ideal for prototyping, academic exploration, and dataset enrichment.

## 🔧 Features

- Real-time **peak and valley-based** step detection (based on Abadleh et al., 2018)
- Interactive graphs and live data preview from the phone’s accelerometer
- Multiple **step length estimation models**:
  - Grieve & Gear (1966) — static model based on user height and gender
  - Weinberg (2002) — dynamic model based on accelerometer magnitude extremes
  - Kim et al. (2004) — cube-root model using average absolute acceleration

## 📊 Educational Purpose

This app is intended for:
- Academic use in research or coursework on inertial navigation and gait analysis
- Contributing annotated data to public or personal datasets
- Testing and comparing classical vs. heuristic-based algorithms

##  Architecture Highlights

- Built using **Flutter/Dart**
- Modular file structure:  
  - `sensor_service.dart` – stream handling for IMU sensors  
  - `graph_detail_screen.dart` – time-series visualization  
  - `json_service.dart` – export/import of step data in JSON  
  - `settings_screen.dart` – user configuration (e.g., height, gender)  
  - `csv_service.dart` – CSV export for external analysis

## Example Dataset Contribution

Data collected can be exported in **CSV** or **JSON** format, making it compatible with academic tools like MATLAB, Python (Pandas), or custom machine learning pipelines.

## 📑 References

- Abadleh et al., 2018 – Peak and valley step detection  
- Grieve & Gear, 1966 – Static step length estimation  
- Weinberg, 2002 – Dynamic magnitude-based method  
- Kim et al., 2004 – Cube-root acceleration model  

## 🚀 Getting Started

1. Clone the repo
2. Run with `flutter run` on a physical or emulated Android device
3. Configure personal attributes in Settings
4. Start walking & export your data!

---

> Developed as part of a Master's Dissertation on smartphone-based pedestrian tracking using inertial sensors.
