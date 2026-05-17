import 'dart:convert';

class AppConfig {
  final ProfileConfig profile;
  final List<SkillCategory> skills;
  final List<SocialLink> socials;
  final List<CustomApp> apps;
  final List<ExperienceItem> experience;
  final List<EducationItem> education;
  final List<String> certifications;

  AppConfig({
    required this.profile,
    required this.skills,
    required this.socials,
    required this.apps,
    required this.experience,
    required this.education,
    required this.certifications,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      profile: ProfileConfig.fromJson(json['profile'] ?? {}),
      skills:
          (json['skills'] as List?)?.map((e) {
            if (e is String)
              return SkillCategory(category: 'Other', items: [e]);
            return SkillCategory.fromJson(e);
          }).toList() ??
          [],
      socials:
          (json['socials'] as List?)
              ?.map((e) => SocialLink.fromJson(e))
              .toList() ??
          [],
      apps:
          (json['apps'] as List?)?.map((e) => CustomApp.fromJson(e)).toList() ??
          [],
      experience:
          (json['experience'] as List?)
              ?.map((e) => ExperienceItem.fromJson(e))
              .toList() ??
          [],
      education:
          (json['education'] as List?)
              ?.map((e) => EducationItem.fromJson(e))
              .toList() ??
          [],
      certifications: List<String>.from(json['certifications'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'profile': profile.toJson(),
    'skills': skills.map((e) => e.toJson()).toList(),
    'socials': socials.map((e) => e.toJson()).toList(),
    'apps': apps.map((e) => e.toJson()).toList(),
    'experience': experience.map((e) => e.toJson()).toList(),
    'education': education.map((e) => e.toJson()).toList(),
    'certifications': certifications,
  };
}

class ProfileConfig {
  final String name;
  final String title;
  final String about;
  final String profilePic;
  final String tabTitle;
  final String terminalName;
  final String systemName;
  final String email;
  final String location;

  ProfileConfig({
    required this.name,
    required this.title,
    required this.about,
    required this.profilePic,
    required this.tabTitle,
    required this.terminalName,
    required this.systemName,
    required this.email,
    required this.location,
  });

  factory ProfileConfig.fromJson(Map<String, dynamic> json) {
    return ProfileConfig(
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      about: json['about'] ?? '',
      profilePic: json['profilePic'] ?? 'assets/face.jpg',
      tabTitle: json['tabTitle'] ?? 'Portfolio',
      terminalName: json['terminalName'] ?? 'archie',
      systemName: json['systemName'] ?? 'fyrWeb',
      email: json['email'] ?? '',
      location: json['location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'title': title,
    'about': about,
    'profilePic': profilePic,
    'tabTitle': tabTitle,
    'terminalName': terminalName,
    'systemName': systemName,
    'email': email,
    'location': location,
  };
}

class SocialLink {
  final String id;
  final String name;
  final String url;
  final String icon;

  SocialLink({
    required this.id,
    required this.name,
    required this.url,
    required this.icon,
  });

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    return SocialLink(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      icon: json['icon'] ?? 'link',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'icon': icon,
  };
}

class CustomApp {
  final String id;
  final String title;
  final String url;
  final String icon;
  final String color;

  CustomApp({
    required this.id,
    required this.title,
    required this.url,
    required this.icon,
    required this.color,
  });

  factory CustomApp.fromJson(Map<String, dynamic> json) {
    return CustomApp(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      icon: json['icon'] ?? 'apps',
      color: json['color'] ?? '0xFF2196F3',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'icon': icon,
    'color': color,
  };
}

class ExperienceItem {
  final String company;
  final String role;
  final String period;
  final String description;

  ExperienceItem({
    required this.company,
    required this.role,
    required this.period,
    required this.description,
  });

  factory ExperienceItem.fromJson(Map<String, dynamic> json) {
    return ExperienceItem(
      company: json['company'] ?? '',
      role: json['role'] ?? '',
      period: json['period'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'company': company,
    'role': role,
    'period': period,
    'description': description,
  };
}

class EducationItem {
  final String school;
  final String degree;
  final String period;

  EducationItem({
    required this.school,
    required this.degree,
    required this.period,
  });

  factory EducationItem.fromJson(Map<String, dynamic> json) {
    return EducationItem(
      school: json['school'] ?? '',
      degree: json['degree'] ?? '',
      period: json['period'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'school': school,
    'degree': degree,
    'period': period,
  };
}

class SkillCategory {
  final String category;
  final List<String> items;

  SkillCategory({required this.category, required this.items});

  factory SkillCategory.fromJson(Map<String, dynamic> json) {
    return SkillCategory(
      category: json['category'] ?? '',
      items: List<String>.from(json['items'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {'category': category, 'items': items};
}
