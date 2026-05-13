# fyr CLI Tool

The `fyr` CLI tool allows you to easily customize your portfolio site without touching the code. You can update your profile, skills, social links, and add custom apps that link to your other projects.

## Setup

The CLI tool is written in Dart. To run it, make sure you have the Dart SDK installed (which comes with Flutter).

Run the tool from the root of the project:

```bash
dart bin/fyr.dart [command] [options]
```

## Commands

### 1. Setup Wizard
The easiest way to set up your portfolio for the first time or do a full update.
```bash
dart bin/fyr.dart wizard
```
This will walk you through:
- Name and Professional Title
- "About Me" description
- Tab Bar Title (the title shown in the browser tab)
- Profile Picture path (default is `assets/face.jpg`)
- Skills (comma separated)
- Adding your first custom app

### 2. Add a Custom App
Directly add a new app link to your desktop.
```bash
dart bin/fyr.dart add-app
```
You will be asked for the app title, URL, icon choice, and accent color.

### 3. Individual Updates
Update specific fields quickly using flags:
- `--name "Your Name"`
- `--title "Your Role"`
- `--about "Brief description"`
- `--tab-title "Browser Tab Name"`
- `--profile-pic "assets/new_face.jpg"`

Example:
```bash
dart bin/fyr.dart --name "Archie" --tab-title "Archie's Portfolio"
```

## Applying Changes

Because the configuration is bundled with the site, you must **rebuild and redeploy** your site for the changes to take effect:

1. Run the CLI to update your config.
2. Run `flutter build web`.
3. Deploy the `build/web` folder to your hosting provider.

## Icons
When adding an app, you can choose from several built-in icons:
- Computer
- Code
- Web/Language
- GitHub
- Link
- Mobile
- Music/Album
- Headphones
