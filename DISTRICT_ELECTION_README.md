# 🏛️ DISTRICT-LEVEL ELECTION APP - COMPLETE GUIDE
## Gujarat Municipal Elections System

**Project Status:** District-Level Election App for Gujarat State (Single District)

**Target:** Municipal Corporation Elections (E-voting Platform)

---

## 📋 TABLE OF CONTENTS

1. [Project Overview](#project-overview)
2. [District-Level Election Overview](#district-level-election-overview)
3. [Election Code System](#election-code-system)
4. [Field-by-Field Analysis](#field-by-field-analysis)
5. [District Election Rules & Regulations](#district-election-rules--regulations)
6. [User & Admin Interface Standards](#user--admin-interface-standards)
7. [Complete Election Workflow](#complete-election-workflow)
8. [Field Checklist Summary](#field-checklist-summary)
9. [Compliance Checklist](#compliance-checklist)

---

## PROJECT OVERVIEW

### Current Architecture (National Level)
- Multi-state support
- Multi-district support
- Constituency-based voting
- Complex registration flow
- Biometric authentication

### Required Architecture (District Level)
- **Single State:** Gujarat (hardcoded)
- **Single District:** Configurable per deployment
- **Ward-based voting:** Not constituency-based
- **No Registration:** Login-only with existing voter database
- **Simplified Authentication:** OTP-based login

### Key Changes Needed
```
❌ REMOVE: Registration pages, state selection, district selection
✅ KEEP: Voting, blockchain integration, results dashboard
⭐ ADD: Party management, ward-based filtering, election scheduling
```

---

## DISTRICT-LEVEL ELECTION OVERVIEW

### What is a District-Level Election in India?

District-level elections in India are typically:
- **Municipal Corporation/Municipal Council Elections** (Local government)
- **District Panchayat Elections** (Rural local bodies)
- **Metropolitan Council Elections** (Urban areas)

### For Gujarat Specifically
- Comes under **Municipal Corporation Act, 1949** and **Gujarat Municipal Corporations Act, 1975**
- Conducted by **State Election Commission (SEC), Gujarat**
- Elections held every **5 years**
- **Ward-based voting system** (divide district into wards)
- **One vote per ward per citizen**
- **Single-day or multi-phase polling**

### Key Features of District Elections
```
Geographic Scope:
├─ Fixed to one district (e.g., Ahmedabad, Surat, Vadodara)
├─ Divided into wards (50-150 wards per district)
├─ Each ward elects one councillor
└─ Total wards vary by district size

Timeline:
├─ Notification to results: 60-90 days
├─ Multiple phases (Notification → Nomination → Polling → Results)
└─ Single polling day (usually)

Voters:
├─ Registered with State Election Commission
├─ Must be resident of ward (6+ months)
├─ Age 18+ years
└─ Indian citizens only

Candidates:
├─ Must be resident of ward (1+ year)
├─ Age 21+ years
├─ Must pass scrutiny by Election Commission
└─ Limited to one candidacy per election
```

---

## ELECTION CODE SYSTEM

### Election ID Generation & Format

Every election in the system is assigned a unique **Election Code (electionId)** that serves as the primary identifier across Firestore and Blockchain.

#### **Election Code Format:**

```
GUJ_[DISTRICT]_[TYPE]_[YEAR]
```

**Components:**

| Component | Description | Example | Notes |
|-----------|-------------|---------|-------|
| `GUJ` | State Code | GUJ | Fixed - Always "GUJ" for Gujarat |
| `[DISTRICT]` | District Code | AHM, SRT, VDR, RAJ, etc. | 3-4 letter abbreviation |
| `[TYPE]` | Election Type | MC, MB, ZP | MC=Municipal Corp, MB=Municipal Board, ZP=Zilla Parishad |
| `[YEAR]` | Election Year | 2026, 2027, 2031 | Full 4-digit year |

#### **Examples of Valid Election Codes:**

```
GUJ_AHM_MC_2026  → Ahmedabad Municipal Corporation Election 2026
GUJ_SRT_MC_2026  → Surat Municipal Corporation Election 2026
GUJ_VDR_MC_2026  → Vadodara Municipal Corporation Election 2026
GUJ_RAJ_MB_2026  → Rajkot Municipal Board Election 2026
GUJ_BRD_MC_2026  → Bharuch Municipal Corporation Election 2026
GUJ_AHM_MC_2031  → Ahmedabad Municipal Corporation Election 2031 (Next cycle)
```

#### **Gujarat District Codes (Complete List):**

```
STATE: GUJARAT (GUJ)

District Codes:
├─ AHM   → Ahmedabad
├─ AMR   → Amreli
├─ ANA   → Anand
├─ BAN   → Banaskantha
├─ BRD   → Bharuch
├─ BHV   → Bhavnagar
├─ BOT   → Botad
├─ CHA   → Chhota Udaipur
├─ DAH   → Dahod
├─ DEV   → Devi
├─ DNG   → Dang
├─ GAD   → Gad
├─ GAI   → Gaikwad
├─ GDH   → Gandhinagar
├─ GIR   → Girsomnath
├─ JAM   → Jamnagar
├─ JUN   → Junagadh
├─ KAC   → Kachchh
├─ KAI   → Kheda
├─ MEH   → Mehsana
├─ MOR   → Morbi
├─ NAR   → Narmada
├─ NAV   → Navsari
├─ PAN   → Panchmahal
├─ PAT   → Patan
├─ POR   → Porbandar
├─ RAJ   → Rajkot
├─ SAB   → Sabarkantha
├─ SAU   → Saurashtra
├─ SIM   → Simul
├─ SIR   → Sirpur
├─ SRT   → Surat
├─ TAP   → Tapi
├─ UDA   → Udaipur
├─ VAG   → Vadodara
├─ VAL   → Valsad
├─ VAN   → Vangli
└─ VDR   → Vododra
```

#### **Election Type Codes:**

```
MC   → Municipal Corporation (Large cities)
      Example: Ahmedabad, Surat, Vadodara, Rajkot
      
MB   → Municipal Board (Medium towns)
      Example: Anand, Mehsana, Palanpur
      
ZP   → Zilla Parishad (District-level)
      Example: District Panchayat Elections

TP   → Taluka Panchayat (Taluka-level)
      Example: Taluka Panchayat Elections

GP   → Gram Panchayat (Village-level)
      Example: Village Panchayat Elections
```

### Election Code Generation Logic

#### **In Firestore (Backend):**

```dart
// Firebase Cloud Function or Backend Service
String generateElectionCode(String district, String type, int year) {
  // Format: GUJ_[DISTRICT]_[TYPE]_[YEAR]
  String electionCode = "GUJ_${district.toUpperCase()}_${type.toUpperCase()}_$year";
  
  // Validate format
  if (!RegExp(r'^GUJ_[A-Z]{3,4}_[A-Z]{2,3}_\d{4}$').hasMatch(electionCode)) {
    throw Exception('Invalid election code format');
  }
  
  return electionCode;
}

// Example usage
String electionId = generateElectionCode('AHM', 'MC', 2026);
// Result: GUJ_AHM_MC_2026
```

#### **In Flutter (Frontend):**

```dart
// lib/services/firestore_service.dart
Future<void> createElection(Election election) async {
  // Generate election ID automatically
  final String district = 'AHM'; // From user selection
  final String type = 'MC';      // From dropdown
  final int year = DateTime.now().year + 1; // Or user selection
  
  // Generate code
  final electionId = generateElectionCode(district, type, year);
  
  // Create election
  final newElection = Election(
    id: electionId,  // Use generated code as ID
    title: election.title,
    // ... other fields
  );
  
  // Save to Firestore
  await _db.collection('elections').doc(electionId).set(newElection.toMap());
  
  // Deploy on blockchain with same ID
  await _blockchainService.createElectionOnBlockchain(electionId);
}
```

### Election Code Usage in Different Modules

#### **1. Admin Dashboard**

```
Create Election → Generate Code (GUJ_AHM_MC_2026)
                    ↓
            Display in UI
                    ↓
            Save to Database
                    ↓
            Link to Blockchain Contract
```

#### **2. Candidate Management**

```
Add Candidate → Select Election (GUJ_AHM_MC_2026)
                    ↓
            Assign to Candidates Collection
                    ↓
            Link in Database
                    ↓
            Display in Voting Page
```

#### **3. Voter Module**

```
User Login → Fetch Active Elections (electionId = GUJ_AHM_MC_2026)
                    ↓
            Load Candidates for Ward
                    ↓
            User Selects Candidate
                    ↓
            Record Vote with electionId
                    ↓
            Blockchain Transaction
```

#### **4. Results Module**

```
Election Completed → Query by electionId (GUJ_AHM_MC_2026)
                    ↓
            Count Votes from Blockchain
                    ↓
            Display Results per Candidate
                    ↓
            Verify on Blockchain
```

### Election Code Storage & Retrieval

#### **Firestore Collection Structure:**

```firestore
├── elections/
│   ├── GUJ_AHM_MC_2026/          ← Use election code as document ID
│   │   ├─ electionId: "GUJ_AHM_MC_2026"
│   │   ├─ title: "Ahmedabad Municipal Corporation Election 2026"
│   │   ├─ status: "active"
│   │   ├─ pollingDate: 2026-02-15
│   │   ├─ totalWards: 130
│   │   └─ contractAddress: "0x..."
│   │
│   ├── GUJ_SRT_MC_2026/          ← Another election
│   │   ├─ electionId: "GUJ_SRT_MC_2026"
│   │   ├─ title: "Surat Municipal Corporation Election 2026"
│   │   └─ ...
│   │
│   └── GUJ_AHM_MC_2031/          ← Next election cycle
│       ├─ electionId: "GUJ_AHM_MC_2031"
│       └─ ...

├── candidates/
│   ├── CND001/
│   │   ├─ name: "Rajesh Patel"
│   │   ├─ electionId: "GUJ_AHM_MC_2026"  ← Links to election
│   │   ├─ ward: "Ward 1"
│   │   └─ party: "BJP"
│   │
│   ├── CND002/
│   │   ├─ name: "Priya Sharma"
│   │   ├─ electionId: "GUJ_AHM_MC_2026"  ← Same election
│   │   └─ ...

├── votes/
│   ├── VOT001/
│   │   ├─ voterUid: "voter_123"
│   │   ├─ electionId: "GUJ_AHM_MC_2026"  ← Links to election
│   │   ├─ candidateId: "CND001"
│   │   ├─ timestamp: 2026-02-15T10:30:00Z
│   │   └─ transactionHash: "0x..."

└── audit_logs/
    ├── LOG001/
    │   ├─ action: "CREATE_ELECTION"
    │   ├─ resourceId: "GUJ_AHM_MC_2026"  ← Reference to election
    │   ├─ timestamp: 2026-01-01T08:00:00Z
    │   └─ adminId: "admin_001"
```

#### **Query Examples:**

```dart
// Get all candidates for an election
Future<List<Candidate>> getCandidatesForElection(String electionId) async {
  // Example: electionId = "GUJ_AHM_MC_2026"
  final snapshot = await _db
      .collection('candidates')
      .where('electionId', isEqualTo: electionId)
      .get();
  
  return snapshot.docs.map((doc) => Candidate.fromFirestore(doc)).toList();
}

// Get all votes for an election
Future<List<Vote>> getVotesForElection(String electionId) async {
  final snapshot = await _db
      .collection('votes')
      .where('electionId', isEqualTo: electionId)
      .get();
  
  return snapshot.docs.map((doc) => Vote.fromFirestore(doc)).toList();
}

// Get election by code
Future<Election?> getElectionByCode(String electionCode) async {
  // Example: electionCode = "GUJ_AHM_MC_2026"
  final doc = await _db.collection('elections').doc(electionCode).get();
  
  if (doc.exists) {
    return Election.fromFirestore(doc);
  }
  return null;
}
```

### Election Code & Blockchain Integration

#### **Smart Contract Mapping:**

```solidity
// EVoting.sol
mapping(string => Election) public elections;
// Key: "GUJ_AHM_MC_2026" → Election struct

mapping(string => bool) public electionActive;
// Key: "GUJ_AHM_MC_2026" → true/false

mapping(string => uint256) public totalVotes;
// Key: "GUJ_AHM_MC_2026" → Vote count
```

#### **Blockchain Transaction Example:**

```dart
// When voter casts vote
Future<BlockchainTransaction?> castVoteOnBlockchain(
  String electionId,  // "GUJ_AHM_MC_2026"
  String voterHash,
  String candidateHash,
) async {
  
  final function = contract!.function("castVote");
  
  final receipt = await client.sendTransaction(
    credentials,
    Transaction.callContract(
      contract: contract!,
      function: function,
      parameters: [
        electionId,          // "GUJ_AHM_MC_2026" passed to blockchain
        voterHash,
        candidateHash,
      ],
    ),
  );
  
  // Transaction recorded with electionId as reference
  return BlockchainTransaction(
    transactionHash: receipt.hash,
    blockHash: receipt.blockHash,
    blockNumber: receipt.blockNumber,
    from: senderAddress.hex,
    to: contractAddress,
    data: 'castVote($electionId)',
    timestamp: DateTime.now(),
    status: receipt.status ?? false,
  );
}
```

### Election Code Validation

#### **Validation Rules:**

```dart
// lib/utils/validators.dart
class ElectionCodeValidator {
  static bool isValidElectionCode(String code) {
    // Format: GUJ_[DISTRICT]_[TYPE]_[YEAR]
    // Example: GUJ_AHM_MC_2026
    
    final pattern = RegExp(r'^GUJ_[A-Z]{3,4}_[A-Z]{2,3}_\d{4}$');
    return pattern.hasMatch(code);
  }
  
  static String? validateElectionCode(String? code) {
    if (code == null || code.isEmpty) {
      return 'Election code is required';
    }
    
    if (!isValidElectionCode(code)) {
      return 'Invalid election code format (e.g., GUJ_AHM_MC_2026)';
    }
    
    return null;  // Valid
  }
  
  static String getElectionYear(String electionCode) {
    // Extract year from code
    // GUJ_AHM_MC_2026 → 2026
    final parts = electionCode.split('_');
    return parts.length > 3 ? parts[3] : '';
  }
  
  static String getDistrict(String electionCode) {
    // Extract district from code
    // GUJ_AHM_MC_2026 → AHM
    final parts = electionCode.split('_');
    return parts.length > 1 ? parts[1] : '';
  }
  
  static String getType(String electionCode) {
    // Extract type from code
    // GUJ_AHM_MC_2026 → MC
    final parts = electionCode.split('_');
    return parts.length > 2 ? parts[2] : '';
  }
}
```

### Election Code Examples by District

#### **Ahmedabad (AHM):**
```
GUJ_AHM_MC_2026  → Ahmedabad Municipal Corporation Election 2026
GUJ_AHM_MC_2031  → Ahmedabad Municipal Corporation Election 2031
GUJ_AHM_MC_2036  → Ahmedabad Municipal Corporation Election 2036
```

#### **Surat (SRT):**
```
GUJ_SRT_MC_2026  → Surat Municipal Corporation Election 2026
GUJ_SRT_MC_2031  → Surat Municipal Corporation Election 2031
```

#### **Vadodara (VDR):**
```
GUJ_VDR_MC_2026  → Vadodara Municipal Corporation Election 2026
GUJ_VDR_MB_2026  → Vadodara Municipal Board Election 2026
```

#### **Rajkot (RAJ):**
```
GUJ_RAJ_MC_2026  → Rajkot Municipal Corporation Election 2026
GUJ_RAJ_MC_2031  → Rajkot Municipal Corporation Election 2031
```

---



### A. MANAGE ELECTIONS PAGE

#### **Unnecessary Fields (REMOVE ❌)**

| Field | Why Unnecessary |
|-------|-----------------|
| `type` | Always "Municipal Election" |
| `state` | Fixed to "Gujarat" |
| `district` | Fixed (configured at deployment) |
| `constituencies` | Use wards instead |

#### **Fields to KEEP ✅**

| Field | Type | Requirements | Example |
|-------|------|--------------|---------|
| `electionId` | String | Unique, auto-generated | `GUJ_AHM_MC_2026` |
| `electionName` | String | Full official name | "Ahmedabad Municipal Corporation Election 2026" |
| `electionType` | String | Fixed (dropdown) | "Municipal Corporation" |
| `description` | TextArea | Election purpose | "Municipal election for ward commissioners" |
| `totalWards` | Integer | Number of wards | `100`, `50`, etc. |
| `notificationDate` | DateTime | Official notification date | Election Commission announcement |
| `nominationStartDate` | DateTime | Candidate nomination begins | Required by Election Commission |
| `nominationEndDate` | DateTime | Last date for nominations | Required by Election Commission |
| `scrutinyDate` | DateTime | Document verification date | After nomination closes |
| `withdrawalDate` | DateTime | Last date to withdraw | Before campaigning |
| `campaignStartDate` | DateTime | Election campaign begins | 2-3 weeks before polling |
| `campaignEndDate` | DateTime | Campaign ends (48 hrs before) | 2 days before polling |
| `pollingDate` | DateTime | Voting day | Single day or multi-phase |
| `resultDate` | DateTime | Results announced | 2-3 days after polling |
| `status` | String | Current state | "Notification" → "Nomination" → "Active" → "Completed" |
| `contractAddress` | String | Blockchain contract | For vote recording |
| `createdAt` | DateTime | Creation timestamp | Auto-generated |
| `createdBy` | String | Admin who created | Admin UID |

#### **NEW Fields to ADD (For Compliance) ⭐**

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `electionCommissionNotification` | String | Official SEC notice | "Notification No. XYZ dated..." |
| `reservedSeats` | Object | Reserved ward details | `{SC: 15, ST: 5, OBC: 20}` |
| `womenReservation` | Integer | % of women-reserved wards | `33%` (1/3 of total) |
| `totalElectors` | Integer | Registered voters | `5,000,000` |
| `estimatedTurnout` | Integer | Expected voter turnout % | `60%` |
| `conductingAuthority` | String | Authority conducting | "State Election Commission" |
| `municipalityType` | String | Type of municipality | "Municipal Corporation" / "Municipal Council" |

#### **Election Status Workflow ⚡**

```
NOTIFIED 
  ↓ (Notification date)
NOMINATION OPEN
  ↓ (Nomination end date)
SCRUTINY
  ↓ (After scrutiny, invalid forms removed)
WITHDRAWAL OPEN
  ↓ (Candidates can withdraw)
CAMPAIGN ACTIVE
  ↓ (Campaign 2-3 weeks)
POLLING
  ↓ (Voting day - critical phase)
COUNTING
  ↓ (Results being counted)
COMPLETED
  └─ Final results announced
```

---

### B. MANAGE CANDIDATES PAGE

#### **Unnecessary Fields (REMOVE ❌)**

| Field | Why Unnecessary |
|-------|-----------------|
| `symbol` | Use party color instead |
| `constituency` | Use ward instead |
| `manifesto` | Limited space, optional |

#### **Fields to KEEP ✅**

| Field | Type | Requirements | Example |
|-------|------|--------------|---------|
| `candidateId` | String | Unique identifier | `CND_GUJ_AHM_001` |
| `candidateName` | String | Full legal name | "Rajesh Kumar Patel" |
| `dateOfBirth` | DateTime | Age verification (min 21) | "1985-05-15" |
| `gender` | String | Dropdown | "Male" / "Female" / "Other" |
| `qualification` | String | Educational qualification | "Graduate" / "Post-Graduate" / "10th Pass" |
| `partyId` | String | Reference to party | FK to Party table |
| `partySymbol` | String | Party symbol code | "BJP", "CONGRESS", "IND" |
| `ward` | String | Ward number | "Ward 1", "Ward 25" |
| `electionId` | String | Election reference | FK to Election |
| `phone` | String | Contact number | "+91XXXXXXXXXX" |
| `email` | String | Email address | "candidate@example.com" |
| `address` | String | Residential address | For verification |
| `photo` | String | Photo URL | For ballot display |
| `voteCount` | Integer | Current votes | Live updated |
| `nominationFormStatus` | String | Form status | "Submitted" / "Accepted" / "Rejected" |
| `status` | String | Candidate status | "Active" / "Withdrawn" / "Disqualified" |
| `createdDate` | DateTime | Nomination date | When form submitted |

#### **NEW Fields to ADD (Regulatory Compliance) ⭐**

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `aadharNumber` | String (encrypted) | ID verification | Last 4 digits visible |
| `panNumber` | String (encrypted) | Tax ID verification | For financial check |
| `criminalRecord` | Boolean | Affidavit: Any criminal record | Yes/No |
| `criminalDetails` | String | If yes, details | "FIR in theft case 2020" |
| `assetValue` | String | Total assets declared | "₹50 lakhs" |
| `educationCertificate` | String (URL) | Education proof doc | PDF link |
| `nominationFormDocument` | String (URL) | Official form | PDF link |
| `nomineeStatus` | String | After scrutiny | "Eligible" / "Ineligible" |
| `nominationNumber` | String | Form number from SEC | "NOM/AHM/2026/001" |
| `nomineeAffidavit` | String (URL) | Signed affidavit | PDF link |
| `photoFIR` | String (URL) | Photo with FIR details | Image URL |
| `withdrawalDate` | DateTime | If withdrawn | Timestamp |
| `disqualificationReason` | String | If disqualified | Reason text |
| `ballotSymbol` | String | Official ballot symbol | Given by Election Commission |
| `ballotPosition` | Integer | Position on ballot | 1, 2, 3, etc. |

---

### C. MANAGE PARTIES PAGE (NEW)

#### **Fields to INCLUDE ✅**

| Field | Type | Requirements | Example |
|-------|------|--------------|---------|
| `partyId` | String | Unique identifier | `PTY_BJP`, `PTY_CONGRESS` |
| `partyName` | String | Official party name | "Bharatiya Janata Party" |
| `partyShortCode` | String | 3-4 letter code | "BJP", "INC", "AAP" |
| `partyColor` | String | Primary color | "#FF9933" (Orange for BJP) |
| `partySymbol` | String | Election symbol code | Given by Election Commission |
| `partyLogo` | String (URL) | Logo image | SVG/PNG URL |
| `partyDescription` | String | Party ideology | Brief description |
| `registrationNumber` | String | SEC registration | "PROP/2023/001" |
| `isNationalParty` | Boolean | National vs State party | True/False |
| `isStateParty` | Boolean | State-level recognition | True/False |
| `isRecognizedParty` | Boolean | Official recognition | True/False |
| `totalCandidates` | Integer | Candidates fielded | Live counter |
| `totalVotes` | Integer | Total votes received | Live counter |
| `votePercentage` | Decimal | Vote share % | Live calculated |
| `createdDate` | DateTime | When added to system | Auto-generated |
| `updatedDate` | DateTime | Last update | Auto-generated |
| `status` | String | Active/Inactive | "Active" / "Inactive" |

#### **Optional Advanced Fields ⭐**

| Field | Type | Purpose |
|-------|------|---------|
| `partyPresident` | String | Party leader name |
| `partyWebsite` | String (URL) | Official website |
| `partyContact` | String | Contact number |
| `partyHeadquarters` | String | Main office address |
| `foundedYear` | Integer | When party established |
| `partyIdeology` | String | Political ideology |

---

### D. MANAGE VOTERS PAGE

#### **Unnecessary Fields (REMOVE ❌)**

| Field | Why Unnecessary |
|-------|-----------------|
| `state` | Fixed to "Gujarat" |
| `district` | Fixed (specific district) |
| `address` | Not critical for voting |

#### **Fields to KEEP ✅**

| Field | Type | Requirements | Example |
|-------|------|--------------|---------|
| `voterId` | String | Unique voter ID | "voter_uid_12345" |
| `voterName` | String | Full legal name | "Priya Sharma" |
| `dateOfBirth` | DateTime | Must be 18+ | "1995-03-20" |
| `gender` | String | Dropdown | "Female" / "Male" / "Other" |
| `email` | String | Contact email | "voter@example.com" |
| `phone` | String | Mobile number (verified) | "+91XXXXXXXXXX" |
| `ward` | String | Ward number assigned | "Ward 15" |
| `voterIdNumber` | String | Government voter ID | From election roll |
| `status` | String | Voter status | "Active" / "Inactive" / "Blocked" |
| `isEligible` | Boolean | Eligibility flag | True/False |
| `hasVoted` | Boolean | Voting status (per election) | True/False |
| `votingTimestamp` | DateTime | When voter voted | Timestamp |
| `registeredDate` | DateTime | Registration date | Auto-generated |
| `lastUpdated` | DateTime | Profile update date | Auto-generated |

#### **NEW Fields to ADD (For Compliance) ⭐**

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `aadharNumber` | String (encrypted) | Government ID | Last 4 digits only |
| `pancardNumber` | String (encrypted) | ID verification | Optional |
| `voterSlipNumber` | String | Voter roll number | From election database |
| `constituencyType` | String | Type of voter | "General" / "OBC" / "SC" / "ST" |
| `electionCommissionRollNumber` | String | Official roll number | "Roll/AHM/2026/00001" |
| `verificationStatus` | String | Voter verification | "Verified" / "Pending" / "Rejected" |
| `verificationDate` | DateTime | When verified | Timestamp |
| `verifiedBy` | String | Admin who verified | Admin UID |
| `aadharVerified` | Boolean | Aadhar link verified | True/False |
| `mobileVerified` | Boolean | Phone OTP verified | True/False |
| `emailVerified` | Boolean | Email verified | True/False |
| `isResident` | Boolean | Residency proof | True/False |
| `residencyProof` | String (URL) | Document link | Utility bill/lease/property deed |
| `blockedReason` | String | If blocked, why | "Disqualified" / "Duplicate" / "Fraud" |
| `blockedDate` | DateTime | When blocked | Timestamp |
| `blockedBy` | String | Admin who blocked | Admin UID |

---

## DISTRICT ELECTION RULES & REGULATIONS

### A. ELIGIBILITY CRITERIA

#### **For Voters (As per Indian Constitution)**

```
✅ ELIGIBLE TO VOTE:
├─ Indian citizen
├─ Age: 18 years or above (as of polling date)
├─ Resident of the ward for minimum 6 months
└─ Not disqualified by law

❌ NOT ELIGIBLE TO VOTE:
├─ Non-citizens or persons with any foreign nationality
├─ Age below 18 years
├─ Person of unsound mind
├─ Convicted of crime within last 5 years (varies by crime)
├─ Disqualified under Representation of People Act
└─ Residing outside ward for more than 6 months
```

#### **For Candidates**

```
✅ ELIGIBLE TO CONTEST:
├─ Indian citizen
├─ Age: Minimum 21 years (as of nomination day)
├─ Resident of the ward (at least 1 year before nomination)
├─ Possess required qualifications (if any)
├─ Not disqualified by law
├─ Filed proper nomination form
└─ Cleared scrutiny by Election Commission

❌ NOT ELIGIBLE TO CONTEST:
├─ Age below 21 years
├─ Non-resident of ward
├─ Disqualified under Representation of People Act
├─ No Aadhar/valid ID
├─ Criminal conviction within last 5 years
├─ Corrupt practices conviction
├─ Default in local taxes/rent
└─ Mental illness certified
```

---

### B. ELECTORAL PROCESS TIMELINE

```
MONTH -4 to -3: PLANNING & NOTIFICATION
├─ Election Commission decides election date
├─ Issues public notification
├─ Appoints election officials
└─ Voter roll finalized

MONTH -2: NOMINATION PERIOD (Usually 10 days)
├─ Candidates file nomination forms
├─ With required documents:
│  ├─ ID proof (Aadhar/PAN)
│  ├─ Address proof
│  ├─ Education certificate
│  ├─ Affidavit about assets
│  ├─ Criminal record affidavit
│  ├─ 10 voter nominations (support)
│  └─ Nomination fee (refundable if 1/6th votes)
├─ SC/ST candidates: Fee concession available
└─ Total candidates selected by SEC

MONTH -2: SCRUTINY (2-3 days after nomination ends)
├─ Election Commission examines forms
├─ Verifies:
│  ├─ Completeness of documents
│  ├─ Eligibility of candidate
│  ├─ Voter support (10 valid signatures)
│  └─ Affidavit accuracy
├─ DECISION: Eligible / Ineligible
└─ Ineligible candidates informed

MONTH -2: WITHDRAWAL PERIOD (2-5 days)
├─ Candidates can withdraw nominations
├─ After scrutiny results
├─ Final candidate list published
└─ Ballot positions assigned

MONTH -1: CAMPAIGN PERIOD (2-3 weeks)
├─ Election campaign by candidates
├─ Rules:
│  ├─ No communal speeches
│  ├─ No bribery/inducements
│  ├─ Voter education campaigns
│  ├─ 48 hours SILENT PERIOD before polls
│  └─ Campaign expenses limit: ₹10-15 lakhs per candidate
├─ Media monitoring
└─ Complaints addressed

ELECTION DAY: POLLING
├─ Voting at designated polling stations
├─ Hours: 8 AM to 5 PM (usually)
├─ Voter identification required
├─ Indelible mark on finger
├─ EVM/Electronic voting
└─ Security seals for machines

ELECTION DAY+2-3: COUNTING & RESULTS
├─ Votes counted at counting centers
├─ Candidate with most votes WINS
├─ Results published by Election Commission
├─ Official gazette notification
└─ Winner takes oath

POST-ELECTION: OBJECTION PERIOD
├─ 30 days to file petition
├─ Election Commission review
├─ If petition upheld: Election cancelled
└─ New election announced
```

---

### C. CANDIDATE NOMINATION RULES

#### **Valid Nomination Requirements:**

```
1. FORM SUBMISSION:
   ├─ Name & Details (as per ID proof)
   ├─ Age proof (>21 years)
   ├─ Residential proof (Ward resident for 1 year)
   └─ Declaration of assets & liabilities

2. DOCUMENT REQUIREMENTS:
   ├─ Aadhar Card (must have)
   ├─ PAN Card (optional but recommended)
   ├─ Education proof
   ├─ Residential address proof:
   │  ├─ Electricity bill (3 months old)
   │  ├─ Property tax receipt
   │  ├─ Rental agreement
   │  └─ Voter ID of residence
   ├─ Criminal history affidavit (self-declaration)
   ├─ Asset declaration form
   ├─ Photograph (4x6 cm)
   ├─ Voter ID copy
   └─ PAN card copy

3. SUPPORTING DOCUMENTS:
   ├─ 10 voter nominations (voter signatures + ID):
   │  ├─ Voters must be from same ward
   │  ├─ One voter = maximum 2 nominations
   │  └─ Signatures must be different person
   ├─ Affidavit on oath (notarized)
   └─ Form signed by candidate & two witnesses

4. NOMINATION FEES:
   ├─ General candidates: ₹500-1000
   ├─ SC/ST candidates: ₹250-500 (concession)
   ├─ Fee refunded if:
   │  ├─ Less than 1/6th of votes received
   │  └─ Nomination rejected
   └─ Non-refundable if:
       ├─ Withdrew after scrutiny
       └─ Contested & votes ≥ 1/6th
```

#### **Scrutiny Process (Election Commission checks):**

```
DOCUMENT CHECK:
├─ Is candidate Indian citizen? ✓
├─ Is age ≥ 21 years? ✓
├─ Is residential proof valid? ✓
├─ Are 10 voter signatures valid? ✓
├─ Are they from same ward? ✓
├─ Is affidavit complete? ✓
└─ Is photo & ID clear? ✓

ELIGIBILITY CHECK:
├─ Any criminal conviction? ✓
├─ Any case pending? ✓
├─ Default in taxes? ✓
├─ Disqualification under law? ✓
└─ Bankruptcy/debt status? ✓

DECISION:
├─ ACCEPTED ✅ (Eligible to contest)
├─ REJECTED ❌ (Can appeal within 3 days)
└─ ACCEPTED SUBJECT TO OBJECTION (After objection period)
```

---

### D. VOTING RULES & REGULATIONS

#### **Voter Eligibility at Polling Station:**

```
VERIFICATION AT POLLING BOOTH:
├─ Voter ID number checked in electoral roll
├─ Cross-verified with voter database
├─ Photo ID verified (Aadhar/Voter slip)
├─ Check: NOT already voted in this election
├─ Check: Ward matches
├─ Signature/thumb impression taken
└─ Indelible ink mark on finger

VOTING METHOD:
├─ Electronic Voting Machine (EVM)
├─ ONE VOTE PER VOTER
├─ One vote per election
├─ Secret ballot (vote secrecy maintained)
├─ Cannot show/prove how you voted
└─ Ballot paper (if EVM fails):
    ├─ Voter marks candidate of choice
    └─ Seal in envelope at polling station

DURING POLLING:
├─ Polling time: 8 AM to 5 PM (typical)
├─ Single-day voting (usually)
├─ Multi-phase if large district
├─ Armed forces voting on separate day
└─ Postal votes for elderly/disabled
```

#### **Vote-Once Enforcement:**

```
DATABASE CHECK (Online in real-time):
├─ After voter identified:
├─ Query: SELECT votes WHERE voter_id = X AND election_id = Y
├─ If result found:
│  └─ DENY VOTING (already voted)
├─ If no result:
│  └─ ALLOW VOTING
└─ After vote cast:
   └─ INSERT into votes table
   └─ Mark voter as "voted"
   └─ Record timestamp
   └─ Record blockchain hash
```

---

### E. RESULT DECLARATION PROCESS

#### **Vote Counting Rules:**

```
SECURITY MEASURES:
├─ Counting centers designated before election
├─ Armed forces deployed
├─ Observer from election commission present
├─ Candidate representatives allowed
├─ Media observation allowed
├─ Sealed EVM brought to counting center
├─ Security seals verified
└─ Tamper evident locks checked

COUNTING PROCESS:
├─ Count from EVM (or ballot papers)
├─ For each candidate:
│  ├─ Read vote count from EVM
│  ├─ Record in official form (Form 20)
│  ├─ Verify with observer witnesses
│  └─ Announce to candidates' representatives
├─ Parallel counting for verification
├─ Cross-check before declaring
└─ Results transcribed to electronic form

RESULT DECLARATION:
├─ Highest votes = WINNER
├─ Tie vote → Re-voting in that ward
├─ Candidate with most votes declared elected
├─ Results officially published
├─ Certificate given to winner
└─ Gazette notification issued
```

---

### F. WARD-BASED ELECTION RULES

#### **Ward System (For District Elections):**

```
WARD DEFINITION:
├─ District divided into wards (typically 50-150 per district)
├─ Each ward = geographic area with population ~40-50k
├─ One ward councillor elected per ward
├─ Mayor/President elected from all councilors
└─ Example: Ahmedabad has ~130 wards

CANDIDATE ELIGIBILITY BY WARD:
├─ Candidate must be RESIDENT of ward
├─ OR Own property in ward
├─ 1-year residency requirement
├─ OR 1-year property ownership
└─ Proof required (utility bill / property tax / lease)

RESERVED WARDS (Social Justice):
├─ 1/3 of wards reserved for WOMEN
│  └─ Only women candidates can contest
├─ SC (Scheduled Caste) wards (typically 10-15%)
│  └─ Only SC candidates can contest
├─ ST (Scheduled Tribe) wards (where applicable)
│  └─ Only ST candidates can contest
├─ OBC wards (if applicable in state)
└─ Rotation of reserved seats every election

GENERAL WARDS:
├─ Anyone (Man/Woman) can contest
├─ Open for all candidates
└─ No caste/gender restriction
```

---

## USER & ADMIN INTERFACE STANDARDS

### A. USER INTERFACE STANDARDS

#### **LOGIN PAGE**

```
Fields:
├─ Voter ID [Text Input] - Required
│  └─ Placeholder: "Enter your Voter ID"
├─ Password [Password Input] - Required
│  └─ Show/Hide toggle
└─ [REMEMBER ME] Checkbox - Optional

Actions:
├─ [LOGIN] Button - Primary action
├─ [FORGOT PASSWORD?] Link
│  └─ Password reset via email
└─ Display:
   └─ "This is a secure system"

Validations:
├─ Voter ID: Must exist in database
├─ Password: Minimum 8 chars (as set during registration)
├─ Must show appropriate error messages
│  ├─ "Voter ID not found"
│  └─ "Incorrect password"
```

#### **OTP VERIFICATION PAGE**

```
Display:
├─ Message: "OTP sent to registered mobile: +91XXXXXX789"
├─ OTP field [6-digit input]
├─ Timer: "Expires in 2:00 minutes"
└─ "Didn't receive OTP? [RESEND]"

Validations:
├─ OTP: 6 digits
├─ Time limit: 2 minutes
├─ Max 3 attempts
├─ Block voter after 3 failed attempts for 30 mins
└─ Resend OTP: After 30 seconds

Actions:
├─ [VERIFY & LOGIN] Button
└─ [BACK] to try different ID
```

#### **HOME/DASHBOARD PAGE**

```
Display (Top Section):
├─ Welcome message: "Welcome, [Voter Name]"
├─ Voter ID: [Read-only display]
├─ Ward: "Ward 25"
└─ Current election status

Election Card (Center Section):
├─ Election Title: "Ahmedabad Municipal Corporation Election 2026"
├─ Dates: "Polling Date: 15 February 2026"
├─ Status Badge:
│  ├─ 🔴 "Upcoming" (before polling)
│  ├─ 🟢 "VOTING ACTIVE" (on polling day)
│  ├─ 🟡 "Counting in progress" (after polling)
│  └─ ✅ "Completed" (after results)
├─ Your Voting Status:
│  ├─ ⏳ "Not voted yet"
│  ├─ ✅ "You have voted"
│  └─ 🔒 "Election closed"
├─ Current Time (for polling day)
│  └─ Polling ends in: "2 hours 45 minutes"
└─ Actions:
    ├─ [VOTE NOW] Button (if eligible & polling active)
    ├─ [VIEW RESULTS] (if results declared)
    └─ [CANDIDATE INFO] (view all candidates)

Bottom Section:
├─ [YOUR PROFILE]
├─ [VOTING HISTORY]
├─ [HELP & SUPPORT]
└─ [LOGOUT]
```

#### **VOTING PAGE**

```
Display:
├─ Election Title
├─ Ward: "You are voting for Ward 25"
├─ Message: "Choose ONE candidate"
├─ Confirmation required: "Are you sure?"

Candidate List (for ward):
├─ For each candidate (sorted by ballot number):
│  ├─ [Ballot Number] [Photo] [Name]
│  ├─ Party: [Color Badge] [Party Name]
│  ├─ [SELECT BUTTON]
│  └─ If selected:
│     └─ ✅ "Selected" (show checkmark)

Validation:
├─ Must select ONE candidate
├─ Cannot select multiple
├─ Cannot submit without selection
└─ [CONFIRM VOTE] Button (only if selected)

Rules Display:
├─ ℹ️ "Your vote is secret and secure"
├─ ℹ️ "This is recorded on blockchain"
├─ ℹ️ "You can change selection before confirming"
├─ ⚠️ "Once submitted, your vote is PERMANENT"
└─ [CANCEL] button to go back
```

#### **CONFIRMATION PAGE**

```
Display (Success State):
├─ ✅ Large success checkmark
├─ "YOUR VOTE HAS BEEN RECORDED"
├─ Vote Details:
│  ├─ Candidate Name: [Voted candidate]
│  ├─ Party: [Party name with color]
│  ├─ Election: [Election name]
│  ├─ Time Voted: [Timestamp]
│  ├─ Date: [Full date]
│  └─ Blockchain Proof:
│     └─ Transaction Hash: [0x...] (clickable, shows details)
├─ QR Code: Scan to verify vote (links to blockchain explorer)
└─ Message:
   └─ "This vote is permanent and cannot be changed"

Actions:
├─ [BACK TO HOME] Button
├─ [VIEW RESULTS] (if results already out)
└─ [DOWNLOAD RECEIPT] (PDF with details + QR)
```

#### **HISTORY PAGE**

```
Display:
├─ Title: "Your Voting History"
├─ Information:
│  └─ "Shows all elections you have voted in"

For each election voted:
├─ Election Name
├─ Ward
├─ Date Voted: [Date and time]
├─ Candidate Name: [Candidate voted for]
├─ Party: [Party color badge]
├─ Status: [✅ Confirmed, 🔒 Vote Hidden (after results)]
├─ Transaction Hash: [Clickable link to blockchain]
└─ [VIEW DETAILS] (shows blockchain confirmation)

Note:
├─ ℹ️ "Your vote is secret - others cannot see it"
├─ ℹ️ "Blockchain ensures vote cannot be changed"
└─ Only you can view your own voting history
```

#### **PROFILE PAGE (Read-Only)**

```
Display:
├─ Title: "Voter Profile"
├─ Photo: [Avatar or profile image]
├─ Name: [Read-only]
├─ Voter ID: [Read-only, copyable]
├─ Date of Birth: [Read-only]
├─ Gender: [Read-only]
├─ Ward: [Read-only]
├─ Email: [Read-only]
├─ Phone: [Read-only, last 4 digits masked]
├─ Status: "✅ Active" or "❌ Inactive"
└─ Actions:
   ├─ [CHANGE PASSWORD] (opens modal)
   └─ [REPORT ISSUE] (contact support)

Edit Password Modal:
├─ Old Password [Required]
├─ New Password [Required, min 8 chars]
├─ Confirm Password [Required]
└─ [UPDATE] [CANCEL]
```

---

### B. ADMIN INTERFACE STANDARDS

#### **ADMIN LOGIN PAGE**

```
Fields:
├─ Admin ID [Text Input]
│  └─ Placeholder: "Admin email or ID"
├─ Password [Password Input]
│  └─ Show/Hide toggle
├─ [REMEMBER ME] Checkbox
└─ [LOGIN] Button

Validations:
├─ Admin ID: Must exist and have admin role
├─ Password: Correct password required
├─ Show error: "Invalid admin credentials"
├─ Log all login attempts
└─ Block after 5 failed attempts for 1 hour

Security:
├─ HTTPS only
├─ 2FA (Optional - OTP) recommended
└─ Session timeout: 4 hours
```

#### **ADMIN DASHBOARD**

```
Header:
├─ Logo & Title: "Election Administration Portal"
├─ Admin Name: "Logged in as: [Admin Name]"
├─ Current Status:
│  ├─ Blockchain: ✅ Connected / ❌ Disconnected
│  ├─ Database: ✅ Online / ❌ Offline
│  └─ Server: ✅ Healthy / ⚠️ Warning
└─ [SETTINGS] [LOGOUT]

Main Menu (Sidebar):
├─ 📊 DASHBOARD (Analytics)
├─ 🗳️ MANAGE ELECTIONS
├─ 👥 MANAGE CANDIDATES
├─ 🎉 MANAGE PARTIES
├─ 👨‍💼 MANAGE VOTERS
├─ 📋 VERIFY NOMINATIONS
├─ 📈 RESULTS & ANALYTICS
├─ 📝 AUDIT LOGS
└─ ⚙️ SETTINGS

Quick Stats (Dashboard Home):
├─ Total Elections: [Count]
├─ Active Elections: [Count]
├─ Total Registered Voters: [Count]
├─ Total Candidates: [Count]
├─ Total Parties: [Count]
├─ Total Votes Cast: [Live counter]
├─ Voter Turnout: [%]
└─ Last updated: [Timestamp]

Charts:
├─ Elections Timeline (Calendar view)
├─ Voter Distribution (Pie chart)
├─ Party Comparison (Bar chart)
└─ Vote Trends (Line chart)
```

#### **MANAGE ELECTIONS PAGE**

```
LIST VIEW:
├─ [+ NEW ELECTION] Button
├─ Filters:
│  ├─ By Status [Dropdown]
│  ├─ By Date Range [Calendar picker]
│  └─ Search [Text input]

Table/Cards Display:
├─ Election Name
├─ Election Type: "Municipal Corporation"
├─ Status Badge: [Notified / Nomination / Polling / Completed]
├─ Total Wards: [Number]
├─ Total Candidates: [Count]
├─ Total Registered Voters: [Count]
├─ Election Dates:
│  ├─ Notification Date
│  ├─ Nomination Start-End
│  ├─ Polling Date
│  └─ Result Date
├─ Voting Status:
│  ├─ Total Votes Cast: [Live]
│  └─ Voter Turnout %: [Live]
└─ Actions:
   ├─ [VIEW DETAILS]
   ├─ [EDIT]
   ├─ [DELETE] (if no votes)
   └─ [RESULTS] (if completed)

CREATE/EDIT ELECTION FORM:
├─ Election Name [Text input, required]
├─ Election Type [Fixed dropdown: "Municipal Corporation"]
├─ District [Dropdown: Fixed to district]
├─ Description [TextArea]
├─ Total Wards [Number input]

Timeline Section:
├─ Notification Date [DatePicker]
├─ Notification Number [Text] - from SEC
├─ Nomination Period:
│  ├─ Start Date [DatePicker]
│  └─ End Date [DatePicker]
├─ Scrutiny Date [DatePicker]
├─ Withdrawal Period:
│  ├─ Start Date [DatePicker]
│  └─ End Date [DatePicker]
├─ Campaign Period:
│  ├─ Start Date [DatePicker]
│  └─ End Date [DatePicker]
├─ Polling Date [DatePicker]
└─ Result Date [DatePicker]

Blockchain Section:
├─ Smart Contract Address [Auto-filled after deploy]
├─ [DEPLOY NEW CONTRACT] Button (if not deployed)
└─ Contract Status [✅ Active / ⏳ Deploying / ❌ Failed]

Reserved Seats Section:
├─ Women Reserved [Number]
├─ SC Reserved [Number]
├─ ST Reserved [Number]
├─ OBC Reserved [Number]
└─ Calculated: General = Total - (W+SC+ST+OBC)

Status Management:
├─ Current Status [Read-only, auto-updated]
├─ Manual override [Toggle] (admin only):
│  ├─ Can manually change status if needed
│  └─ Requires reason/note
└─ Conducting Authority [Text field] - "State Election Commission"

Actions:
├─ [SAVE & VALIDATE]
├─ [DRAFT] (Save without validation)
└─ [CANCEL]
```

#### **MANAGE PARTIES PAGE**

```
LIST VIEW:
├─ [+ ADD NEW PARTY] Button
├─ Filters:
│  ├─ By Recognition [National / State]
│  ├─ Search [Text input]
│  └─ Sort [By name / By votes]

Table/Cards Display:
├─ Party Logo/Color
├─ Party Name
├─ Party Code
├─ Recognition: [National / State]
├─ Candidates Count: [In current election]
├─ Total Votes: [Live counter]
├─ Vote Share %: [Calculated]
├─ Status: [Active / Inactive]
└─ Actions:
   ├─ [EDIT]
   ├─ [VIEW CANDIDATES]
   ├─ [DEACTIVATE]
   └─ [DELETE] (if no candidates)

CREATE/EDIT PARTY FORM:
├─ Party Name [Text input, required]
│  └─ Example: "Bharatiya Janata Party"
├─ Party Code [Text input, required, max 10 chars]
│  └─ Example: "BJP"
├─ Party Short Code [Text input]
│  └─ Example: "BJP"
├─ Party Color [Color Picker]
│  └─ Used for ballots & display
├─ Party Logo [Image Upload]
│  └─ Recommended: SVG or PNG
├─ Party Description [TextArea]
│  └─ Party ideology/info

Recognition Section:
├─ Is National Party? [Toggle]
├─ Is State Party? [Toggle]
├─ Is Recognized Party? [Toggle]
├─ Registration Number [Text]
│  └─ From Election Commission

Contact Section:
├─ Party President [Text]
├─ Office Address [TextArea]
├─ Phone [Text]
├─ Email [Text]
└─ Website [URL]

Candidate Settings:
├─ [VIEW ALL CANDIDATES] Link
└─ [MANAGE CANDIDATES] Button

Actions:
├─ [SAVE]
├─ [ACTIVATE/DEACTIVATE]
└─ [CANCEL]
```

#### **MANAGE CANDIDATES PAGE**

```
LIST VIEW:
├─ Filters:
│  ├─ By Election [Dropdown]
│  ├─ By Ward [Dropdown]
│  ├─ By Party [Dropdown]
│  ├─ By Status [Eligible/Rejected/Withdrawn]
│  └─ Search [By name/ID]
├─ [+ ADD NEW CANDIDATE] Button
├─ [📥 BULK IMPORT] Button (CSV)
└─ [📥 DOWNLOAD TEMPLATE] Button

Table/Cards Display:
├─ Ballot Number (assigned by SEC)
├─ Candidate Photo
├─ Candidate Name
├─ Party [Color badge + name]
├─ Ward
├─ Nomination Status:
│  ├─ Submitted: [Date]
│  ├─ Scrutiny: [Eligible/Ineligible/Pending]
│  └─ Ballot Position: [Number]
├─ Age & Qualification [Summary]
├─ Asset Value [₹ amount]
├─ Criminal Record [Yes/No indicator]
├─ Vote Count [Live]
├─ Status: [Active/Withdrawn/Disqualified]
└─ Actions:
   ├─ [VIEW FULL DETAILS]
   ├─ [EDIT DETAILS]
   ├─ [VIEW DOCUMENTS]
   ├─ [MARK WITHDRAWN]
   ├─ [DISQUALIFY]
   └─ [DELETE] (if no votes)

CREATE/ADD CANDIDATE FORM:
├─ Basic Info:
│  ├─ Full Name [Text, required]
│  ├─ Date of Birth [DatePicker, required]
│  │  └─ Must be 21+ years
│  ├─ Gender [Dropdown: Male/Female/Other]
│  ├─ Email [Text]
│  ├─ Phone [Text, required]
│  └─ Photo [Image Upload, required]

Election & Ward:
├─ Select Election [Dropdown, required]
├─ Select Ward [Dropdown, required]
│  └─ Filtered by selected election
├─ Ward Residency:
│  ├─ Resident for 1+ year? [Yes/No]
│  ├─ Proof Document [File upload]
│  └─ Proof Type [Utility bill/Property tax/Lease/Voter ID]

Party & Symbol:
├─ Select Party [Dropdown, required]
├─ Party Symbol [Display auto-filled]
├─ Ballot Position [Auto-assigned]
└─ [REASSIGN POSITION] (if allowed)

Documents & Verification:
├─ Aadhar Number [Encrypted input, required]
├─ Aadhar Upload [File]
├─ PAN Number [Optional]
├─ PAN Upload [File]
├─ Voter ID [Required]
├─ Voter ID Upload [File]

Affidavit Details:
├─ Total Assets Declared [Currency input]
├─ Asset Declaration Form [File upload]
├─ Criminal Record [Radio: Yes/No]
├─ If Yes:
│  ├─ Details [TextArea]
│  └─ Case Document [File upload]
├─ Affidavit Document [File upload]
└─ Date of Affidavit [DatePicker]

Nomination Details:
├─ Nomination Form Status [Dropdown]
│  └─ Submitted / Under Scrutiny / Eligible / Ineligible
├─ Nomination Number [Auto-fill]
├─ Nomination Date [DatePicker]
├─ Scrutiny Date [DatePicker]
├─ Scrutiny Result [Eligible/Ineligible/Appeal]
├─ Nominating Voters [10 voter signatures]:
│  ├─ Voter ID
│  ├─ Voter Name
│  └─ Voter Signature [checkbox]
└─ Nomination Fee [Currency, show status]
    ├─ Amount: ₹500
    ├─ Status: [Paid/Refundable/Non-refundable]
    └─ Payment Date

Candidate Bio:
├─ Qualification [Dropdown]
│  └─ 10th/12th/Graduate/Post-Graduate
├─ Occupation [Text]
├─ Manifesto [TextArea, optional]
└─ Prior Experience [TextArea, optional]

Actions:
├─ [SAVE DRAFT]
├─ [SUBMIT FOR SCRUTINY]
├─ [MARK ELIGIBLE] (post-scrutiny)
├─ [MARK INELIGIBLE] (with reason)
└─ [CANCEL]

Documents Tab:
├─ View all uploaded documents
├─ Download each document
├─ Mark as verified [Checkbox for each]
├─ Add notes/comments [TextArea]
└─ Print nomination form
```

#### **MANAGE VOTERS PAGE**

```
LIST VIEW:
├─ Filters:
│  ├─ By Ward [Dropdown]
│  ├─ By Verification Status [Verified/Pending/Rejected]
│  ├─ By Voter Status [Active/Inactive/Blocked]
│  ├─ By Gender [Male/Female/Other]
│  ├─ By Category [General/SC/ST/OBC]
│  ├─ By Voting Status [Voted/Not Voted] (per election)
│  └─ Search [By Voter ID/Name/Phone]
├─ [📥 BULK UPLOAD] CSV Button
├─ [📥 DOWNLOAD TEMPLATE] Button
├─ [🔄 SYNC WITH SEC ROLL] Button (fetch latest voters)
└─ [📊 VOTER STATISTICS] Button

Table/Cards Display:
├─ Voter ID
├─ Voter Name
├─ Ward
├─ Category [General/SC/ST/OBC]
├─ Verification Status [✅ Verified / ⏳ Pending / ❌ Rejected]
├─ Status [🟢 Active / 🔴 Inactive / ⛔ Blocked]
├─ Aadhar Verified [✅/❌]
├─ Mobile Verified [✅/❌]
├─ Email Verified [✅/❌]
├─ Voted (for active election) [✅/❌]
├─ Last Updated [Date]
└─ Actions:
   ├─ [VIEW DETAILS]
   ├─ [VERIFY]
   ├─ [BLOCK/UNBLOCK]
   ├─ [ACTIVATE/DEACTIVATE]
   └─ [DELETE] (not voted)

VOTER DETAILS PAGE:
├─ Profile Section (Read-only):
│  ├─ Voter ID
│  ├─ Full Name
│  ├─ Date of Birth
│  ├─ Gender
│  ├─ Age (calculated)
│  ├─ Email
│  ├─ Phone (masked)
│  ├─ Ward
│  ├─ Category [General/SC/ST/OBC]
│  └─ Photo [if available]

Verification Section:
├─ Overall Status [Active/Inactive/Blocked]
├─ Verification Status:
│  ├─ Aadhar Status [Verified/Pending/Failed]
│  ├─ Aadhar (Last 4 digits) [Masked display]
│  ├─ Mobile Status [Verified/Pending/Failed]
│  ├─ Email Status [Verified/Pending/Failed]
│  ├─ Residency Proof [Document link]
│  └─ Verified By [Admin name]
│  └─ Verified Date [Timestamp]

Eligibility Section:
├─ Is Eligible to Vote? [Yes/No]
├─ Eligibility Criteria:
│  ├─ Age >= 18? [✅/❌]
│  ├─ Resident > 6 months? [✅/❌]
│  ├─ No disqualification? [✅/❌]
│  └─ All documents verified? [✅/❌]
├─ Blocked Reason [If blocked]
│  └─ [Text area]
└─ Blocked By [Admin name/date]

Voting History Section:
├─ For each election:
│  ├─ Election Name
│  ├─ Voting Status [Voted/Not Voted]
│  ├─ Date Voted [If voted]
│  ├─ Candidate Voted [Anonymized]
│  └─ Transaction Hash [Clickable]

Actions:
├─ [VERIFY] (if pending)
├─ [REJECT] (with reason)
├─ [BLOCK] (if fraud suspected)
├─ [UNBLOCK] (if blocked)
├─ [ACTIVATE] (if inactive)
├─ [DEACTIVATE] (if active)
├─ [EDIT DETAILS] (limited fields)
├─ [RESET PASSWORD] (via email)
└─ [DELETE] (only if no voting history)

Edit Voter Modal (Limited fields):
├─ Email [Editable]
├─ Phone [Editable]
├─ Category [Editable]
└─ Residency Proof [Replaceable]

Block Voter Modal:
├─ Reason [Dropdown]:
│  ├─ Fraud/Duplicate
│  ├─ Disqualified
│  ├─ Deceased
│  ├─ Migrated
│  └─ Other
├─ Additional Notes [TextArea]
└─ [BLOCK] [CANCEL]
```

#### **RESULTS & ANALYTICS PAGE**

```
HEADER:
├─ Election Selection [Dropdown]
├─ Status: "Results declared on [Date/Time]"
├─ Voter Turnout: [Live %]
├─ Total Votes Cast: [Live count]
└─ [🔄 REFRESH] Button (live updates)

OVERVIEW CARDS:
├─ Total Wards: [Count]
├─ Total Candidates: [Count]
├─ Total Votes Cast: [Live]
├─ Voter Turnout: [%]
└─ Expected Winner: [Name]

WARD-WISE RESULTS:
├─ [Ward Filter Dropdown] or view all wards
├─ For each ward:
│  ├─ Ward Number: [Number]
│  ├─ Candidate Rankings:
│  │  ├─ 1st: [Candidate] - [Party] - [Vote Count] - [%]
│  │  ├─ 2nd: [Candidate] - [Party] - [Vote Count] - [%]
│  ├─ Votes by Category:
│  │  ├─ General: [Count]
│  │  ├─ SC: [Count]
│  │  ├─ ST: [Count]
│  │  └─ OBC: [Count]
│  └─ Polling %: [%]

PARTY-WISE RESULTS:
├─ Overall Party Performance:
│  ├─ Party Name
│  ├─ Votes Received: [Count]
│  ├─ Vote Share %: [%]
│  ├─ Seats Won: [Count]
│  └─ Seats per category

CHARTS & GRAPHS:
├─ Pie Chart: Vote distribution by party
├─ Bar Chart: Candidate votes comparison (by ward)
├─ Line Chart: Vote trends over time
├─ Ward Map: Ward-wise party winning display
└─ Voter Turnout: Timeline turnout growth

EXPORT OPTIONS:
├─ [📊 EXPORT AS PDF] (full report)
├─ [📊 EXPORT AS EXCEL] (ward-wise results)
├─ [📊 EXPORT AS CSV] (detailed results)
└─ [🖨️ PRINT] (result sheet)

BLOCKCHAIN VERIFICATION:
├─ Transaction Hash Display
├─ [✅ VERIFY ON BLOCKCHAIN] Button
│  └─ Link to blockchain explorer
├─ Total Votes on Blockchain: [Count]
├─ Blockchain Status: [Verified/Unverified]
└─ Last Block: [Block number] on [Date/Time]

VERIFICATION TABS:
├─ Tab 1: Ward Results (detailed)
├─ Tab 2: Party Results
├─ Tab 3: Candidate Results
└─ Tab 4: Blockchain Verification
```

#### **AUDIT LOGS PAGE**

```
Display:
├─ Filters:
│  ├─ By Admin [Dropdown]
│  ├─ By Action Type [Dropdown]
│  ├─ By Date Range [Calendar picker]
│  └─ Search [Text input]

Table Columns:
├─ Timestamp [Date & Time]
├─ Admin Name [Who performed]
├─ Admin ID [UID]
├─ Action Type [Created/Edited/Deleted/Verified/Blocked]
├─ Resource Type [Election/Candidate/Voter/Party]
├─ Resource [Name/ID]
├─ Old Value [What changed from]
├─ New Value [What changed to]
├─ IP Address [From where]
├─ Status [Success/Failed]
└─ [VIEW DETAILS] Action

Audit Log Entry Example:
├─ 2026-02-15 10:30:45 | Admin: Rajesh Kumar
├─ Action: MARK ELIGIBLE
├─ Resource: Candidate - Priya Sharma (CND_001)
├─ Old Status: Under Scrutiny
├─ New Status: Eligible
├─ Reason: "All documents verified"
└─ IP: 192.168.1.100
```

---

## COMPLETE ELECTION WORKFLOW

### Election Lifecycle (60-90 Days)

```
DAY 0-5: ELECTION NOTIFICATION
├─ State Election Commission issues notification
├─ Official gazette published
├─ Media release
├─ Voter registration roll finalized
└─ Admin system activated

DAY 6-10: NOMINATION FILING
├─ Nomination period opens
├─ Candidates submit forms with documents
├─ 10 voter nominations required
├─ Nomination fee paid
├─ App shows: Status = "NOMINATION OPEN"
└─ Admin: Verify documents as they arrive

DAY 11-13: SCRUTINY OF NOMINATIONS
├─ Election Commission examines forms
├─ Verifies documents & eligibility
├─ Decision: Eligible / Ineligible / Accepted subject to objection
├─ App shows: Status = "SCRUTINY IN PROGRESS"
├─ Admin: Mark candidates as eligible/ineligible
└─ Publish list of eligible candidates

DAY 14-16: WITHDRAWAL PERIOD
├─ Eligible candidates can withdraw
├─ Submitted withdrawals are processed
├─ Final candidate list finalized
├─ Ballot positions assigned by lottery
├─ App shows: Status = "WITHDRAWAL PERIOD"
└─ Candidates list locked

DAY 17-30: CAMPAIGN PERIOD
├─ Candidates campaign for votes
├─ Voter education campaigns
├─ Media coverage
├─ 48-hour silent period before polling
├─ App shows: Status = "CAMPAIGN ACTIVE"
└─ Admin: Monitor campaign violations

DAY 31: POLLING DAY
├─ Voting centers open: 8 AM to 5 PM
├─ Voters cast votes on EVM
├─ Real-time vote counting disabled (security)
├─ Voter turnout tracked
├─ App shows: Status = "POLLING" (Live updates every hour)
│  └─ Voter participation %
│  └─ Estimated votes cast
├─ Poll observers present
└─ Tight security

DAY 32-33: COUNTING & RESULTS
├─ Sealed EVMs brought to counting centers
├─ Votes counted
├─ Results declared ward-wise
├─ App shows: Status = "COUNTING" → "COMPLETED"
├─ Live results displayed:
│  ├─ Candidate votes
│  ├─ Party vote share
│  └─ Ward winners
└─ Final results published in gazette

DAY 34-64: OBJECTION PERIOD (30 days)
├─ Candidates can file petitions
├─ Election Commission hears objections
├─ If petition upheld: Election cancelled for that ward
└─ If rejected: Result stands

DAY 65+: POST-ELECTION
├─ Winner takes oath
├─ Municipal council formed
├─ Voter history recorded
└─ Blockchain vote records permanent
```

### User Workflow During Election

```
BEFORE POLLING DAY:
User → Login → View Dashboard
        ├─ Status: "Election Upcoming"
        ├─ Polling Date: [Date]
        ├─ View Candidates: [List all candidates per ward]
        └─ [PREPARE] Read manifesto/candidate info

ON POLLING DAY (8 AM - 5 PM):
User → Login → View Dashboard
        ├─ Status: "VOTING ACTIVE"
        ├─ Time Remaining: [Live countdown]
        ├─ Polling location: [Address from voter DB]
        └─ [VOTE NOW] Button
        
User → Click [VOTE NOW]
        ├─ Go to voting location
        ├─ Show voter ID/phone
        ├─ Verify from electoral roll
        ├─ Mark with indelible ink
        ├─ Return to phone
        ├─ Open app
        └─ [CAST VOTE]

VOTING PROCESS (In App):
User → [CAST VOTE]
        ├─ Show candidates for ward
        ├─ [SELECT CANDIDATE]
        ├─ Show confirmation: "Are you sure?"
        ├─ [CONFIRM VOTE]
        ├─ Blockchain transaction submitted
        └─ Wait for confirmation...

CONFIRMATION:
App → Records vote
        ├─ Firebase: Insert vote record
        ├─ Blockchain: Record transaction
        ├─ Get transaction hash
        └─ Show confirmation page

User → Sees:
        ├─ ✅ "Vote Recorded"
        ├─ Candidate name
        ├─ Transaction hash
        ├─ Timestamp
        └─ [DONE]

AFTER VOTING:
User → Dashboard
        ├─ Status: "✅ You have voted"
        ├─ Cannot vote again
        └─ Can view results (when declared)

AFTER RESULTS DECLARED:
User → Dashboard
        ├─ Status: "✅ Results Declared"
        ├─ [VIEW RESULTS]
        └─ See elected candidate

User → History
        ├─ Show voted election
        ├─ Candidate voted for (anonymized)
        ├─ Transaction hash
        └─ Blockchain proof
```

### Admin Workflow During Election

```
NOTIFICATION PHASE (Day 0-5):
Admin → Dashboard
        ├─ [+ CREATE ELECTION]
        ├─ Fill election details
        ├─ Add wards (50-150)
        ├─ Set notification date
        ├─ Deploy smart contract
        └─ [SAVE & PUBLISH]
        
Dashboard → Status: "NOTIFIED"
        ├─ Notification published
        ├─ Voter roll activated
        └─ System ready for nominations

NOMINATION PHASE (Day 6-10):
Admin → [MANAGE CANDIDATES]
        ├─ Candidates submit forms
        ├─ Admin receives notifications
        ├─ [VERIFY DOCUMENTS]
        ├─ Check eligibility
        ├─ [MARK SUBMITTED] for each
        └─ Candidates count increases

Dashboard → Status: "NOMINATION OPEN"
        ├─ Total candidates: [Live counter]
        ├─ Candidates per ward: [Distribution]
        └─ Submission deadline: [Countdown]

SCRUTINY PHASE (Day 11-13):
Admin → [MANAGE CANDIDATES]
        ├─ Review each candidate form
        ├─ Verify:
        │  ├─ Documents complete
        │  ├─ Eligibility criteria met
        │  ├─ 10 voter nominations valid
        │  └─ Age & qualification OK
        ├─ [MARK ELIGIBLE] or [MARK INELIGIBLE]
        ├─ If ineligible, specify reason
        └─ Publish eligible list

Dashboard → Status: "SCRUTINY IN PROGRESS"
        ├─ Eligible candidates: [Count]
        ├─ Ineligible candidates: [Count]
        ├─ Pending review: [Count]
        └─ Scrutiny deadline: [Countdown]

WITHDRAWAL PHASE (Day 14-16):
Admin → [MANAGE CANDIDATES]
        ├─ Candidates submit withdrawal
        ├─ [MARK WITHDRAWN]
        ├─ Remove from ballot
        ├─ Refund nomination fee
        └─ Update candidate list

Dashboard → Status: "WITHDRAWAL PERIOD"
        ├─ Withdrawn candidates: [Count]
        ├─ Final candidates per ward: [Updated count]
        ├─ Ballot positions assigned
        └─ Final list locked

CAMPAIGN PHASE (Day 17-30):
Admin → Dashboard
        ├─ Monitor campaign activities (external)
        ├─ View candidate info page
        ├─ Check voter engagement
        ├─ Address complaints
        └─ 48-hour silent period notice

Dashboard → Status: "CAMPAIGN ACTIVE"
        ├─ Days remaining: [Countdown]
        ├─ Candidate activity: [Stats]
        └─ Voter education: [Materials]

POLLING DAY (Day 31):
Admin → [MANAGE VOTERS]
        ├─ Real-time voter turnout tracking
        ├─ Monitor voting progress
        ├─ Every hour:
        │  ├─ Update turnout %
        │  ├─ Show votes cast estimate
        │  └─ Ward-wise participation
        ├─ Address voting issues/complaints
        ├─ Extend polling hours if needed
        └─ Close polling at 5 PM

Dashboard → Status: "POLLING"
        ├─ Time: [Live clock]
        ├─ Polling Hours: 8 AM to 5 PM
        ├─ Total Votes Cast: [Live counter, updated hourly]
        ├─ Voter Turnout: [Live %]
        ├─ Wards Voting: [Live ≥ X%]
        └─ Alerts: Any anomalies/issues

COUNTING & RESULTS (Day 32-33):
Admin → [RESULTS & ANALYTICS]
        ├─ Votes counted (automated from blockchain)
        ├─ Results calculated per ward
        ├─ Party vote share calculated
        ├─ Overall winner determined
        ├─ [PUBLISH RESULTS] Button
        └─ Results declared

Dashboard → Status: "COMPLETED"
        ├─ Elected Candidate: [Name]
        ├─ Winner Details:
        │  ├─ Party
        │  ├─ Votes received
        │  ├─ Vote %
        │  └─ Ward
        ├─ Runner-up: [Name & votes]
        ├─ Party-wise results
        └─ Blockchain verification: ✅

POST-ELECTION (Day 34+):
Admin → [AUDIT LOGS]
        ├─ Review all actions taken
        ├─ Archive election data
        ├─ Generate final report
        ├─ Export results
        ├─ Close blockchain contract
        └─ Prepare for next election

Archive:
├─ Election data locked (read-only)
├─ Voting records permanent (blockchain)
├─ Audit trail complete
└─ Certificate of election issued
```

---

## FIELD CHECKLIST SUMMARY

### **ELECTIONS TABLE**

```
✅ KEEP:
├─ electionId
├─ electionName
├─ electionType (fixed)
├─ description
├─ totalWards
├─ notificationDate
├─ nominationStartDate
├─ nominationEndDate
├─ scrutinyDate
├─ withdrawalDate
├─ campaignStartDate
├─ campaignEndDate
├─ pollingDate
├─ resultDate
├─ status
├─ contractAddress
├─ createdAt
└─ createdBy

❌ REMOVE:
├─ type
├─ state
├─ district
└─ constituencies

⭐ ADD NEW:
├─ electionCommissionNotification
├─ reservedSeats (JSON)
├─ womenReservation
├─ totalElectors
├─ estimatedTurnout
├─ conductingAuthority
├─ district (fixed)
└─ municipalityType
```

### **CANDIDATES TABLE**

```
✅ KEEP:
├─ candidateId
├─ candidateName
├─ dateOfBirth
├─ gender
├─ qualification
├─ partyId
├─ partySymbol
├─ ward
├─ electionId
├─ phone
├─ email
├─ address
├─ photo
├─ voteCount
├─ status
└─ createdDate

❌ REMOVE:
├─ symbol
└─ constituency

⭐ ADD NEW:
├─ aadharNumber (encrypted)
├─ panNumber (encrypted)
├─ criminalRecord
├─ criminalDetails
├─ assetValue
├─ educationCertificate (URL)
├─ nominationFormDocument (URL)
├─ nomineeStatus
├─ nominationNumber
├─ nomineeAffidavit (URL)
├─ photoFIR (URL)
├─ withdrawalDate
├─ disqualificationReason
├─ ballotSymbol
├─ ballotPosition
└─ nominationFormStatus
```

### **PARTIES TABLE** (NEW)

```
⭐ ADD ALL:
├─ partyId
├─ partyName
├─ partyShortCode
├─ partyColor
├─ partySymbol
├─ partyLogo (URL)
├─ partyDescription
├─ registrationNumber
├─ isNationalParty
├─ isStateParty
├─ isRecognizedParty
├─ totalCandidates
├─ totalVotes
├─ votePercentage
├─ createdDate
├─ updatedDate
├─ status
├─ partyPresident
├─ partyWebsite
├─ partyContact
├─ partyHeadquarters
├─ foundedYear
└─ partyIdeology
```

### **VOTERS TABLE**

```
✅ KEEP:
├─ voterId
├─ voterName
├─ dateOfBirth
├─ gender
├─ email
├─ phone
├─ ward
├─ status
├─ isEligible
├─ hasVoted
├─ votingTimestamp
├─ registeredDate
└─ lastUpdated

❌ REMOVE:
├─ state
├─ district
└─ address

⭐ ADD NEW:
├─ aadharNumber (encrypted)
├─ pancardNumber (encrypted)
├─ voterSlipNumber
├─ constituencyType
├─ electionCommissionRollNumber
├─ verificationStatus
├─ verificationDate
├─ verifiedBy
├─ aadharVerified
├─ mobileVerified
├─ emailVerified
├─ isResident
├─ residencyProof (URL)
├─ blockedReason
├─ blockedDate
└─ blockedBy
```

---

## COMPLIANCE CHECKLIST

✅ **Must Implement:**

- [ ] Single ward voting (not multiple constituencies)
- [ ] Vote-once enforcement per election
- [ ] Voter anonymity on blockchain
- [ ] Blockchain immutability for votes
- [ ] Voter eligibility verification (age 18+, resident 6 months)
- [ ] Candidate eligibility verification (age 21+, resident 1 year)
- [ ] Reserved seat system (Women 1/3, SC/ST categories)
- [ ] Scrutiny process for nominations
- [ ] Nomination fee system
- [ ] Election Commission status tracking
- [ ] Audit logs for all admin actions
- [ ] OTP verification for voters
- [ ] Encrypted Aadhar/PAN storage
- [ ] Residency proof requirement
- [ ] Criminal record declaration
- [ ] Asset declaration
- [ ] 48-hour campaign silent period
- [ ] Ballot position assignment by lottery
- [ ] Real-time vote counting (safe, not live during polling)
- [ ] Results blockchain verification

---

## NEXT STEPS

### Phase 1 - Immediate Implementation
1. Create new Dart model classes (Party.dart, simplified AppUser.dart)
2. Refactor authentication (remove registration, add login-only flow)
3. Build Manage Parties admin page
4. Build Manage Elections admin page

### Phase 2 - Core Features
1. Build Manage Candidates admin page
2. Build Manage Voters admin page
3. Implement vote-once enforcement logic
4. Build Results & Analytics dashboard

### Phase 3 - Advanced Features
1. Implement Audit Logs
2. Add export/reporting features
3. Integrate blockchain verification
4. Multi-language support

---

## QUICK REFERENCE SUMMARY

### Election Code Quick Lookup

| Election Code | District | Type | Year | wards | Status Example |
|---------------|----------|------|------|-------|----------------|
| GUJ_AHM_MC_2026 | Ahmedabad | Municipal Corp | 2026 | 130 | Active/Completed |
| GUJ_SRT_MC_2026 | Surat | Municipal Corp | 2026 | 120 | Upcoming |
| GUJ_VDR_MC_2026 | Vadodara | Municipal Corp | 2026 | 100 | Planning |
| GUJ_RAJ_MC_2026 | Rajkot | Municipal Corp | 2026 | 80 | Nomination |
| GUJ_BRD_MC_2026 | Bharuch | Municipal Corp | 2026 | 40 | Completed |

### Critical Implementation Checklist

#### **Database Models (MUST CREATE/UPDATE)**
- [ ] `Party.dart` - NEW party management model
- [ ] `AppUser.dart` - SIMPLIFY (remove state, district, constituency)
- [ ] `Election.dart` - ADD electionCommissionNotification, reservedSeats, municipalityType
- [ ] `Candidate.dart` - ADD aadhar, pan, criminal record, affidavit fields
- [ ] `Voter.dart` - ADD aadhar verification, residency proof fields
- [ ] `AuditLog.dart` - NEW for admin action tracking

#### **Services (MUST CREATE/UPDATE)**
- [ ] `PartyService.dart` - NEW for party management
- [ ] `AuthService.dart` - REFACTOR to remove registration
- [ ] `FirestoreService.dart` - ADD party CRUD, candidate scrutiny
- [ ] `BlockchainService.dart` - ADD electionId support
- [ ] `VoterVerificationService.dart` - NEW for voter verification

#### **Admin Pages (MUST CREATE/UPDATE)**
- [ ] `AdminDashboard.dart` - Add Manage Parties link
- [ ] `ManageElections.dart` - UPDATE with new fields
- [ ] `ManageCandidates.dart` - UPDATE with scrutiny workflow
- [ ] `ManageParties.dart` - CREATE NEW
- [ ] `ManageVoters.dart` - UPDATE with verification
- [ ] `AuditLogs.dart` - CREATE NEW

#### **User Pages (MUST UPDATE/REMOVE)**
- [ ] `LoginPage.dart` - REFACTOR to remove registration link
- [ ] `RegistrationPage.dart` - DELETE (use login only)
- [ ] `RegistrationNewPage.dart` - DELETE
- [ ] `HomePage.dart` - UPDATE to show election code
- [ ] `VotingPage.dart` - Update to show ward-based candidates
- [ ] `HistoryPage.dart` - Show election codes

#### **Firestore Structure (MUST CONFIGURE)**
- [ ] Create `elections/` collection with electionId as doc ID
- [ ] Create `parties/` collection with partyId as doc ID
- [ ] Update `candidates/` with new fields
- [ ] Update `voters/` with verification fields
- [ ] Create `audit_logs/` collection
- [ ] Create `verification_queue/` collection

#### **Blockchain (MUST UPDATE)**
- [ ] Update smart contract to use election codes
- [ ] Add party information to contract
- [ ] Implement vote validation by election ID
- [ ] Test contract deployment

### All Election Codes for Gujarat (Complete Reference)

```
STATE: GUJARAT

TIER 1: MUNICIPAL CORPORATIONS (MC) - All major cities
GUJ_AHM_MC_2026  - Ahmedabad
GUJ_SRT_MC_2026  - Surat
GUJ_VDR_MC_2026  - Vadodara
GUJ_RAJ_MC_2026  - Rajkot
GUJ_BRD_MC_2026  - Bharuch
GUJ_JAM_MC_2026  - Jamnagar
GUJ_JUN_MC_2026  - Junagadh
GUJ_BHV_MC_2026  - Bhavnagar
GUJ_AMR_MC_2026  - Amreli
GUJ_GAD_MC_2026  - Gandhinagar
GUJ_GIR_MC_2026  - Girsomnath
GUJ_MOR_MC_2026  - Morbi
GUJ_KAC_MC_2026  - Kachchh
GUJ_ANA_MC_2026  - Anand

TIER 2: MUNICIPAL BOARDS (MB) - Medium towns
GUJ_GAI_MB_2026  - Gaikwad
GUJ_MEH_MB_2026  - Mehsana
GUJ_PAT_MB_2026  - Patan
GUJ_SIR_MB_2026  - Sirpur
GUJ_UDA_MB_2026  - Udaipur

TIER 3: SPECIAL CODES (Future Use)
GUJ_[DIST]_ZP_[YEAR]  - Zilla Parishad (District level)
GUJ_[DIST]_TP_[YEAR]  - Taluka Panchayat (Taluka level)
GUJ_[DIST]_GP_[YEAR]  - Gram Panchayat (Village level)
```

### Field Changes Summary

#### **ELECTIONS TABLE**
- ❌ Remove: `type`, `state`, `district`, `constituencies`
- ✅ Keep: `electionId`, `electionName`, `description`, `status`, `pollingDate`, `resultDate`
- ⭐ Add: `electionCommissionNotification`, `reservedSeats`, `womenReservation`, `totalElectors`, `municipalityType`

#### **CANDIDATES TABLE**
- ❌ Remove: `symbol`, `constituency`
- ✅ Keep: `candidateId`, `candidateName`, `partyId`, `ward`, `electionId`, `voteCount`, `status`
- ⭐ Add: `aadharNumber`, `panNumber`, `criminalRecord`, `assetValue`, `nomineeStatus`, `ballotPosition`

#### **PARTIES TABLE** (NEW)
- ⭐ Create: All fields including `partyId`, `partyName`, `partyColor`, `partySymbol`, `registrationNumber`, `isNationalParty`

#### **VOTERS TABLE**
- ❌ Remove: `state`, `district`
- ✅ Keep: `voterId`, `voterName`, `dateOfBirth`, `ward`, `email`, `phone`, `status`
- ⭐ Add: `aadharNumber`, `voterSlipNumber`, `verificationStatus`, `aadharVerified`, `mobileVerified`, `residencyProof`

### Key Features Summary

**For Users:**
- ✅ Login with Voter ID + OTP (no registration)
- ✅ View upcoming elections by district
- ✅ Vote for candidates in their ward
- ✅ See vote confirmation with blockchain hash
- ✅ View voting history
- ✅ Read-only profile

**For Admins:**
- ✅ Manage Elections (create, schedule, publish)
- ✅ Manage Parties (create, register, deactivate)
- ✅ Manage Candidates (add, verify, mark eligible, disqualify)
- ✅ Manage Voters (verify, block, check eligibility)
- ✅ View Real-time Results (vote counting, analytics)
- ✅ Audit Logs (track all actions)

**Compliance Features:**
- ✅ Vote-once enforcement per election
- ✅ Voter eligibility verification (age 18+, resident 6+ months)
- ✅ Candidate eligibility verification (age 21+, resident 1+ year)
- ✅ Reserved seats system (Women 1/3, SC/ST)
- ✅ Criminal record declaration
- ✅ Asset declaration
- ✅ Blockchain vote immutability
- ✅ Aadhar/PAN encryption

---

## REFERENCES

- **Indian Constitution:** Articles related to voting rights
- **Municipal Corporation Act, 1949:** Election procedures
- **Gujarat Municipal Corporations Act, 1975:** State-specific regulations
- **Representation of People Act, 1951:** Electoral regulations
- **Election Commission of India:** Standard procedures
- **Project Election Code Format:** GUJ_[DISTRICT]_[TYPE]_[YEAR]

---

**Last Updated:** April 27, 2026  
**Documentation Version:** 2.0 (With Election Code System)  
**Project Status:** Complete Documentation - Ready for Implementation  
**Target Deployment:** Single District (Gujarat) - Municipal Elections  
**Election Code Examples:** GUJ_AHM_MC_2026, GUJ_SRT_MC_2026, GUJ_VDR_MC_2026

