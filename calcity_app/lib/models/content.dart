class NewsItem {
  final int id;
  final String title;
  final String content;
  final String? sourceUrl;
  final String? category;
  final String? imageUrl;
  final String? videoUrl;
  final bool featured;
  final DateTime createdAt;

  NewsItem({
    required this.id,
    required this.title,
    required this.content,
    this.sourceUrl,
    this.category,
    this.imageUrl,
    this.videoUrl,
    this.featured = false,
    required this.createdAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      sourceUrl: json['source_url'] as String?,
      category: json['category'] as String?,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      featured: json['featured'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'source_url': sourceUrl,
        'category': category,
        'image_url': imageUrl,
        'video_url': videoUrl,
        'featured': featured,
        'created_at': createdAt.toIso8601String(),
      };

  String get excerpt =>
      content.length > 150 ? '${content.substring(0, 150)}...' : content;
}

class EventItem {
  final int id;
  final String title;
  final String? description;
  final String? location;
  final String? imageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;

  EventItem({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.imageUrl,
    this.startDate,
    this.endDate,
    this.category,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      imageUrl: json['image_url'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'image_url': imageUrl,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'category': category,
      };
}

class AlertItem {
  final int id;
  final String title;
  final String message;
  final String severity;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  AlertItem({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'severity': severity,
        'image_url': imageUrl,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };
}

class CouncilAgendaItem {
  final int id;
  final String title;
  final String? description;
  final DateTime? meetingDate;
  final String? pdfUrl;
  final DateTime createdAt;

  CouncilAgendaItem({
    required this.id,
    required this.title,
    this.description,
    this.meetingDate,
    this.pdfUrl,
    required this.createdAt,
  });

  factory CouncilAgendaItem.fromJson(Map<String, dynamic> json) {
    return CouncilAgendaItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      meetingDate: json['meeting_date'] != null
          ? DateTime.parse(json['meeting_date'] as String)
          : null,
      pdfUrl: json['pdf_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'meeting_date': meetingDate?.toIso8601String(),
        'pdf_url': pdfUrl,
        'created_at': createdAt.toIso8601String(),
      };
}

class BusinessItem {
  final int id;
  final String name;
  final String? description;
  final String? category;
  final String? imageUrl;
  final String? contactPhone;
  final String? contactEmail;
  final String? website;
  final String? address;
  final bool isHomeBased;
  final bool isFeatured;
  final bool isDemo;

  BusinessItem({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.imageUrl,
    this.contactPhone,
    this.contactEmail,
    this.website,
    this.address,
    this.isHomeBased = false,
    this.isFeatured = false,
    this.isDemo = false,
  });

  factory BusinessItem.fromJson(Map<String, dynamic> json) {
    return BusinessItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String?,
      imageUrl: json['image_url'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      website: json['website'] as String?,
      address: json['address'] as String?,
      isHomeBased: json['is_home_based'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isDemo: json['is_demo'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'image_url': imageUrl,
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'website': website,
        'address': address,
        'is_home_based': isHomeBased,
        'is_featured': isFeatured,
      };
}

class WeatherInfo {
  final int id;
  final String headline;
  final String? detail;
  final int? temperatureHigh;
  final int? temperatureLow;
  final String? sunrise;
  final String? sunset;
  final String? humidity;
  final String? wind;
  final String? fireRisk;
  final DateTime createdAt;

  WeatherInfo({
    required this.id,
    required this.headline,
    this.detail,
    this.temperatureHigh,
    this.temperatureLow,
    this.sunrise,
    this.sunset,
    this.humidity,
    this.wind,
    this.fireRisk,
    required this.createdAt,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      id: json['id'] as int,
      headline: json['headline'] as String? ?? '',
      detail: json['detail'] as String?,
      temperatureHigh: json['temperature_high'] as int?,
      temperatureLow: json['temperature_low'] as int?,
      sunrise: json['sunrise'] as String?,
      sunset: json['sunset'] as String?,
      humidity: json['humidity'] as String?,
      wind: json['wind'] as String?,
      fireRisk: json['fire_risk'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class SchoolItem {
  final int id;
  final String name;
  final String? type;
  final String? address;
  final String? phone;
  final String? website;
  final String? calendarUrl;
  final String? bellScheduleUrl;
  final String? description;

  SchoolItem({
    required this.id,
    required this.name,
    this.type,
    this.address,
    this.phone,
    this.website,
    this.calendarUrl,
    this.bellScheduleUrl,
    this.description,
  });

  factory SchoolItem.fromJson(Map<String, dynamic> json) {
    return SchoolItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: json['type'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      calendarUrl: json['calendar_url'] as String?,
      bellScheduleUrl: json['bell_schedule_url'] as String?,
      description: json['description'] as String?,
    );
  }
}

class ChurchItem {
  final int id;
  final String name;
  final String? denomination;
  final String? description;
  final String? address;
  final String? phone;
  final String? website;
  final String? serviceTimes;
  final String? events;
  final String? foodGiveaway;
  final String? imageUrl;
  final bool isDemo;

  ChurchItem({
    required this.id,
    required this.name,
    this.denomination,
    this.description,
    this.address,
    this.phone,
    this.website,
    this.serviceTimes,
    this.events,
    this.foodGiveaway,
    this.imageUrl,
    this.isDemo = false,
  });

  factory ChurchItem.fromJson(Map<String, dynamic> json) {
    return ChurchItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      denomination: json['denomination'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      serviceTimes: json['service_times'] as String?,
      events: json['events'] as String?,
      foodGiveaway: json['food_giveaway'] as String?,
      imageUrl: json['image_url'] as String?,
      isDemo: json['is_demo'] as bool? ?? false,
    );
  }
}
