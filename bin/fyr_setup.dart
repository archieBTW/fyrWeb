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
    ..addOption('terminal-name', help: 'Update terminal user name')
    ..addOption('system-name', help: 'Update system/project name')
    ..addOption('email', help: 'Update contact email')
    ..addOption('location', help: 'Update contact location')
    ..addCommand('add-app')
    ..addCommand('add-experience')
    ..addCommand('add-social');

  final results = parser.parse(arguments);

  if (results['help']) {
    print('fyr CLI - Manage your portfolio site\n');
    print(parser.usage);
    print('\nCommands:');
    print('  wizard          Run the setup wizard');
    print('  add-app         Add a new app link');
    print('  add-experience  Add work experience');
    print('  add-social      Add a social link');
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

  if (results.command?.name == 'add-experience') {
    await addExperience();
    return;
  }

  if (results.command?.name == 'add-social') {
    await addSocial();
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
  if (results['terminal-name'] != null) {
    config['profile']['terminalName'] = results['terminal-name'];
    changed = true;
  }
  if (results['system-name'] != null) {
    config['profile']['systemName'] = results['system-name'];
    changed = true;
  }
  if (results['email'] != null) {
    config['profile']['email'] = results['email'];
    changed = true;
  }
  if (results['location'] != null) {
    config['profile']['location'] = results['location'];
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
  config['profile']['terminalName'] = ask('Terminal User Name', defaultValue: config['profile']['terminalName']);
  config['profile']['systemName'] = ask('System/Project Name', defaultValue: config['profile']['systemName']);
  config['profile']['email'] = ask('Email', defaultValue: config['profile']['email']);
  config['profile']['location'] = ask('Location', defaultValue: config['profile']['location']);
  config['profile']['profilePic'] = ask('Profile Pic Path', defaultValue: config['profile']['profilePic']);

  print('\nSkills (comma separated):');
  String skillsInput = ask('Skills', defaultValue: (config['skills'] as List).join(', '));
  config['skills'] = skillsInput.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  print('\n--- Social Links ---');
  print('Would you like to clear existing socials and add new? (y/n)');
  if (stdin.readLineSync()?.toLowerCase() == 'y') {
    config['socials'] = [];
    bool adding = true;
    while (adding) {
      await addSocial(existingConfig: config);
      print('Add another social link? (y/n)');
      adding = stdin.readLineSync()?.toLowerCase() == 'y';
    }
  }

  print('\n--- Work Experience ---');
  print('Would you like to clear existing experience and add new? (y/n)');
  if (stdin.readLineSync()?.toLowerCase() == 'y') {
    config['experience'] = [];
    bool adding = true;
    while (adding) {
      await addExperience(existingConfig: config);
      print('Add another experience? (y/n)');
      adding = stdin.readLineSync()?.toLowerCase() == 'y';
    }
  }

  print('\n--- Apps ---');
  print('Would you like to add a new app? (y/n)');
  if (stdin.readLineSync()?.toLowerCase() == 'y') {
    await addApp(existingConfig: config);
  }

  await saveConfig(config);
  print('\nWizard complete! Configuration saved.');
}

Future<void> addSocial({Map<String, dynamic>? existingConfig}) async {
  Map<String, dynamic> config = existingConfig ?? await readConfig();
  
  print('\n--- Add Social Link ---');
  String name = ask('Social Name (e.g. GitHub, LinkedIn)');
  String url = ask('Profile URL');
  
  print('\nChoose an icon:');
  const icons = {
    '1': {'name': 'github', 'label': 'GitHub'},
    '2': {'name': 'linkedin', 'label': 'LinkedIn'},
    '3': {'name': 'twitter', 'label': 'Twitter'},
    '4': {'name': 'instagram', 'label': 'Instagram'},
    '5': {'name': 'facebook', 'label': 'Facebook'},
    '6': {'name': 'youtube', 'label': 'YouTube'},
    '7': {'name': 'tiktok', 'label': 'TikTok'},
    '8': {'name': 'link', 'label': 'Generic Link'},
  };

  icons.forEach((key, value) => print('$key: ${value['label']}'));
  String iconChoice = ask('Icon Choice', defaultValue: '8');
  String iconName = icons[iconChoice]?['name'] ?? 'link';

  List socials = config['socials'] as List;
  socials.add({
    'id': name.toLowerCase().replaceAll(' ', '_'),
    'name': name,
    'url': url,
    'icon': iconName,
  });

  if (existingConfig == null) {
    await saveConfig(config);
    print('\nSocial link added successfully!');
  }
}

Future<void> addExperience({Map<String, dynamic>? existingConfig}) async {
  Map<String, dynamic> config = existingConfig ?? await readConfig();
  
  print('\n--- Add Experience ---');
  String company = ask('Company');
  String role = ask('Role');
  String period = ask('Period (e.g. 2020 - Present)');
  String description = ask('Description');

  List exp = config['experience'] as List;
  exp.add({
    'company': company,
    'role': role,
    'period': period,
    'description': description,
  });

  if (existingConfig == null) {
    await saveConfig(config);
    print('\nExperience added successfully!');
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

  if (existingConfig == null) {
    await saveConfig(config);
    print('\nApp "$title" added successfully!');
  }
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
