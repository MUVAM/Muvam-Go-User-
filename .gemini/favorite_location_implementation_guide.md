# Favorite Location Implementation Guide

## Summary
Implementation guide for saving and displaying Home, Work, and Favourite locations using the `/users/favouriteLocation/` endpoint with appropriate icons for each type.

## Requirements

### API Endpoint
- **Base URL:** `{{baseURLMOVAM}}users/favouriteLocation/`
- **Methods:** POST (save), GET (retrieve)

### Request Body Format
```json
{
    "name": "home",  // or "work" or "favourite"
    "dest_location": "POINT(-122.4194 38.7749)",
    "dest_address": "No. 19 Itam, Uyo"
}
```

### Location Types
1. **home** - Home icon
2. **work** - Work/briefcase icon  
3. **favourite** - Yellow star icon (already implemented)

## Current Implementation Status

### ✅ Already Implemented
1. **Models** - `lib/features/home/data/models/favourite_location_models.dart`
2. **Service** - `lib/core/services/favourite_location_service.dart`
3. **Loading** - Favorite locations are loaded in `_loadFavouriteLocations()`
4. **Display** - Locations shown in recent searches section
5. **Delete** - Long press to delete functionality

### ❌ Needs Implementation
1. **Add Home Location UI** - Reusable dialog/sheet
2. **Add Work Location UI** - Same UI as home
3. **Add Favourite Location UI** - Same UI as home/work
4. **Icon Logic** - Display correct icon based on location type
5. **Update existing favorite display** - Show home/work icons

## Implementation Steps

### Step 1: Update Icon Display Logic

**File:** `lib/features/home/presentation/screens/home_screen.dart`

**Current code (around line 2684-2705):**
```dart
ListTile(
  leading: Image.asset(
    ConstImages.locationPin,
    width: 24.w,
    height: 24.h,
  ),
  // ...
  trailing: Icon(
    Icons.star,
    size: 20.sp,
    color: Colors.amber,
  ),
)
```

**Updated code:**
```dart
ListTile(
  leading: _getFavoriteLocationIcon(fav.name),
  // ...
  trailing: _getFavoriteLocationTrailingIcon(fav.name),
)
```

**Add helper methods:**
```dart
Widget _getFavoriteLocationIcon(String name) {
  switch (name.toLowerCase()) {
    case 'home':
      return Icon(
        Icons.home,
        size: 24.sp,
        color: Color(ConstColors.mainColor),
      );
    case 'work':
      return Icon(
        Icons.work,
        size: 24.sp,
        color: Color(ConstColors.mainColor),
      );
    case 'favourite':
    default:
      return Icon(
        Icons.star,
        size: 24.sp,
        color: Colors.amber,
      );
  }
}

Widget _getFavoriteLocationTrailingIcon(String name) {
  switch (name.toLowerCase()) {
    case 'home':
      return Icon(
        Icons.home_outlined,
        size: 20.sp,
        color: Colors.grey,
      );
    case 'work':
      return Icon(
        Icons.work_outline,
        size: 20.sp,
        color: Colors.grey,
      );
    case 'favourite':
    default:
      return Icon(
        Icons.star,
        size: 20.sp,
        color: Colors.amber,
      );
  }
}
```

### Step 2: Create Add Location Dialog

**File:** `lib/features/home/presentation/screens/home_screen.dart`

Add method to show location dialog:

```dart
Future<void> _showAddLocationDialog({
  required String locationType, // 'home', 'work', or 'favourite'
}) async {
  final TextEditingController addressController = TextEditingController();
  LatLng? selectedLocation;
  
  // Get title based on type
  String getTitle() {
    switch (locationType.toLowerCase()) {
      case 'home':
        return 'Add Home Location';
      case 'work':
        return 'Add Work Location';
      case 'favourite':
      default:
        return 'Add Favourite Location';
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: 500.h,
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 69.w,
                  height: 5.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
                ),
              ),
              
              // Title
              Text(
                getTitle(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              
              SizedBox(height: 20.h),
              
              // Address input
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  hintText: 'Enter address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  prefixIcon: Icon(Icons.location_on),
                ),
                onChanged: (value) {
                  // Optionally implement autocomplete
                },
              ),
              
              SizedBox(height: 20.h),
              
              // Map button (optional)
              OutlinedButton.icon(
                onPressed: () async {
                  // Open map picker
                  // selectedLocation = await _pickLocationFromMap();
                },
                icon: Icon(Icons.map),
                label: Text('Pick from map'),
              ),
              
              Spacer(),
              
              // Save button
              Container(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () async {
                    if (addressController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter an address')),
                      );
                      return;
                    }
                    
                    await _saveFavoriteLocation(
                      name: locationType,
                      address: addressController.text,
                      location: selectedLocation ?? _currentLocation,
                    );
                    
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(ConstColors.mainColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Save Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
```

### Step 3: Create Save Location Method

```dart
Future<void> _saveFavoriteLocation({
  required String name,
  required String address,
  required LatLng location,
}) async {
  try {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saving location...')),
    );
    
    // Format location as POINT
    final destLocation = 'POINT(${location.longitude} ${location.latitude})';
    
    // Create request
    final request = FavouriteLocationRequest(
      name: name,
      destLocation: destLocation,
      destAddress: address,
    );
    
    // Save to API
    await _favouriteService.addFavouriteLocation(request);
    
    // Reload locations
    await _loadFavouriteLocations();
    
    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to save location: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Step 4: Add UI Buttons to Trigger Dialogs

Add buttons in the home screen UI (in the drawer or search section):

```dart
// Add Home Location Button
ListTile(
  leading: Icon(Icons.home, color: Color(ConstColors.mainColor)),
  title: Text('Add Home Location'),
  onTap: () => _showAddLocationDialog(locationType: 'home'),
),

// Add Work Location Button
ListTile(
  leading: Icon(Icons.work, color: Color(ConstColors.mainColor)),
  title: Text('Add Work Location'),
  onTap: () => _showAddLocationDialog(locationType: 'work'),
),

// Add Favourite Location Button
ListTile(
  leading: Icon(Icons.star, color: Colors.amber),
  title: Text('Add Favourite Location'),
  onTap: () => _showAddLocationDialog(locationType: 'favourite'),
),
```

## Icon Mapping

### Leading Icons (in list)
- **Home:** `Icons.home` (filled) - Main color
- **Work:** `Icons.work` (filled) - Main color
- **Favourite:** `Icons.star` (filled) - Amber color

### Trailing Icons (in list)
- **Home:** `Icons.home_outlined` - Grey
- **Work:** `Icons.work_outline` - Grey
- **Favourite:** `Icons.star` - Amber

## API Integration

### Save Location
```dart
POST /api/v1/users/favouriteLocation/

Headers:
  Content-Type: application/json
  Authorization: Bearer {token}

Body:
{
  "name": "home",
  "dest_location": "POINT(-122.4194 38.7749)",
  "dest_address": "No. 19 Itam, Uyo"
}

Response:
{
  "success": true,
  "message": "Location saved successfully",
  "data": {
    "ID": 1,
    "Name": "home",
    "DestLocation": "POINT(-122.4194 38.7749)",
    "DestAddress": "No. 19 Itam, Uyo",
    "CreatedAt": "2025-12-27T07:00:00Z",
    "UpdatedAt": "2025-12-27T07:00:00Z",
    "UserID": 123
  }
}
```

### Get Locations
```dart
GET /api/v1/users/favouriteLocation/

Headers:
  Authorization: Bearer {token}

Response:
[
  {
    "ID": 1,
    "Name": "home",
    "DestLocation": "POINT(-122.4194 38.7749)",
    "DestAddress": "No. 19 Itam, Uyo",
    "CreatedAt": "2025-12-27T07:00:00Z",
    "UpdatedAt": "2025-12-27T07:00:00Z",
    "UserID": 123
  },
  {
    "ID": 2,
    "Name": "work",
    "DestLocation": "POINT(-122.4194 38.7749)",
    "DestAddress": "Office Building, Lagos",
    "CreatedAt": "2025-12-27T07:00:00Z",
    "UpdatedAt": "2025-12-27T07:00:00Z",
    "UserID": 123
  }
]
```

## Testing Checklist

- [ ] Add home location with address
- [ ] Add work location with address
- [ ] Add favourite location with address
- [ ] Verify home icon appears for home location
- [ ] Verify work icon appears for work location
- [ ] Verify star icon appears for favourite location
- [ ] Tap location to set as destination
- [ ] Long press to delete location
- [ ] Verify locations persist after app restart
- [ ] Test with multiple locations of same type
- [ ] Test error handling for failed saves

## Files to Modify

1. **`lib/features/home/presentation/screens/home_screen.dart`**
   - Add `_showAddLocationDialog()` method
   - Add `_saveFavoriteLocation()` method
   - Add `_getFavoriteLocationIcon()` method
   - Add `_getFavoriteLocationTrailingIcon()` method
   - Update favorite location list display
   - Add UI buttons for adding locations

## Benefits

✅ **Unified UI** - Same dialog for home, work, and favourite
✅ **Clear Icons** - Visual distinction between location types
✅ **Easy Access** - Quick access to saved locations
✅ **Persistent** - Locations saved to backend
✅ **User-Friendly** - Simple add/delete operations

## Next Steps

1. Implement icon helper methods
2. Create add location dialog
3. Add save location method
4. Add UI buttons to trigger dialogs
5. Test all functionality
6. Handle edge cases (duplicate names, etc.)

This implementation will provide a complete favorite location system with proper icons and easy management!
