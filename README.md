# 🗳️ E-Voting System Using Blockchain

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Backend-orange?logo=firebase)
![Ethereum](https://img.shields.io/badge/Ethereum-Blockchain-627EEA?logo=ethereum)
![Solidity](https://img.shields.io/badge/Solidity-Smart_Contracts-black?logo=solidity)
![Dart](https://img.shields.io/badge/Dart-Language-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-Educational-green)

### Secure • Transparent • Tamper-Proof Digital Voting Platform

A Blockchain-powered E-Voting System developed using Flutter, Firebase, Ethereum, Solidity, and Web3 technologies to provide a secure, transparent, and trustworthy digital election platform.

</div>

---

# 📖 Project Overview

The **E-Voting System Using Blockchain** is a secure electronic voting platform designed to eliminate common problems found in traditional voting systems such as vote tampering, duplicate voting, lack of transparency, and centralized control.

The application combines the power of:

- Flutter Mobile Application
- Firebase Backend Services
- Ethereum Blockchain
- Solidity Smart Contracts
- SHA-256 Hashing
- Web3 Integration

to create a highly secure and auditable voting environment.

---

# 🎯 Problem Statement

Traditional voting systems face several challenges:

- Vote manipulation and fraud
- Duplicate voting attempts
- Centralized control of voting records
- Lack of transparency
- High operational costs
- Human intervention errors
- Limited voter trust
- Slow result processing

These issues can significantly affect election credibility and public confidence.

---

# 💡 Proposed Solution

The E-Voting System uses Blockchain technology to ensure:

✅ One Voter = One Vote

✅ Tamper-Proof Vote Storage

✅ Transparent Election Process

✅ Secure Authentication

✅ Immutable Voting Records

✅ Blockchain Audit Trail

✅ Fast Result Generation

Every vote is recorded as a blockchain transaction, making it impossible to modify or delete voting records once submitted.

---

# 🚀 Key Features

## 👤 User Module

### Voter Registration

- Aadhaar Verification
- Voter ID Verification
- Mobile Number Verification
- OTP Authentication
- SHA-256 Hash Generation
- Secure User Registration

### User Login

- Secure Authentication
- OTP Verification
- Password Protection
- Session Management

### Election Dashboard

- View Active Elections
- View Upcoming Elections
- Election Details
- Candidate Information

### Voting Module

- Candidate Selection
- Vote Confirmation
- Blockchain Vote Submission
- Transaction Hash Generation
- Voting Success Animation

### Voting History

- Previous Votes
- Election Details
- Blockchain Transaction Records

### Profile Management

- View Profile
- Update Information
- Change Password

---

## 🛡️ Admin Module

### Election Management

- Create Elections
- Update Elections
- Activate Elections
- Close Elections

### Candidate Management

- Add Candidate
- Edit Candidate
- Remove Candidate

### Voter Verification

- Verify User Accounts
- Approve Voters
- Reject Invalid Applications

### Results Management

- View Results
- Generate Reports
- Election Analytics

### Dashboard Analytics

- Total Voters
- Total Votes
- Active Elections
- Election Statistics

---

# 🏗️ System Architecture

```text
+------------------------+
| Flutter Mobile App     |
+-----------+------------+
            |
            v
+------------------------+
| Firebase Authentication|
+------------------------+
            |
            v
+------------------------+
| Firebase Firestore     |
+------------------------+
            |
            v
+------------------------+
| Ethereum Blockchain    |
+------------------------+
            |
            v
+------------------------+
| Solidity Smart Contract|
+------------------------+
```

---

# 🔐 Security Features

## Authentication Security

- OTP Verification
- Firebase Authentication
- Password Encryption
- User Validation

## Blockchain Security

- Immutable Vote Records
- Decentralized Storage
- Smart Contract Validation

## Data Security

- SHA-256 Hashing
- Salt Generation
- Secure Data Storage

## Election Security

- Duplicate Vote Prevention
- Election Validation
- Transaction Verification

---

# 🔄 Voting Workflow

## Step 1

User logs into application

↓

## Step 2

User selects election

↓

## Step 3

Candidate list is loaded

↓

## Step 4

User selects candidate

↓

## Step 5

Vote hash generated

```text
Vote Hash =
User Hash +
Candidate ID +
Election ID +
Timestamp
```

↓

## Step 6

Smart contract invoked

↓

## Step 7

Blockchain verifies voter

↓

## Step 8

Vote recorded on blockchain

↓

## Step 9

Transaction Hash generated

↓

## Step 10

Vote metadata stored in Firebase

↓

## Step 11

Success confirmation shown

↓

## Step 12

Voting history updated

---

# ⚙️ Technology Stack

## Frontend

| Technology | Purpose |
|------------|----------|
| Flutter | Mobile App Development |
| Dart | Programming Language |

---

## Backend

| Technology | Purpose |
|------------|----------|
| Firebase Authentication | User Authentication |
| Firestore | Database |
| Firebase Storage | File Storage |

---

## Blockchain

| Technology | Purpose |
|------------|----------|
| Ethereum | Blockchain Network |
| Solidity | Smart Contracts |
| Web3.dart | Blockchain Integration |
| Ganache | Local Blockchain |

---

## Security

| Technology | Purpose |
|------------|----------|
| SHA-256 | Hashing |
| Salt | Additional Security |
| OTP Verification | User Validation |

---

# 📱 Application Screens

## User Side

### Authentication

- Splash Screen
- Registration Page
- Login Page
- OTP Verification
- Forgot Password

### Main Application

- Home Dashboard
- Election Details
- Candidate List
- Voting Page
- Vote Confirmation

### Additional Pages

- Voting History
- Profile
- Results
- Guidelines
- Help & Support

---

## Admin Side

- Admin Login
- Dashboard
- Manage Elections
- Manage Candidates
- Manage Voters
- Manage Votes
- Results Management
- Analytics
- Settings

---

# 🗄️ Database Collections

## users

```json
{
  "userId": "",
  "name": "",
  "aadhaar": "",
  "phone": "",
  "email": "",
  "voterHash": "",
  "role": ""
}
```

---

## elections

```json
{
  "electionId": "",
  "title": "",
  "description": "",
  "startDate": "",
  "endDate": "",
  "status": ""
}
```

---

## candidates

```json
{
  "candidateId": "",
  "name": "",
  "party": "",
  "photoUrl": "",
  "electionId": ""
}
```

---

## votes

```json
{
  "voteId": "",
  "voterHash": "",
  "candidateId": "",
  "transactionHash": "",
  "timestamp": ""
}
```

---

# 📜 Smart Contract Functions

## registerVoter()

Registers a voter on blockchain.

---

## castVote()

Records vote securely on blockchain.

---

## hasVoted()

Checks whether voter has already voted.

---

## getResults()

Retrieves election results.

---

## countVotes()

Counts total votes.

---

# 📊 Advantages

- Secure Voting
- Transparent Process
- Immutable Records
- Reduced Election Cost
- Fast Results
- Decentralized Architecture
- Increased Voter Trust
- Real-Time Verification

---

# 🔮 Future Scope

## AI Integration

- Fraud Detection
- Voter Analytics

## Advanced Security

- Biometric Authentication
- Face Recognition

## National Deployment

- Government Elections
- University Elections
- Corporate Voting

## Cloud Blockchain

- Public Ethereum Network
- Scalable Infrastructure

---

# 👨‍💻 Team Members

| Name | Role |
|--------|--------|
| Gohil Bansirajsinh | Blockchain Specialist |
| Gohil Satyajeetsinh | Software Developer |
| Vala Priyarajsinh | Backend & Database Engineer |
| Vaja Tushar | UI/UX & Testing Engineer |

---

# 🎓 Academic Information

**Project Title:** E-Voting System Using Blockchain

**Department:** Information Technology

**College:** Shantilal Shah Engineering College

**University:** Gujarat Technological University (GTU)

**Subject:** Design Engineering 1B

**Subject Code:** 3140005

**Team ID:** 723566

**Project Type:** Academic Final Year Project

---

# 📷 Screenshots

Add your screenshots here:

```text
screenshots/
├── login.png
├── register.png
├── dashboard.png
├── election.png
├── candidate.png
├── voting.png
├── success.png
├── results.png
└── admin-dashboard.png
```

---

# 🤝 Contributing

Contributions, suggestions, and improvements are welcome.

Feel free to fork the repository and submit pull requests.

---

# 📄 License

This project was developed for educational and academic purposes.

---

# ⭐ Support

If you found this project useful:

⭐ Star this repository

🍴 Fork this repository

📢 Share with others

---

## "Secure Voting Through Blockchain Technology"

### Building Trust, Transparency, and Security in Digital Elections
