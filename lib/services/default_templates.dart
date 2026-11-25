import '../models/awrad_task.dart';
import '../models/awrad_template.dart';

/// Built-in curated Awrad lists available for onboarding and template import.
class DefaultAwradTemplates {
  static const dailyEssentials = AwradTemplate(
    id: 'daily_essentials',
    name: 'Daily Essentials',
    description: 'Core daily Quran, prayers, adhkar, and reading habits.',
    tasks: [
      AwradTemplateTask(title: 'Quran', category: AwradCategory.quran),
      AwradTemplateTask(
        title: 'Fajr prayer in Jamaa',
        category: AwradCategory.prayer,
      ),
      AwradTemplateTask(title: 'Duha', category: AwradCategory.sunnah),
      AwradTemplateTask(
        title: 'Morning Adhkar',
        category: AwradCategory.adhkar,
      ),
      AwradTemplateTask(
        title: 'Evening Adhkar',
        category: AwradCategory.adhkar,
      ),
      AwradTemplateTask(
        title: '100 Istighfar',
        category: AwradCategory.adhkar,
      ),
      AwradTemplateTask(
        title: '100 La ilaha illa Allah',
        category: AwradCategory.adhkar,
      ),
      AwradTemplateTask(
        title: '100 Salawat',
        category: AwradCategory.adhkar,
      ),
      AwradTemplateTask(
        title: 'Reading',
        category: AwradCategory.knowledge,
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
