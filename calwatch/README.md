# CalWatch - Nutrition & Fitness Tracker

CalWatch is a Flutter-based mobile application for tracking nutrition, calories, and fitness metrics. The app features a modern dark theme with glass effect UI components and provides a comprehensive solution for users to monitor their daily food intake, water consumption, and nutritional goals.

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [App Structure](#app-structure)
- [Tech Stack](#tech-stack)
- [Setup and Installation](#setup-and-installation)
- [Dependencies](#dependencies)
- [Usage](#usage)

## Features

- **User Authentication**
  - Login, Sign up, and Reset Password functionality
  - JWT token-based authentication
  - Secure password storage

- **Home Screen**
  - Daily calorie tracking with visual indicators (consumed, burned, remaining)
  - Water intake tracker with animated progress bar
  - Food entries organized by meal type
  - Date navigation to view historical data

- **Food Tracking**
  - Add food entries with details like name, calories, and meal type
  - Quick add feature for common foods
  - Search functionality for food database
  - Meal categorization (Breakfast, Lunch, Dinner, Snacks)

- **Nutrition Logging**
  - Calendar view to navigate through history
  - Daily logs of food intake and water consumption
  - Nutritional statistics for each day

- **User Profile**
  - Personal statistics (age, height, weight, goals)
  - Micronutrient tracking with progress indicators
  - Settings management
  - Profile customization

- **UI/UX**
  - Modern dark theme with glass effect components
  - Responsive design for different screen sizes
  - Consistent bottom navigation across all screens
  - Animated transitions and progress indicators

## App Structure

### Screens

- `home_screen.dart` - Main dashboard with calories, water tracking, and food entries
- `login_screen.dart` - User authentication screen
- `signup_screen.dart` - New user registration
- `reset_password_screen.dart` - Password recovery
- `logs_screen.dart` - Calendar view and daily nutrition logs
- `add_food_screen.dart` - Food entry form with meal type selection
- `profile_screen.dart` - User profile and settings

### Components

- `water_tracker_widget.dart` - Reusable component for tracking water intake
- Services:
  - `api_service.dart` - Handles all API communications with backend

### Navigation Flow

The app uses a consistent bottom navigation bar across all main screens for easy navigation:

1. **Home** - Daily nutrition dashboard
2. **Foods** - Add and manage food entries
3. **Logs** - Calendar view and historical data
4. **Profile** - User settings and statistics

## Tech Stack

- **Frontend**: Flutter with Dart
- **State Management**: setState (local state management)
- **API Communication**: HTTP package with RESTful API design
- **Authentication**: JWT tokens stored in SharedPreferences
- **Design**: Custom UI components with Google Fonts

## Setup and Installation

1. **Prerequisites**
   - Flutter SDK (3.7.0 or higher)
   - Dart SDK
   - Android Studio / VS Code with Flutter extensions

2. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/calwatch.git
   cd calwatch
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Dependencies

The app uses the following main dependencies:

- `google_fonts: ^5.1.0` - For typography
- `percent_indicator: ^4.2.5` - For circular and linear progress indicators
- `fl_chart: ^0.71.0` - For nutrition charts
- `table_calendar: ^3.2.0` - For the logs calendar
- `http: ^1.1.2` - For API requests
- `shared_preferences: ^2.2.2` - For local storage of user data

Full dependencies can be found in the `pubspec.yaml` file.

## Usage

1. **Authentication**
   - New users can register using the Sign Up screen
   - Existing users can log in with email and password
   - Forgotten passwords can be reset via the Reset Password screen

2. **Home Screen**
   - Track daily calories (consumed, burned, remaining)
   - Monitor water intake and add glasses with a single tap
   - View and manage food entries organized by meal type
   - Navigate through dates using the arrows in the app bar

3. **Adding Food**
   - Tap the "+" button on the home screen or navigate to the Foods tab
   - Enter food name and select meal type
   - Add commonly consumed foods from the Recent Foods list

4. **Viewing Logs**
   - Navigate to the Logs tab
   - Use the calendar to select specific days
   - View detailed logs of food intake and water consumption

5. **Profile Management**
   - View and update personal stats
   - Track micronutrient consumption
   - Manage app settings
   - Sign out from the app

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- Flutter team for the amazing cross-platform framework
- All open-source package contributors
