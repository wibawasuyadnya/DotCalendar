# Uninstall

## Remove the App

1. Quit DotCalendar from the menu bar (click the grid icon > Quit)
2. Drag `DotCalendar.app` from **Applications** to **Trash**

## Clean Up Data

Remove generated files and preferences:

```bash
# Remove wallpaper
rm -rf ~/Pictures/DotCalendar

# Remove thumbnail
rm -f ~/Library/Application\ Support/com.apple.wallpaper/aerials/thumbnails/DOTCAL-001.png

# Remove preferences
defaults delete app.dotcalendar 2>/dev/null
```

## Remove from Login Items

If you enabled "Launch at Login", it will be automatically removed when you delete the app. If it persists:

1. Open **System Settings > General > Login Items**
2. Find DotCalendar and remove it

## Restore Default Wallpaper

After uninstalling, go to **System Settings > Wallpaper** and select a different wallpaper.
