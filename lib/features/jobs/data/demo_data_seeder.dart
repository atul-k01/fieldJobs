import 'package:intl/intl.dart';
import '../models/checklist_item_model.dart';
import '../models/job_model.dart';

/// Generates realistic demo data containing at least 200 jobs spread across 2 weeks
/// for the two demo technicians (Alex Rivera & Sarah Connor).
class DemoDataSeeder {
  static final List<String> _appliances = [
    'Samsung French Door Refrigerator',
    'Bosch 800 Series Dishwasher',
    'Whirlpool Front Load Washer',
    'LG Smart Electric Dryer',
    'GE Profile Induction Range',
    'KitchenAid Built-In Microwave',
    'Miele Commercial Washing Machine',
    'Frigidaire Upright Freezer',
    'Maytag High-Efficiency Washer',
    'Siemens Built-In Coffee Machine',
  ];

  static final List<String> _problems = [
    'Not cooling properly, clicking noise from compressor',
    'Water not draining, error code E24 on display',
    'Loud vibration during spin cycle, burning rubber smell',
    'Takes 3 cycles to dry clothes, lint trap clean',
    'Left front burner not heating, touch control unresponsive',
    'Door latch mechanism jammed, turntable motor spinning slowly',
    'Water leaking from bottom drawer during rinse cycle',
    'Ice maker overflowed into freezer compartment',
    'Continuous humming sound, drum will not turn',
    'Error F08 thermostat malfunction, cuts power intermittently',
  ];

  static final List<String> _customerNames = [
    'David Miller', 'Emma Watson', 'James Anderson', 'Sophia Taylor',
    'Michael Brown', 'Olivia Davis', 'William Wilson', 'Emily Evans',
    'Robert Thomas', 'Ava Johnson', 'Daniel White', 'Mia Martin',
    'Christopher Lee', 'Isabella Hall', 'Matthew Wright', 'Charlotte Green',
    'Anthony Harris', 'Amelia Clark', 'Joseph Lewis', 'Harper Walker',
  ];

  static final List<String> _streets = [
    '142 Elm Street, Oxford',
    '78 Meadow Lane, Cambridge',
    '12 Kingfisher Court, Bristol',
    '59 Queen Street, Reading',
    '33 Victoria Road, Manchester',
    '88 High Street, Birmingham',
    '24 Park Avenue, Leeds',
    '105 Mill Lane, Southampton',
    '47 Church Lane, Sheffield',
    '91 St. John Street, London',
  ];

  static final List<String> _timeWindows = [
    '08:00 - 10:00 AM',
    '10:00 - 12:00 PM',
    '12:30 - 02:30 PM',
    '02:30 - 04:30 PM',
    '04:30 - 06:30 PM',
  ];

  static final List<List<String>> _standardChecklists = [
    [
      'Visual inspection of power cable and ground connection',
      'Run diagnostic cycle and read error code memory',
      'Test heating element / thermostat continuity with multimeter',
      'Inspect water inlet valve and drainage filter for blockages',
      'Perform electrical safety earth leakage test before closing unit',
      'Verify normal operating cycle with customer signature',
    ],
    [
      'Verify water supply shut-off valve is functional',
      'Inspect drain pump impeller for foreign object obstruction',
      'Clean water level pressure switch sensor tube',
      'Check drum bearings and motor drive belt tension',
      'Confirm zero water leaks under full operating pressure',
    ],
    [
      'Check evaporator fan motor operation and airflow path',
      'Inspect condenser coils and clean dust accumulation',
      'Verify defrost heater resistance reading',
      'Inspect door gasket seal for magnetic leakage',
      'Confirm internal temperature stabilizes at target setpoint',
    ],
  ];

  /// Generates exactly 200 jobs (100 for Alex, 100 for Sarah) spread over 14 days
  static List<JobModel> generate200Jobs() {
    final List<JobModel> jobs = [];
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');

    final techs = ['alex@fieldjobs.com', 'sarah@fieldjobs.com'];

    int jobCounter = 1;

    for (final techEmail in techs) {
      // 100 jobs for each technician
      // Spread across 14 days (1 day overdue, today, and 12 upcoming days)
      for (int dayOffset = -1; dayOffset < 13; dayOffset++) {
        final targetDate = now.add(Duration(days: dayOffset));
        final dateStr = dateFormat.format(targetDate);
        final jobsForDay = (dayOffset == -1)
            ? 2 // 2 overdue jobs from yesterday
            : (dayOffset == 0 ? 5 : 7); // 5 today, 7 on upcoming days

        for (int i = 0; i < jobsForDay; i++) {
          if (jobs.where((j) => j.assignedTo == techEmail).length >= 100) break;

          final jobId = 'job-${jobCounter.toString().padLeft(4, '0')}';
          jobCounter++;

          final appliance = _appliances[(jobCounter + i) % _appliances.length];
          final problem = _problems[(jobCounter + i) % _problems.length];
          final customer = _customerNames[(jobCounter + i) % _customerNames.length];
          final street = _streets[(jobCounter + i) % _streets.length];
          final timeWindow = _timeWindows[i % _timeWindows.length];

          // Status distribution: Overdue jobs are assigned and uncompleted from yesterday
          String initialStatus = 'assigned';
          if (dayOffset == 0 && i == 0) {
            initialStatus = 'on_site';
          } else if (dayOffset == 0 && i == 1) {
            initialStatus = 'travelling';
          }

          final checklistTemplate = _standardChecklists[jobCounter % _standardChecklists.length];
          final List<ChecklistItemModel> checklists = [];
          for (int c = 0; c < checklistTemplate.length; c++) {
            checklists.add(
              ChecklistItemModel(
                id: 'chk-$jobId-$c',
                jobId: jobId,
                title: checklistTemplate[c],
                isCompleted: (initialStatus == 'on_site' && c == 0),
                sortOrder: c,
              ),
            );
          }

          jobs.add(
            JobModel(
              id: jobId,
              assignedTo: techEmail,
              customerName: customer,
              customerPhone: '+44 7700 900${(100 + jobCounter)}',
              address: '$street, Apt ${10 + i}',
              scheduledDate: dateStr,
              timeWindow: timeWindow,
              appliance: appliance,
              problemDescription: problem,
              status: initialStatus,
              technicianNotes: (initialStatus == 'on_site')
                  ? 'Arrived on site. Customer reported error began 2 days ago.'
                  : null,
              version: 1,
              syncStatus: 'synced',
              updatedAt: DateTime.now().toIso8601String(),
              checklists: checklists,
              photos: const [],
            ),
          );
        }
      }
    }

    return jobs;
  }
}
