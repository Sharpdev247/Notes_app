#!/usr/bin/env python3
from PIL import Image
import os

# Source image
source_path = "/Users/basitkhan/Desktop/projects/flutter_projects/notes_app/assets/logo.png"
ios_icon_dir = "/Users/basitkhan/Desktop/projects/flutter_projects/notes_app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
android_icon_dir = "/Users/basitkhan/Desktop/projects/flutter_projects/notes_app/android/app/src/main/res"

# Open the source image
img = Image.open(source_path).convert("RGBA")

# iOS icon sizes needed
ios_sizes = [
    (20, "Icon-App-20x20@1x.png"),
    (40, "Icon-App-20x20@2x.png"),
    (60, "Icon-App-20x20@3x.png"),
    (29, "Icon-App-29x29@1x.png"),
    (58, "Icon-App-29x29@2x.png"),
    (87, "Icon-App-29x29@3x.png"),
    (40, "Icon-App-40x40@1x.png"),
    (80, "Icon-App-40x40@2x.png"),
    (120, "Icon-App-40x40@3x.png"),
    (120, "Icon-App-60x60@2x.png"),
    (180, "Icon-App-60x60@3x.png"),
    (76, "Icon-App-76x76@1x.png"),
    (152, "Icon-App-76x76@2x.png"),
    (167, "Icon-App-83.5x83.5@2x.png"),
    (1024, "Icon-App-1024x1024@1x.png"),
]

for size, filename in ios_sizes:
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    output_path = os.path.join(ios_icon_dir, filename)
    resized.save(output_path, "PNG")
    print(f"✅ Generated {filename} ({size}x{size})")

print("\n✅ All iOS icons regenerated successfully!")

# Android icon sizes
print("\n🤖 Generating Android icons...")
android_sizes = [
    ("mipmap-mdpi", 48),
    ("mipmap-hdpi", 72),
    ("mipmap-xhdpi", 96),
    ("mipmap-xxhdpi", 144),
    ("mipmap-xxxhdpi", 192),
]

for dpi_folder, size in android_sizes:
    dpi_path = os.path.join(android_icon_dir, dpi_folder)
    os.makedirs(dpi_path, exist_ok=True)
    
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    filepath = os.path.join(dpi_path, "ic_launcher.png")
    resized.save(filepath, "PNG")
    print(f"✅ Created {dpi_folder}/ic_launcher.png ({size}x{size})")

print("\n✨ All icons (iOS + Android) regenerated successfully from logo.png!")
