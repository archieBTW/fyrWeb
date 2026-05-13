import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

const String configPath = 'assets/config.json';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
    ..addCommand('wizard')
    ..addOption('name', help: 'Update profile name')
    ..addOption('title', help: 'Update profile title')
    ..addOption('about', help: 'Update about me text')
    ..addOption('tab-title', help: 'Update tab bar title')
    ..addOption('profile-pic', help: 'Update profile picture path')
    ..addCommand('add-app');

  final results = parser.parse(arguments);

  if (results['help']) {
    print('fyr CLI - Manage your portfolio site\n');
    print(parser.usage);
    print('\nCommands:');
    print('  wizard   Run the setup wizard');
    print('  add-app  Add a new app link');
    return;
  }

  if (results.command?.name == 'wizard') {
    await runWizard();
    return;
  }

  if (results.command?.name == 'add-app') {
    await addApp();
    return;
  }

  // Handle individual updates
  Map<String, dynamic> config = await readConfig();
  bool changed = false;

  if (results['name'] != null) {
    config['profile']['name'] = results['name'];
    changed = true;
  }
  if (results['title'] != null) {
    config['profile']['title'] = results['title'];
    changed = true;
  }
  if (results['about'] != null) {
    config['profile']['about'] = results['about'];
    changed = true;
  }
  if (results['tab-title'] != null) {
    config['profile']['tabTitle'] = results['tab-title'];
    changed = true;
  }
  if (results['profile-pic'] != null) {
    config['profile']['profilePic'] = results['profile-pic'];
    changed = true;
  }

  if (changed) {
    await saveConfig(config);
    print('Config updated successfully.');
  } else if (arguments.isEmpty) {
    print('No arguments provided. Use --help for usage.');
  }
}

Future<void> runWizard() async {
  print('=== fyr Portfolio Wizard ===\n');
  Map<String, dynamic> config = await readConfig();

  config['profile']['name'] = ask('Name', defaultValue: config['profile']['name']);
  config['profile']['title'] = ask('Title', defaultValue: config['profile']['title']);
  config['profile']['about'] = ask('About Me', defaultValue: config['profile']['about']);
  config['profile']['tabTitle'] = ask('Tab Bar Title', defaultValue: config['profile']['tabTitle']);
  config['profile']['profilePic'] = ask('Profile Pic Path', defaultValue: config['profile']['profilePic']);

  print('\nSkills (comma separated):');
  String skillsInput = ask('Skills', defaultValue: (config['skills'] as List).join(', '));
  config['skills'] = skillsInput.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  print('\nWould you like to add a new app? (y/n)');
  if (stdin.readLineSync()?.toLowerCase() == 'y') {
    await addApp(existingConfig: config);
  } else {
    await saveConfig(config);
    print('\nWizard complete! Configuration saved.');
  }
}

Future<void> addApp({Map<String, dynamic>? existingConfig}) async {
  Map<String, dynamic> config = existingConfig ?? await readConfig();
  
  print('\n--- Add New App ---');
  String title = ask('App Title');
  String url = ask('App URL');
  String id = title.toLowerCase().replaceAll(' ', '_');

  print('\nChoose an icon:');
  const icons = {
    '1': {'name': 'computer', 'label': 'Computer'},
    '2': {'name': 'code', 'label': 'Code'},
    '3': {'name': 'language', 'label': 'Web/Language'},
    '4': {'name': 'github', 'label': 'GitHub'},
    '5': {'name': 'link', 'label': 'Link'},
    '6': {'name': 'smartphone', 'label': 'Mobile'},
    '7': {'name': 'album', 'label': 'Music/Album'},
    '8': {'name': 'headphones', 'label': 'Headphones'},
  };

  icons.forEach((key, value) => print('$key: ${value['label']}'));
  String iconChoice = ask('Icon Choice', defaultValue: '5');
  String iconName = icons[iconChoice]?['name'] ?? 'link';

  String color = ask('Accent Color (Hex with 0x)', defaultValue: '0xFF2196F3');

  List apps = config['apps'] as List;
  apps.add({
    'id': id,
    'title': title,
    'url': url,
    'icon': iconName,
    'color': color,
  });

  await saveConfig(config);
  print('\nApp "$title" added successfully!');
}

String ask(String question, {String? defaultValue}) {
  stdout.write('$question ${defaultValue != null ? "[$defaultValue]" : ""}: ');
  String? input = stdin.readLineSync();
  if (input == null || input.isEmpty) {
    return defaultValue ?? '';
  }
  return input;
}

Future<Map<String, dynamic>> readConfig() async {
  File file = File(configPath);
  if (!await file.exists()) {
    return {
      'profile': {},
      'skills': [],
      'socials': [],
      'apps': [],
      'experience': []
    };
  }
  return jsonDecode(await file.readAsString());
}

Future<void> saveConfig(Map<String, dynamic> config) async {
  File file = File(configPath);
  JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  await file.writeAsString(encoder.convert(config));
}
