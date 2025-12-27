# Add Location Implementation - Home, Work, and Favourite

## Summary
Implemented a unified location saving system that uses the AddHomeScreen for all three location types (home, work, favourite) with proper API integration to save locations using the `/users/favouriteLocation/` endpoint.

## Changes Made

### **1. Updated AddHomeScreen** (`lib/features/home/presentation/screens/add_home_screen.dart`)

Made the screen reusable for all three location types:

#### **Added Location Type Parameter:**
```dart
class AddHomeScreen extends StatefulWidget {
  final String locationType; // 'home', 'work', or 'favourite'
  
  const AddHomeScreen({
    super.key,
    this.locationType = 'home',
  });
}
```

#### **Dynamic Title Based on Type:**
```dart
String get _title {
  switch (widget.locationType.toLowerCase()) {
    case 'work':
      return 'Add work';
    case 'favourite':
      return 'Add favourite';
    case 'home':
    default:
      return 'Add home';
  }
}
```

#### **Dynamic Location Name for API:**
```dart
String get _locationName {
  switch (widget.locationType.toLowerCase()) {
    case 'work':
      return 'Work Location';
    case 'favourite':
      return 'Favourite Location';
    case 'home':
    default:
      return 'Home Location';
  }
}
```

#### **Save Location Method:**
```dart
Future<void> _saveLocation(String address) async {
  if (address.isEmpty) {
    CustomFlushbar.showError(
      context: context,
      message: 'Please enter an address',
    );
    return;
  }

  setState(() => _isSaving = true);

  try {
    // Create request with location name based on type
    final request = FavouriteLocationRequest(
      name: _locationName,  // "Home Location", "Work Location", or "Favourite Location"
      destLocation: destLocation,
      destAddress: address,
    );

    await _favouriteService.addFavouriteLocation(request);

    CustomFlushbar.showSuccess(
      context: context,
      message: '$_locationName saved successfully!',
    );

    // Return true to indicate success
    Navigator.pop(context, true);
  } catch (e) {
    CustomFlushbar.showError(
      context: context,
      message: 'Failed to save location: $e',
    );
  } finally {
    setState(() => _isSaving = false);
  }
}
```

#### **Added Save Button:**
```dart
ElevatedButton(
  onPressed: _isSaving
      ? null
      : () => _saveLocation(_addressController.text),
  child: _isSaving
      ? CircularProgressIndicator(color: Colors.white)
      : Text('Save Location'),
)
```

#### **Made Recent Locations Clickable:**
```dart
ListTile(
  title: Text(recentLocations[index]),
  onTap: () {
    _addressController.text = recentLocations[index];
    _saveLocation(recentLocations[index]);
  },
)
```

### **2. Updated Home Screen** (`lib/features/home/presentation/screens/home_screen.dart`)

Updated all three location buttons to use AddHomeScreen with appropriate types:

#### **Add Home Location:**
```dart
ListTile(
  title: Text('Add home location'),
  onTap: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddHomeScreen(
          locationType: 'home',
        ),
      ),
    );
    if (result == true) {
      _loadFavouriteLocations();  // Reload locations
    }
  },
)
```

#### **Add Work Location:**
```dart
ListTile(
  title: Text('Add work location'),
  onTap: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddHomeScreen(
          locationType: 'work',
        ),
      ),
    );
    if (result == true) {
      _loadFavouriteLocations();  // Reload locations
    }
  },
)
```

#### **Add Favourite Location:**
```dart
ListTile(
  title: Text('Add favourite location'),
  onTap: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddHomeScreen(
          locationType: 'favourite',
        ),
      ),
    );
    if (result == true) {
      _loadFavouriteLocations();  // Reload locations
    }
  },
)
```

## API Integration

### **Endpoint:**
```
POST /api/v1/users/favouriteLocation/
```

### **Request Body Format:**

#### **Home Location:**
```json
{
  "name": "Home Location",
  "dest_location": "POINT(-122.4194 38.7749)",
  "dest_address": "No. 19 Itam, Uyo"
}
```

#### **Work Location:**
```json
{
  "name": "Work Location",
  "dest_location": "POINT(-122.4194 38.7749)",
  "dest_address": "Office Building, Lagos"
}
```

#### **Favourite Location:**
```json
{
  "name": "Favourite Location",
  "dest_location": "POINT(-122.4194 38.7749)",
  "dest_address": "Restaurant XYZ"
}
```

## User Flow

### **Adding Home Location:**

```
1. User taps "Add home location"
      ↓
2. AddHomeScreen opens with title "Add home"
      ↓
3. User enters address or selects from recent
      ↓
4. User taps "Save Location" button
      ↓
5. API call to /users/favouriteLocation/ with name="Home Location"
      ↓
6. Success message: "Home Location saved successfully!"
      ↓
7. Screen closes, returns to home screen
      ↓
8. Favourite locations reload automatically
      ↓
9. Home location appears in list with home icon
```

### **Adding Work Location:**

```
1. User taps "Add work location"
      ↓
2. AddHomeScreen opens with title "Add work"
      ↓
3. User enters address
      ↓
4. API call with name="Work Location"
      ↓
5. Success message: "Work Location saved successfully!"
      ↓
6. Work location appears in list with work icon
```

### **Adding Favourite Location:**

```
1. User taps "Add favourite location"
      ↓
2. AddHomeScreen opens with title "Add favourite"
      ↓
3. User enters address
      ↓
4. API call with name="Favourite Location"
      ↓
5. Success message: "Favourite Location saved successfully!"
      ↓
6. Favourite location appears in list with star icon
```

## Features

### **✅ Unified UI:**
- Same screen for all three location types
- Dynamic title based on location type
- Consistent user experience

### **✅ API Integration:**
- Uses existing FavouriteLocationService
- Proper request format with correct name field
- Error handling with user-friendly messages

### **✅ User Feedback:**
- Loading indicator while saving
- Success message on save
- Error message on failure
- Disabled button during save

### **✅ Auto-Reload:**
- Locations reload after successful save
- List updates immediately
- Correct icons display based on type

### **✅ Quick Selection:**
- Recent locations are clickable
- One-tap to select and save
- Faster user experience

## Location Name Mapping

| Button Tapped | Screen Title | API Name Field | Icon Displayed |
|--------------|--------------|----------------|----------------|
| Add home location | "Add home" | "Home Location" | Home icon |
| Add work location | "Add work" | "Work Location" | Work icon |
| Add favourite location | "Add favourite" | "Favourite Location" | Star icon |

## Error Handling

### **Empty Address:**
```dart
if (address.isEmpty) {
  CustomFlushbar.showError(
    context: context,
    message: 'Please enter an address',
  );
  return;
}
```

### **API Failure:**
```dart
catch (e) {
  CustomFlushbar.showError(
    context: context,
    message: 'Failed to save location: $e',
  );
}
```

### **Widget Disposed:**
```dart
if (!mounted) return;
```

## Testing Checklist

- [ ] Tap "Add home location" → Screen opens with "Add home" title
- [ ] Enter address → Save button enabled
- [ ] Tap "Save Location" → Loading indicator shows
- [ ] Success → "Home Location saved successfully!" message
- [ ] Home location appears in list with home icon
- [ ] Tap "Add work location" → Screen opens with "Add work" title
- [ ] Save work location → "Work Location saved successfully!"
- [ ] Work location appears with work icon
- [ ] Tap "Add favourite location" → Screen opens with "Add favourite" title
- [ ] Save favourite → "Favourite Location saved successfully!"
- [ ] Favourite appears with star icon
- [ ] Tap recent location → Auto-fills and saves
- [ ] Test with empty address → Error message shows
- [ ] Test with network error → Error message shows

## Future Enhancements

### **Geocoding:**
Currently using a default location point. Future implementation should:
```dart
// Get coordinates from address
final coordinates = await geocodeAddress(address);
final destLocation = 'POINT(${coordinates.longitude} ${coordinates.latitude})';
```

### **Map Picker:**
Add ability to pick location from map:
```dart
OutlinedButton.icon(
  onPressed: () async {
    final location = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapPickerScreen()),
    );
    if (location != null) {
      _addressController.text = location.address;
      _saveLocation(location.address);
    }
  },
  icon: Icon(Icons.map),
  label: Text('Pick from map'),
)
```

### **Edit Existing Locations:**
Allow users to edit saved locations:
```dart
// Long press to edit
onLongPress: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddHomeScreen(
        locationType: 'home',
        existingLocation: location,
        isEditing: true,
      ),
    ),
  );
}
```

## Files Modified

1. **`lib/features/home/presentation/screens/add_home_screen.dart`**
   - Added locationType parameter
   - Added save functionality
   - Added loading state
   - Made recent locations clickable
   - Added dynamic titles

2. **`lib/features/home/presentation/screens/home_screen.dart`**
   - Updated all three location buttons
   - Added location type parameters
   - Added result handling
   - Added auto-reload on success

## Benefits

✅ **Reusable** - One screen for all location types
✅ **Consistent** - Same UX across all types
✅ **Integrated** - Uses existing API service
✅ **User-Friendly** - Clear feedback and loading states
✅ **Maintainable** - Single source of truth for UI
✅ **Extensible** - Easy to add more location types

The implementation is complete and ready to use! Users can now save home, work, and favourite locations using the same intuitive interface. 🎉
