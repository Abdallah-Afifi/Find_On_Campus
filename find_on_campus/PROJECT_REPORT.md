# Find On Campus - Project Report

## Team Members
- Jasmin Guadarrama
- Fernanda 
- Allison Ewing
- Abdallah Afifi


## Project Summary
Find On Campus is a mobile application designed to help students and faculty easily report and search for lost or found items on campus. The app aims to simplify the lost and found process by creating a centralized digital platform where users can:

- Report items they've lost on campus
- Report items they've found on campus
- Search for lost or found items with filters
- Get notified of potential matches
- Track the status of their reports
- Contact item owners or finders
- Earn reward points for helping return items

The application is built using Flutter for cross-platform compatibility (Android, iOS, and web) and Firebase as the backend for authentication, database, storage, and notifications.

## Design Changes Since Proposal
While maintaining our core vision, we've made the following refinements to the project since our proposal:

1. **Enhanced Matching System**: Implemented an automatic matching algorithm that suggests potential matches between lost and found items based on category, date, and location.

2. **Reward Points System**: Added gamification through a reward points system to encourage user engagement. Users earn points for reporting found items and when items they found are claimed.

3. **Status Tracking**: Added more detailed status tracking for items (Pending, Resolved, Claimed) to manage better the lifecycle of lost/found items.

4. **UI/UX Improvements**: Refined the user interface with a more intuitive navigation system and color-coding (red for lost items, green for found items) for better visual distinction.

## Project Milestones & Tasks

### 1. Project Setup & Configuration
- Flutter project initialization
- Firebase configuration
- Version control setup (GitHub)
- Package dependencies management

### 2. Authentication System
- User registration functionality
- Login/logout functionality
- Profile management
- Password reset functionality
- Google Sign-In integration

### 3. Core Features Implementation
- Item reporting interface (lost items)
- Item reporting interface (found items)
- Dashboard screen with recent items
- Search functionality with filters
- Item details screen
- User profile screen
- Notification system

### 4. Backend Development
- Firebase Cloud Firestore database design
- Authentication services
- Storage services for images
- Cloud functions for matching algorithm
- Notification services

### 5. UI/UX Design & Implementation
- Application theme implementation
- Custom widgets development
- Responsive design for multiple screen sizes
- Animation and transitions
- Error handling and user feedback

### 6. Testing & Quality Assurance
- Unit testing
- Integration testing
- User acceptance testing
- Performance optimization
- Bug fixing

### 7. Deployment & Documentation
- App packaging for Android/iOS
- Web version deployment
- User documentation
- Technical documentation
- Future enhancement planning

## Timeline & Work Distribution

### Week 1: Project Setup & Authentication
- **Tasks**: Project initialization, Firebase setup, authentication system
- **Team Members**: Jasmin Guadarrama, Abdallah Afifi

### Week 2: Core Features Implementation
- **Tasks**: Dashboard, item reporting, search functionality
- **Team Members**: Fernanda De La Fuente, Allison Ewing

### Week 3: Backend & UI Development
- **Tasks**: Database implementation, storage services, UI components, user profile
- **Team Members**: All team members

### Week 4: Final Integration & Testing
- **Tasks**: Final bug fixes, documentation, quality assurance
- **Team Members**: All team members

## Completed Tasks

### Project Setup
- **Method**: We initialized the firebase console and researched the available frameworks.
- **Team Members**: All team members. 



## Work Distribution Summary

- **Authentication & Firebase Integration**: Jasmin Guadarrama, Abdallah Afifi
- **Item Reporting & Dashboard**: Fernanda, Allison Ewing
- **Search & User Profile System**: Jasmin Guadarrama, Fernanda
- **UI Components & Notification System**: Allison Ewing, Abdallah Afifi

## Technologies Used

- **Frontend**: Flutter, Dart
- **Backend**: Firebase (Authentication, Cloud Firestore, Storage, Cloud Messaging)
- **State Management**: Provider
- **UI Libraries**: Flutter Material Design, Flutter Spinkit
- **Image Handling**: Image Picker
- **Tools**: VS Code, Android Studio, Firebase Console

## Next Steps

1. **Analytics Implementation**: Add Firebase Analytics to track user behavior and app usage
2. **Advanced Matching Algorithm**: Enhance the matching algorithm with machine learning capabilities
3. **Campus Map Integration**: Add visual map interface to mark where items were lost/found
4. **Social Media Sharing**: Enable sharing lost/found items on social media platforms
5. **Admin Panel**: Develop an administrative dashboard for campus officials to manage the platform
