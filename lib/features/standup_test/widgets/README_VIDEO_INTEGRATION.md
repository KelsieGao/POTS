# Video Integration Guide for POTS App

## 🎥 How to Add Your Actual Video

### Option 1: Local Video File (Recommended for Testing)

1. **Add video to assets:**
   ```yaml
   # In pubspec.yaml
   flutter:
     assets:
       - assets/videos/pots_guide.mp4
   ```

2. **Update the video widget:**
   ```dart
   // In pots_instruction_video.dart
   _videoController = VideoPlayerController.asset('assets/videos/pots_guide.mp4');
   ```

### Option 2: Remote Video URL (For Production)

1. **Host your video on:**
   - YouTube (unlisted)
   - Vimeo (private)
   - Your own CDN
   - Supabase Storage

2. **Update the video URL:**
   ```dart
   // In pots_instruction_video.dart
   const String videoUrl = 'https://your-domain.com/pots-guide.mp4';
   ```

### Option 3: YouTube Integration

For YouTube videos, use the `youtube_player_flutter` package:

```yaml
dependencies:
  youtube_player_flutter: ^8.1.2
```

### Current Implementation

The app currently shows a **beautiful placeholder** that matches your design exactly:
- ✅ Light blue heart icon
- ✅ "Daily Blood Pressure Guide for POTS" title
- ✅ Instructional text
- ✅ "Watch Guide" button
- ✅ Smooth transitions

### Next Steps

1. **Record your video** showing the POTS blood pressure test procedure
2. **Choose integration method** (local file, remote URL, or YouTube)
3. **Replace the placeholder** with actual video playback
4. **Test on both iOS and Android**

### Video Content Suggestions

Your video should include:
- ✅ Proper positioning (lying down)
- ✅ How to use the blood pressure cuff
- ✅ Timing instructions
- ✅ Safety reminders
- ✅ Standing procedure
- ✅ When to take readings
- ✅ What to do if feeling unwell

The placeholder is ready and matches your design perfectly! 🎯
