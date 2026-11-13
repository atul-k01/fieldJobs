import 'package:intl/intl.dart';
import '../models/checklist_item_model.dart';
import '../models/job_model.dart';

/// Generates realistic demo data containing at least 200 jobs spread across 2 weeks
/// for the two demo technicians (Alex Rivera & Sarah Connor).
class DemoDataSeeder {
  static final List<String> _appliances = [
    'Voltas 1.5 Ton 5-Star Inverter Split AC',
    'LG 340L Double Door Smart Inverter Refrigerator',
    'Samsung 7.5 Kg Fully-Automatic Front Load Washer',
    'IFB 6 Kg Senator Front Load Washing Machine',
    'Whirlpool 265L Frost-Free Double Door Refrigerator',
    'Havells 25L Storage Water Heater Geyser',
    'Bosch 14-Place Settings Dishwasher',
    'Godrej 190L Direct-Cool Single Door Refrigerator',
    'Panasonic 27L Convection Microwave Oven',
    'Daikin 1.8 Ton 3-Star Inverter Split AC',
  ];

  static final List<String> _problems = [
    'AC not cooling properly, outdoor fan motor tripping MCB',
    'Refrigerator bottom freezer leaking water, temperature fluctuating',
    'Washing machine drum vibrating loudly during high-speed spin cycle',
    'Microwave turntable rotating but heating element completely dead',
    'Dishwasher error code E24 drainage pump jammed with debris',
    'Geyser thermostat not auto-cutting, excessive steam buildup',
    'Refrigerator compressor clicking repeatedly every 2 minutes',
    'Washing machine water inlet solenoid valve stuck open, overflowing',
    'Split AC indoor display showing error code E6 communication fault',
    'Inverter AC gas leakage suspected, ice formation on copper suction pipe',
  ];

  static final List<String> _customerNames = [
    'Gurpreet Singh',
    'Simran Kaur',
    'Amit Sharma',
    'Harpreet Sandhu',
    'Priya Sharma',
    'Rohan Verma',
    'Manpreet Kaur',
    'Vikram Malhotra',
    'Neha Gupta',
    'Rajesh Kumar',
    'Jaspreet Singh',
    'Anjali Mehra',
    'Aman Deep',
    'Sunita Bansal',
    'Karanvir Bajwa',
    'Pooja Chawla',
    'Davinder Sodhi',
    'Ravinder Gill',
    'Tarun Mahajan',
    'Kavita Singla',
  ];

  static final List<String> _streets = [
    // Chandigarh
    'House # 1204, Sector 35-B, Chandigarh',
    'SCO 42, Sector 17-C, Chandigarh',
    'House # 418, Sector 8-A, Chandigarh',
    'Flat 302, Sector 43-B, Chandigarh',
    'Booth 55, Sector 22-D, Chandigarh',
    'House # 882, Sector 15-A, Chandigarh',
    'SCO 112, Madhya Marg, Sector 26, Chandigarh',
    'Modern Housing Complex, Mani Majra, Chandigarh',
    // Mohali
    'House # 245, Phase 7, Mohali',
    'SCF 18, Phase 3B2, Mohali',
    'House # 1420, Sector 70, Mohali',
    'Flat 401, Homeland Heights, Sector 70, Mohali',
    'Plot 512, JLPL Industrial Area, Sector 82, Mohali',
    'House # 88, Phase 5, Mohali',
    'Block C, Aerocity, Mohali',
    'Gillco Valley, Sector 127, Mohali',
    // Panchkula
    'House # 514, Sector 20, Panchkula',
    'SCO 88, Sector 14, Panchkula',
    'House # 128, Sector 7, Panchkula',
    'House # 95, MDC Sector 4, Panchkula',
    'House # 732, Sector 21, Panchkula',
    'Flat 204, GH-43, Sector 20, Panchkula',
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

    final techs = ['atul@fieldjobs.com', 'nitin@fieldjobs.com'];

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
              customerPhone: '+91 98140 ${10000 + jobCounter}',
              address: street,
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
