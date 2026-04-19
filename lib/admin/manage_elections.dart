import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/firestore_service.dart';
import '../models/election.dart';

class ManageElectionsPage extends StatefulWidget {
  const ManageElectionsPage({super.key});

  @override
  State<ManageElectionsPage> createState() => _ManageElectionsPageState();
}

class _ManageElectionsPageState extends State<ManageElectionsPage> {
  final _firestoreService = FirestoreService();


    final List<String> _constituencies = [
    'Bhavnagar city',
    'Talaja',
    'Gariadhar',
    'Sihor',
    'Ghogha',
    'Mahuva',
    'Palitana',
    'Jesar',
    'umrala',
    'Vallabhipur',
  ];

    final List<String> _states = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',

  // Union Territories
  'Andaman and Nicobar Islands',
  'Chandigarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Jammu and Kashmir',
  'Ladakh',
  'Lakshadweep',
  'Puducherry',
];

    final List<String> _gujaratDistricts = [
  'Ahmedabad',
  'Amreli',
  'Anand',
  'Aravalli',
  'Banaskantha',
  'Bharuch',
  'Bhavnagar',
  'Botad',
  'Chhota Udaipur',
  'Dahod',
  'Dang',
  'Devbhoomi Dwarka',
  'Gandhinagar',
  'Gir Somnath',
  'Jamnagar',
  'Junagadh',
  'Kheda',
  'Kutch',
  'Mahisagar',
  'Mehsana',
  'Morbi',
  'Narmada',
  'Navsari',
  'Panchmahal',
  'Patan',
  'Porbandar',
  'Rajkot',
  'Sabarkantha',
  'Surat',
  'Surendranagar',
  'Tapi',
  'Vadodara',
  'Valsad',
];

    final Map<String, Map<String, List<String>>> locationData = {
  
  'Andhra Pradesh':{},
  'Arunachal Pradesh':{},
  'Assam':{},
  'Bihar':{},
  'Chhattisgarh':{},
  'Goa':{},
  'Gujarat': {
    'Bhavnagar': [
      'Bhavnagar city',
      'Talaja',
      'Gariadhar',
      'Sihor',
      'Ghogha',
      'Mahuva',
      'Palitana',
      'Jesar',
      'Umrala',
      'Vallabhipur',
    ],
    'Ahmedabad': [],
    'Amreli':[],
    'Anand':[],
    'Aravalli':[],
    'Banaskantha':[],
    'Bharuch':[],
    'Botad':[],
    'Chhota Udaipur':[],
    'Dahod':[],
    'Dang':[],
    'Devbhoomi Dwarka':[],
    'Gandhinagar':[],
    'Gir Somnath':[],
    'Jamnagar':[],
    'Junagadh':[],
    'Kheda':[],
    'Kutch':[],
    'Mahisagar':[],
    'Mehsana':[],
    'Morbi':[],
    'Narmada':[],
    'Navsari':[],
    'Panchmahal':[],
    'Patan':[],
    'Porbandar':[],
    'Rajkot':[],
    'Sabarkantha':[],
    'Surat':[],
    'Surendranagar':[],
    'Tapi':[],
    'Vadodara':[],
    'Valsad':[],
  },
  'Haryana':{},
  'Himachal Pradesh':{},
  'Jharkhand':{},
  'Karnataka':{},
  'Kerala':{},
  'Madhya Pradesh':{},
  'Maharashtra':{},
  'Manipur':{},
  'Meghalaya':{},
  'Mizoram':{},
  'Nagaland':{},
  'Odisha':{},
  'Punjab':{},
  'Rajasthan':{},
  'Sikkim':{},
  'Tamil Nadu':{},
  'Telangana':{},
  'Tripura':{},
  'Uttar Pradesh':{},
  'Uttarakhand':{},
  'West Bengal':{},

  // Union Territories
  'Andaman and Nicobar Islands':{},
  'Chandigarh':{},
  'Dadra and Nagar Haveli and Daman and Diu':{},
  'Delhi':{},
  'Jammu and Kashmir':{},
  'Ladakh':{},
  'Lakshadweep':{},
  'Puducherry':{}
};


  @override
  void initState() {
    super.initState();
    debug();
  }


  void _showAddEditDialog([Election? election]) {


    debugPrint('\x1B[32m'
    'lib/admin/manage_elections.dart: _showAddEditDialog() executed'
    '\x1B[0m');

    final isEditing = election != null;
    final titleController = TextEditingController(text: election?.title ?? '');
    final descController = TextEditingController(text: election?.description ?? '');

    DateTime startDate = election?.startDate ?? DateTime.now().add(const Duration(days: 1));
    DateTime endDate = election?.endDate ?? DateTime.now().add(const Duration(days: 3));
    String status = election?.status ?? 'upcoming';

    String selectedElectionType = election?.type ?? 'general';
    String? selectedState;
    String? selectedDistrict;
    String? selectedConstituency;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Election' : 'Create Election'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),


                // 🔹 ROW 1 → State + District
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedState,
                        isExpanded: true, // ✅ IMPORTANT FIX
                        decoration: InputDecoration(
                          labelText: 'States',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _states.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c,overflow: TextOverflow.ellipsis,));
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedState = value;

                            // 🔴 reset dependent fields
                            selectedDistrict = null;
                            selectedConstituency = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedDistrict,
                        isExpanded: true, // ✅ IMPORTANT FIX
                        decoration: InputDecoration(
                          labelText: 'Districts',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: (locationData[selectedState] ?? {})
                          .keys
                          .map((district) {
                        return DropdownMenuItem(
                          value: district,
                          child: Text(district, overflow: TextOverflow.ellipsis),
                        );
                        }).toList(),
                        onChanged: (selectedState == null ||
                            (locationData[selectedState!] ?? {}).isEmpty)
                          ? null // 🔴 disables dropdown
                          : (value) {
                              setDialogState(() {
                                selectedDistrict = value;
                                selectedConstituency = null;
                            });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 🔹 ROW 2 → Constituency + Type
                Row(
                  children: [
                    Expanded(
                      child: 
                      DropdownButtonFormField<String>(
                      value: selectedConstituency,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Constituencies',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),

                      items: (locationData[selectedState]?[selectedDistrict] ?? [])
                          .map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),

                      onChanged: (selectedDistrict == null)
                          ? null
                          : (value) {
                              setDialogState(() {
                                selectedConstituency = value;
                              });
                            },
                    ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedElectionType,
                        isExpanded: true, // ✅ IMPORTANT FIX
                        decoration: InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'general', child: Text('General')),
                          DropdownMenuItem(value: 'local', child: Text('Local')),
                          DropdownMenuItem(value: 'state', child: Text('State')),
                          DropdownMenuItem(value: 'national', child: Text('National')),
                        ],
                        onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedElectionType = value);
                        }
                      },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date'),
                  subtitle: Text('${startDate.day}/${startDate.month}/${startDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End Date'),
                  subtitle: Text('${endDate.day}/${endDate.month}/${endDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => endDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: (value) => setDialogState(() => status = value!),
                ),

              ],
            ),
          ),

          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }


                if (selectedState == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a state')),
                  );
                  return;
                }

                if (selectedState == 'Gujarat') {
                  if (selectedDistrict == null || selectedConstituency == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a district and constituency')),
                    );
                    return;
                  }
                }




                Navigator.pop(context);

                final newElection = Election(
                  id: election?.id ?? '',
                  title: titleController.text,
                  description: descController.text,
                  type: selectedElectionType,
                  startDate: startDate,
                  endDate: endDate,
                  state: selectedState!,
                  district: selectedDistrict ?? '',
                  constituencies: election?.constituencies?.isNotEmpty == true ? election!.constituencies : [selectedConstituency!],                  status: status,
                  createdAt: election?.createdAt ?? DateTime.now(),
                );

                if (isEditing) {
                  await _firestoreService.updateElection(newElection);
                } else {
                  await _firestoreService.createElection(newElection);
                }


                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing
                        ? 'Election updated successfully'
                        : 'Election created successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteElection(Election election) async {
    debugPrint('\x1B[32m'
    'lib/admin/manage_elections.dart: _deleteElection() executed'
    '\x1B[0m');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Election'),
        content: Text('Are you sure you want to delete "${election.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.deleteElection(election.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Election deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Elections'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Election'),
      ),
      body: StreamBuilder<List<Election>>(
        stream: _firestoreService.getElectionsStream(), // ✅ use your existing method
        builder: (context, snapshot) {

          // 🔹 1. Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong'),
            );
          }

          // 🔹 2. No data state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.how_to_vote_outlined,
                    size: 80,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('No Elections', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  const Text('Create your first election',
                      style: AppTextStyles.body2),
                ],
              ),
            );
          }

          // 🔹 3. Data available
          final elections = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            itemCount: elections.length,
            itemBuilder: (context, index) {
              final election = elections[index];
              return _buildElectionCard(election);
            },
          );
        },
      ),
    );
  }

  Widget _buildElectionCard(Election election) {
    Color statusColor;
    switch (election.status) {
      case 'active':
        statusColor = AppColors.success;
        break;
      case 'completed':
        statusColor = AppColors.textSecondary;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        election.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        election.type.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        election.state.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),                   


                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        election.district.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        election.constituencies.isNotEmpty ? election.constituencies[0].toUpperCase() : 'ALL',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),

                    const Spacer(),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showAddEditDialog(election);
                        } else if (value == 'delete') {
                          _deleteElection(election);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(election.title, style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Text(
                  election.description,
                  style: AppTextStyles.body2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(election.startDate)} - ${_formatDate(election.endDate)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
 
  void debug() {
    debugPrint('\x1B[34m'
        'lib/admin/manage_elections.dart: executed'
        '\x1B[0m');
  }
}
