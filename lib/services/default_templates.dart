import '../models/awrad_task.dart';
import '../models/awrad_template.dart';

/// Built-in curated Awrad lists available for onboarding and template import.
class DefaultAwradTemplates {
  static const dailyEssentials = AwradTemplate(
    id: 'daily_essentials',
    name: 'Daily Essentials',
    description: 'Core daily Quran, adhkar, congregation, and spiritual habits.',
    tasks: [
      AwradTemplateTask(title: 'Read Quran', category: AwradCategory.quran),
      AwradTemplateTask(
        title: 'Fajr prayer in congregation',
        category: AwradCategory.prayer,
      ),
      AwradTemplateTask(title: 'Duha prayer', category: AwradCategory.sunnah),
      AwradTemplateTask(title: 'Morning adhkar', category: AwradCategory.adhkar),
      AwradTemplateTask(title: 'Evening adhkar', category: AwradCategory.adhkar),
      AwradTemplateTask(
        title: '200 times istighfar',
        category: AwradCategory.adhkar,
      ),
      AwradTemplateTask(
        title: '200 times “La ilaha illa Allah”',
        category: AwradCategory.adhkar,
      ),
      AwradTemplateTask(
        title: '200 blessings on the Prophet',
        category: AwradCategory.adhkar,
      ),
      AwradTemplateTask(
        title: 'Fasting',
        category: AwradCategory.fasting,
        repeatWeekdays: {DateTime.monday, DateTime.thursday},
      ),
      AwradTemplateTask(
        title: 'Read for half an hour',
        category: AwradCategory.knowledge,
      ),
      AwradTemplateTask(
        title: 'Remember the Hereafter',
        category: AwradCategory.other,
      ),
      AwradTemplateTask(
        title: 'Spiritual connection with dawah',
        category: AwradCategory.other,
      ),
    ],
  );

  static const morningEveningAdhkar = AwradTemplate(
    id: 'morning_evening_adhkar',
    name: 'Morning & Evening Adhkar',
    description: 'Focused remembrance routine for morning, evening, and before sleep.',
    tasks: [
      AwradTemplateTask(title: 'Morning adhkar', category: AwradCategory.adhkar),
      AwradTemplateTask(title: 'Evening adhkar', category: AwradCategory.adhkar),
      AwradTemplateTask(title: 'Surah Al-Mulk before sleep', category: AwradCategory.quran),
      AwradTemplateTask(title: 'Adhkar before sleep', category: AwradCategory.adhkar),
      AwradTemplateTask(title: '100 times SubhanAllah wa bihamdihi', category: AwradCategory.adhkar),
    ],
  );

  static const ramadanIntensive = AwradTemplate(
    id: 'ramadan_intensive',
    name: 'Ramadan Intensive',
    description: 'Elevated Quran, Qiyam, charity, and dua routine for blessed seasons.',
    tasks: [
      AwradTemplateTask(title: 'Read 1 Juz of Quran', category: AwradCategory.quran),
      AwradTemplateTask(title: 'Taraweeh / Qiyam al-Layl', category: AwradCategory.sunnah),
      AwradTemplateTask(title: 'Tahajjud & Pre-Fajr Dua', category: AwradCategory.sunnah),
      AwradTemplateTask(title: 'Daily Sadaqah', category: AwradCategory.other),
      AwradTemplateTask(title: 'Dua before Iftar', category: AwradCategory.adhkar),
      AwradTemplateTask(
        title: 'Surah Al-Kahf',
        category: AwradCategory.quran,
        repeatWeekdays: {DateTime.friday},
      ),
    ],
  );

  static const List<AwradTemplate> all = [
    dailyEssentials,
    morningEveningAdhkar,
    ramadanIntensive,
  ];
}
