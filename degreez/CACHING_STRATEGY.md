# Caching Strategy for DegreEZ

## How Caching Helps Speed Up Loading

### 🎯 **The Problem**
Every time you open the app, it needs to:
1. Authenticate the user
2. Fetch student data from Firestore
3. Fetch courses from Firestore
4. Fetch theme preferences

This requires network calls which can take 200-1000ms depending on connection speed.

### ✅ **The Solution: Multi-Layer Caching**

## 1. Firebase Firestore Cache (Built-in)

Firebase automatically caches data, but it works **differently** on mobile vs web:

### 📱 **Mobile (Android/iOS)**
- ✅ **Offline Persistence Enabled by Default**
- Data is stored in SQLite database on device
- Works even when completely offline
- Cache persists between app restarts
- **Result**: Near-instant loading (5-50ms) when reopening app

### 🌐 **Web**
- ⚠️ **Limited by Browser**
- Uses IndexedDB for caching (not enabled by default)
- Cache is cleared when browser is closed (unless we enable persistence)
- Smaller cache size limits
- **Current State**: NOT optimized yet

---

## 2. Proposed Caching Improvements

### For Web:

#### A. Enable Firestore Persistence (Web)
```dart
// In main.dart after Firebase initialization
if (kIsWeb) {
  await FirebaseFirestore.instance.enablePersistence();
}
```

**Benefits:**
- Cache survives browser refresh
- Loads data from IndexedDB (~50-100ms instead of 200-500ms)
- Works offline if user has visited before

**Limitations:**
- Only one browser tab can have persistence enabled
- ~40MB cache limit
- Doesn't work in incognito mode

#### B. Add Memory Cache (Provider-level)
Store frequently accessed data in memory:

```dart
class CachedStudentProvider {
  static StudentModel? _cachedStudent;
  static DateTime? _cacheTime;
  
  Future<StudentModel?> getStudent(String userId) async {
    // Return cached if less than 5 minutes old
    if (_cachedStudent != null && 
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < Duration(minutes: 5)) {
      return _cachedStudent;
    }
    
    // Otherwise fetch fresh data
    final student = await fetchFromFirestore(userId);
    _cachedStudent = student;
    _cacheTime = DateTime.now();
    return student;
  }
}
```

**Benefits:**
- Instant access (< 1ms)
- No network calls for repeated requests
- Works across all platforms

#### C. Use SharedPreferences for Critical Data
Store minimal user data locally:

```dart
// Save on login
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setString('userId', user.uid);
await prefs.setString('userName', user.displayName);
await prefs.setBool('hasCompletedSignup', true);

// Load on app start (before Firebase)
String? userId = prefs.getString('userId');
bool hasSignup = prefs.getBool('hasCompletedSignup') ?? false;
```

**Benefits:**
- Available instantly on app start
- Can show personalized splash screen
- Decide which screen to show without network call

---

## 3. Current Performance

### Without Cache:
```
App Open → Firebase Auth Check (100ms) 
       → Fetch Student Data (200-500ms)
       → Fetch Courses (200-500ms)
       → Navigate to Home
Total: 500-1100ms
```

### With Firestore Cache (Mobile):
```
App Open → Firebase Auth Check (100ms)
       → Fetch Student Data from Cache (5-20ms)
       → Fetch Courses from Cache (5-20ms)
       → Navigate to Home
Total: 110-140ms ⚡ 80% faster!
```

### With ALL Optimizations (Web + Mobile):
```
App Open → Check SharedPreferences (1-5ms)
       → Show Personalized Splash
       → Firebase Auth Check (50ms)
       → Load from Memory Cache (1ms)
       → Navigate to Home
Total: 50-60ms ⚡ 95% faster!
```

---

## 4. Implementation Priority

### ✅ Phase 1: DONE
- [x] AuthWrapper to prevent login page flash
- [x] Parallel data loading

### 🔄 Phase 2: Quick Wins (Recommended Next)
- [ ] Enable Firestore persistence for web
- [ ] Add memory cache to StudentProvider and CourseProvider
- [ ] Prefetch user data in AuthWrapper

### 🚀 Phase 3: Advanced (Optional)
- [ ] SharedPreferences for offline-first experience
- [ ] Predictive prefetching
- [ ] Background sync
- [ ] Service Worker for PWA

---

## 5. Does Caching Work on Website?

### Current State:
**Partial** - Firebase has some automatic caching but not optimized

### After Implementing Phase 2:
**Yes!** The website will:
- Cache data in IndexedDB (persists across page refreshes)
- Store recent data in memory (instant access during session)
- Load 60-80% faster on subsequent visits

### Important Note:
- First visit will always require network (no cache yet)
- Subsequent visits/refreshes will be much faster
- Incognito mode won't benefit from IndexedDB cache
- Regular browsing will have full caching benefits

---

## 6. Recommendation

**Implement Phase 2 next** because:
1. Small code changes (< 50 lines)
2. Big performance impact (60-80% faster)
3. Works on both mobile and web
4. Improves user experience immediately
5. No infrastructure changes needed

Would you like me to implement the Phase 2 caching improvements?
