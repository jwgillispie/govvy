// lib/data/government_roles.dart
import 'package:flutter/material.dart';

/// Class containing standardized information about various government roles
/// This provides consistent information regardless of API data quality
class GovernmentRoles {
  
  /// Get comprehensive information about a specific government role
  static RoleInfo getRoleInfo(String role) {
    // Normalize the role name to handle variations
    final normalizedRole = _normalizeRoleName(role);
    
    // Return the appropriate role info
    return _roleInfoMap[normalizedRole] ?? _roleInfoMap['default']!;
  }
  
  /// Normalize role names to match our defined categories
  static String _normalizeRoleName(String role) {
    final String normalizedRole = role.trim().toLowerCase();
    
    if (normalizedRole.contains('president')) {
      return 'president';
    } else if (normalizedRole.contains('vice president')) {
      return 'vicePresident';
    } else if (normalizedRole.contains('senator') || 
               normalizedRole.contains('senate') || 
               normalizedRole == 'national_upper') {
      return 'senator';
    } else if (normalizedRole.contains('representative') || 
               normalizedRole.contains('house') || 
               normalizedRole == 'national_lower') {
      return 'representative';
    } else if (normalizedRole.contains('governor')) {
      return 'governor';
    } else if (normalizedRole.contains('lieutenant governor')) {
      return 'lieutenantGovernor';
    } else if (normalizedRole.contains('state senator') || 
               normalizedRole.contains('state_upper')) {
      return 'stateSenator';
    } else if (normalizedRole.contains('state representative') || 
               normalizedRole.contains('state assembly') || 
               normalizedRole.contains('state_lower')) {
      return 'stateRepresentative';
    } else if (normalizedRole.contains('attorney general')) {
      return 'attorneyGeneral';
    } else if (normalizedRole.contains('mayor') || 
               normalizedRole.contains('local_exec')) {
      return 'mayor';
    } else if (normalizedRole.contains('city council') || 
               normalizedRole.contains('councilmember') || 
               normalizedRole.contains('alderman') || 
               normalizedRole == 'local') {
      return 'cityCouncil';
    } else if (normalizedRole.contains('county commissioner') || 
               normalizedRole.contains('county supervisor') || 
               normalizedRole.contains('county council') || 
               normalizedRole == 'county') {
      return 'countyCommissioner';
    } else if (normalizedRole.contains('school board')) {
      return 'schoolBoard';
    } else if (normalizedRole.contains('sheriff')) {
      return 'sheriff';
    } else if (normalizedRole.contains('clerk')) {
      return 'countyClerk';
    } else if (normalizedRole.contains('treasurer')) {
      return 'countyTreasurer';
    } else if (normalizedRole.contains('state')) {
      return 'stateOfficial';
    } else {
      return 'default';
    }
  }

  /// Map of roles to their comprehensive information
  static final Map<String, RoleInfo> _roleInfoMap = {
    'president': RoleInfo(
      title: 'President of the United States',
      level: GovernmentLevel.federal,
      branch: GovernmentBranch.executive,
      description: 'The President is the head of state and head of government of the United States. The President leads the executive branch of the federal government and is the commander-in-chief of the United States Armed Forces.',
      responsibilities: [
        'Serves as commander-in-chief of the armed forces',
        'Signs or vetoes bills passed by Congress',
        'Represents the nation in foreign affairs',
        'Appoints federal judges and executives',
        'Develops federal policies and budgets',
        'Enforces federal laws',
        'Grants pardons and reprieves'
      ],
      termYears: "4",
      termLimit: 'Two terms (8 years) total',
      salary: '\$400,000 annually plus \$50,000 expense allowance',
      totalPositions: 1,
      qualifications: 'Natural-born U.S. citizen, at least 35 years old, resident of the U.S. for at least 14 years',
      electionInfo: 'Elected through the Electoral College system every four years',
      funFacts: [
        'The President lives and works in the White House in Washington, D.C.',
        'The position was established by the U.S. Constitution in 1789',
        'The Presidential Seal features an eagle holding arrows and an olive branch',
        'The President travels on Air Force One',
        'The President receives a pension and Secret Service protection for life'
      ],
      icon: Icons.account_balance,
    ),

    'vicePresident': RoleInfo(
      title: 'Vice President of the United States',
      level: GovernmentLevel.federal,
      branch: GovernmentBranch.executive,
      description: 'The Vice President is the second-highest officer in the executive branch of the U.S. federal government. The Vice President is first in the presidential line of succession and becomes President upon the death, resignation, or removal of the President.',
      responsibilities: [
        'Presides over the Senate and casts tie-breaking votes',
        'Assists and advises the President',
        'Represents the President at ceremonial functions',
        'Assumes presidency if the President is unable to serve',
        'Serves on the National Security Council'
      ],
      termYears: "4",
      termLimit: 'No constitutional limit, but typically serves with President',
      salary: '\$235,100 annually',
      totalPositions: 1,
      qualifications: 'Same as President: natural-born U.S. citizen, at least 35 years old, resident of the U.S. for at least 14 years',
      electionInfo: 'Elected on the same ticket as the President every four years',
      funFacts: [
        'The Vice President resides at Number One Observatory Circle on the grounds of the U.S. Naval Observatory',
        'The office was established by the U.S. Constitution in 1789',
        'The VP breaks ties in the Senate but otherwise cannot vote',
        'John Adams was the first Vice President',
        '14 Vice Presidents have gone on to become President'
      ],
      icon: Icons.account_balance_outlined,
    ),
    
    'senator': RoleInfo(
      title: 'United States Senator',
      level: GovernmentLevel.federal,
      branch: GovernmentBranch.legislative,
      description: 'U.S. Senators serve in the Senate, the upper chamber of Congress. Each state elects two Senators, regardless of population, for a total of 100 senators nationwide.',
      responsibilities: [
        'Creates and passes federal legislation',
        'Confirms presidential appointments',
        'Ratifies treaties with foreign countries',
        'Conducts impeachment trials',
        'Approves federal budgets',
        'Investigates matters of national interest',
        'Represents state interests at the federal level'
      ],
      termYears: "6",
      termLimit: 'No term limits',
      salary: '\$174,000 annually',
      totalPositions: 100,
      qualifications: 'At least 30 years old, U.S. citizen for 9+ years, resident of the state they represent',
      electionInfo: 'Elections staggered so that approximately one-third of Senate seats are up for election every two years',
      funFacts: [
        'The Senate is sometimes called the "upper house" or "most deliberative body"',
        'Vice President serves as President of the Senate',
        'Senators represented states even before citizens could vote for them directly',
        'The Senate Chamber is located in the north wing of the U.S. Capitol',
        'Senate seats were originally appointed by state legislatures until the 17th Amendment in 1913'
      ],
      icon: Icons.gavel,
    ),
    
    'representative': RoleInfo(
      title: 'United States Representative',
      level: GovernmentLevel.federal,
      branch: GovernmentBranch.legislative,
      description: 'U.S. Representatives serve in the House of Representatives, the lower chamber of Congress. Each representative serves a specific congressional district, with the number of representatives per state based on population.',
      responsibilities: [
        'Drafts and passes federal legislation',
        'Has exclusive power to initiate revenue bills',
        'Approves federal budgets',
        'Can impeach federal officials',
        'Elects the President in electoral college ties',
        'Conducts investigations and oversight',
        'Represents district constituents at the federal level'
      ],
      termYears: "2",
      termLimit: 'No term limits',
      salary: '\$174,000 annually',
      totalPositions: 435,
      qualifications: 'At least 25 years old, U.S. citizen for 7+ years, resident of the state they represent',
      electionInfo: 'All seats are up for election every two years',
      funFacts: [
        'The House is sometimes called the "people\'s house"',
        'The Speaker of the House is second in line for presidency after the Vice President',
        'The House Chamber is located in the south wing of the U.S. Capitol',
        'Representatives are sometimes called "congressmen/congresswomen" or "members of Congress"',
        'There have been 435 voting members since 1913 (plus non-voting delegates)'
      ],
      icon: Icons.domain,
    ),
    
    'governor': RoleInfo(
      title: 'State Governor',
      level: GovernmentLevel.state,
      branch: GovernmentBranch.executive,
      description: 'The Governor is the head of the executive branch in state government. As the chief executive officer of the state, the Governor is responsible for implementing state laws and overseeing the operation of the state government.',
      responsibilities: [
        'Signs or vetoes bills passed by state legislature',
        'Prepares and administers state budget',
        'Appoints state officials and judges',
        'Commands state National Guard',
        'Grants pardons and reprieves (in most states)',
        'Oversees state agencies and departments',
        'Represents the state in dealings with the federal government'
      ],
      termYears: "4",
      termLimit: 'Varies by state - many have 2-term limits',
      salary: 'Ranges from \$70,000 to \$225,000 depending on the state',
      totalPositions: 50,
      qualifications: 'Varies by state, typically U.S. citizen, state resident, minimum age (often 30)',
      electionInfo: 'Most governors are elected in even-numbered years between presidential elections',
      funFacts: [
        'Governors reside in official governor\'s mansions',
        'The National Governors Association is their collective organization',
        'Some governors have gone on to become President',
        'Vermont and New Hampshire are the only states with 2-year gubernatorial terms',
        'Governors have varying degrees of veto and pardon powers depending on the state'
      ],
      icon: Icons.account_balance_wallet,
    ),
    
    'lieutenantGovernor': RoleInfo(
      title: 'Lieutenant Governor',
      level: GovernmentLevel.state,
      branch: GovernmentBranch.executive,
      description: 'The Lieutenant Governor is the second-highest ranking official in state government and first in the line of succession to the governorship. Their specific duties and powers vary significantly from state to state.',
      responsibilities: [
        'Assumes governorship if governor is unable to serve',
        'Presides over state senate (in many states)',
        'Casts tie-breaking votes in state senate (in many states)',
        'Serves on various state boards and commissions',
        'Represents the state at ceremonial functions',
        'Advocates for specific policy initiatives (varies by state)',
        'Assists the governor with various duties'
      ],
      termYears: "4",
      termLimit: 'Varies by state',
      salary: 'Ranges from \$25,000 to \$150,000 depending on the state',
      totalPositions: 45,
      qualifications: 'Similar to governor: U.S. citizen, state resident, minimum age',
      electionInfo: 'In most states, elected on same ticket as governor; in some, elected separately',
      funFacts: [
        'Five states do not have a lieutenant governor (AZ, ME, NH, OR, WY)',
        'In some states, the position is part-time',
        'Tennessee and West Virginia have the Senate President serve as lieutenant governor',
        'In NJ, the lieutenant governor cannot simultaneously serve as a department head',
        'Alaska was the last state to create the position (in 1970)'
      ],
      icon: Icons.account_balance_wallet_outlined,
    ),
    
    'stateSenator': RoleInfo(
      title: 'State Senator',
      level: GovernmentLevel.state,
      branch: GovernmentBranch.legislative,
      description: 'State Senators serve in the upper chamber of state legislatures. They draft and vote on bills that may become state law, approve state budgets, and provide oversight of state agencies.',
      responsibilities: [
        'Drafts and votes on state legislation',
        'Approves state budgets',
        'Confirms gubernatorial appointments (in most states)',
        'Conducts oversight of state agencies',
        'Represents constituent interests at the state level',
        'Serves on legislative committees',
        'Responds to constituent concerns'
      ],
      termYears: "4",
      termLimit: 'Varies by state - many have term limits',
      salary: 'Ranges from \$0 to \$110,000 depending on the state',
      totalPositions: 'Varies by state, typically 20-67 members',
      qualifications: 'Varies by state, typically state resident, minimum age requirement',
      electionInfo: 'Elections typically staggered so that half the seats are up for election at a time',
      funFacts: [
        'Nebraska is the only state without a state senate (unicameral legislature)',
        'State senates generally have fewer members than state houses/assemblies',
        'In some states, the position is part-time or even unpaid',
        'Terms are typically longer than state house/assembly terms',
        'Many state senators go on to run for higher office'
      ],
      icon: Icons.account_balance,
    ),
    
    'stateRepresentative': RoleInfo(
      title: 'State Representative',
      level: GovernmentLevel.state,
      branch: GovernmentBranch.legislative,
      description: 'State Representatives (also called Assemblymembers in some states) serve in the lower chamber of state legislatures. They draft and vote on bills that may become state law, approve state budgets, and represent the concerns of their districts.',
      responsibilities: [
        'Drafts and votes on state legislation',
        'Approves state budgets',
        'Initiates revenue bills (in most states)',
        'Conducts oversight of state agencies',
        'Represents district interests at the state level',
        'Serves on legislative committees',
        'Addresses constituent needs and concerns'
      ],
      termYears: "2",
      termLimit: 'Varies by state - many have term limits',
      salary: 'Ranges from \$0 to \$110,000 depending on the state',
      totalPositions: 'Varies by state, typically 80-400 members',
      qualifications: 'Varies by state, typically state resident, minimum age requirement',
      electionInfo: 'Most states hold elections for all seats every two years',
      funFacts: [
        'New Hampshire has the largest state house with 400 members',
        'Many state houses/assemblies use proportional representation like the U.S. House',
        'In some states, the position is part-time or even unpaid',
        'Districts are typically smaller than state senate districts',
        'State representatives often advance to state senate or other higher offices'
      ],
      icon: Icons.domain,
    ),
    
    'attorneyGeneral': RoleInfo(
      title: 'State Attorney General',
      level: GovernmentLevel.state,
      branch: GovernmentBranch.executive,
      description: 'The State Attorney General is the chief legal officer of the state. The Attorney General provides legal advice to state agencies, represents the state in legal matters, enforces state laws, and protects the public interest.',
      responsibilities: [
        'Provides legal advice to the governor and state agencies',
        'Represents the state in legal proceedings',
        'Issues formal legal opinions on state law',
        'Enforces consumer protection laws',
        'Prosecutes certain criminal cases',
        'Investigates violations of state law',
        'Protects the public interest in charitable trusts'
      ],
      termYears: "4",
      termLimit: 'Varies by state',
      salary: 'Ranges from \$60,000 to \$190,000 depending on the state',
      totalPositions: 50,
      qualifications: 'Usually must be licensed to practice law in the state; other requirements vary',
      electionInfo: 'Elected in 43 states; appointed by governor or legislature in others',
      funFacts: [
        'The National Association of Attorneys General (NAAG) was founded in 1907',
        'State AGs often collaborate on multi-state lawsuits',
        'Many U.S. Senators and Governors previously served as state Attorneys General',
        'The position has become increasingly political in recent decades',
        'Some state AGs have broad criminal prosecution authority, while others have limited power'
      ],
      icon: Icons.gavel,
    ),
    
    'mayor': RoleInfo(
      title: 'Mayor',
      level: GovernmentLevel.local,
      branch: GovernmentBranch.executive,
      description: 'The Mayor is the chief executive officer of a city or town. Depending on the form of government, mayors may have varying levels of authority, from largely ceremonial to strong executive powers.',
      responsibilities: [
        'Oversees city departments and operations',
        'Proposes annual city budget',
        'Enforces city ordinances and policies',
        'Represents the city officially',
        'Appoints department heads (in many cities)',
        'Presides over city council meetings (in some cities)',
        'Develops and implements city initiatives'
      ],
      termYears: '2-4 years, varies by city',
      termLimit: 'Varies by city',
      salary: 'Ranges from unpaid to \$250,000+ for major cities',
      totalPositions: 'Over 19,000 mayors in the U.S.',
      qualifications: 'Typically city resident, registered voter, minimum age',
      electionInfo: 'Many cities have nonpartisan elections; timing varies widely',
      funFacts: [
        'Some cities have "weak mayor" systems where the mayor has limited power',
        'Other cities have "strong mayor" systems with significant executive authority',
        'Some cities have city managers who handle day-to-day operations',
        'The term "mayor" comes from the Latin word "maior" meaning "greater"',
        'The U.S. Conference of Mayors represents cities with populations over 30,000'
      ],
      icon: Icons.location_city,
    ),
    
    'cityCouncil': RoleInfo(
      title: 'City Council Member',
      level: GovernmentLevel.local,
      branch: GovernmentBranch.legislative,
      description: 'City Council Members (sometimes called Aldermen, Selectmen, or Commissioners) serve on the legislative body of a city. They establish local laws, approve city budgets, and determine city policies.',
      responsibilities: [
        'Drafts and passes local ordinances and resolutions',
        'Approves city budget',
        'Sets property tax rates and service fees',
        'Reviews land use, zoning, and development',
        'Approves contracts and major expenditures',
        'Represents district or city constituents',
        'Provides oversight of city departments'
      ],
      termYears: '2-4 years, varies by city',
      termLimit: 'Varies by city',
      salary: 'Ranges from unpaid to \$100,000+ for major cities',
      totalPositions: 'Varies widely by city, typically 5-50 members',
      qualifications: 'Typically city resident, registered voter, sometimes district residency',
      electionInfo: 'Many councils have either district-based or at-large members, or a combination',
      funFacts: [
        'Many city councils have both ward/district and at-large members',
        'The position is part-time in most cities',
        'The National League of Cities advocates for city governments',
        'Council structure varies dramatically based on city size and form of government',
        'Council members often serve on various city boards and commissions'
      ],
      icon: Icons.groups,
    ),
    
    'countyCommissioner': RoleInfo(
      title: 'County Commissioner',
      level: GovernmentLevel.local,
      branch: GovernmentBranch.both,
      description: 'County Commissioners (sometimes called Supervisors, Councilmembers, or Judges in some states) serve on the governing board of a county. They often have both legislative and executive responsibilities, making them unique in American government.',
      responsibilities: [
        'Establishes county policies and ordinances',
        'Approves county budget',
        'Sets county property tax rates',
        'Oversees county roads and infrastructure',
        'Manages county facilities and property',
        'Approves contracts and expenditures',
        'Coordinates with other local governments'
      ],
      termYears: '4 years in most counties',
      termLimit: 'Varies by county',
      salary: 'Ranges from a few thousand to over \$100,000 for large counties',
      totalPositions: 'Typically 3-7 per county',
      qualifications: 'County resident, registered voter, sometimes district residency',
      electionInfo: 'May be partisan or nonpartisan depending on state and county',
      funFacts: [
        'County commissions are called different names in different states',
        'Some counties have appointed administrators who handle day-to-day operations',
        'County government predates the founding of the United States',
        'Counties are the largest subdivision of states',
        'The National Association of Counties (NACo) represents county governments'
      ],
      icon: Icons.business,
    ),
    
    'schoolBoard': RoleInfo(
      title: 'School Board Member',
      level: GovernmentLevel.local,
      branch: GovernmentBranch.both,
      description: 'School Board Members serve on the governing body for school districts. They set educational policy, approve school budgets, and oversee district operations, while leaving day-to-day management to the superintendent and staff.',
      responsibilities: [
        'Sets district educational policies and goals',
        'Approves school district budget',
        'Hires and evaluates the superintendent',
        'Approves curriculum and textbooks',
        'Establishes district boundaries',
        'Oversees school construction and maintenance',
        'Responds to community educational concerns'
      ],
      termYears: '3-4 years, varies by district',
      termLimit: 'Varies by district',
      salary: 'Most are unpaid or receive a small stipend',
      totalPositions: 'Typically 5-9 per district',
      qualifications: 'District resident, minimum age, sometimes specific district residency',
      electionInfo: 'Most school board elections are nonpartisan',
      funFacts: [
        'School boards manage the largest portion of local government expenditures',
        'There are approximately 13,800 school districts in the U.S.',
        'Most school board positions are part-time volunteer positions',
        'School boards date back to the Massachusetts Bay Colony in the 1700s',
        'The National School Boards Association represents these officials'
      ],
      icon: Icons.school,
    ),
    
    'sheriff': RoleInfo(
      title: 'County Sheriff',
      level: GovernmentLevel.local,
      branch: GovernmentBranch.executive,
      description: 'The Sheriff is the chief law enforcement officer of a county. Sheriffs and their deputies provide police services, operate county jails, serve court papers, and provide courthouse security.',
      responsibilities: [
        'Enforces state laws and county ordinances',
        'Operates the county jail system',
        'Serves court papers and executes court orders',
        'Provides security for county courts',
        'Patrols unincorporated areas',
        'Investigates crimes in the county',
        'Conducts search and rescue operations'
      ],
      termYears: '4 years in most counties',
      termLimit: 'Varies by county',
      salary: 'Ranges from \$40,000 to \$200,000+ depending on county',
      totalPositions: 'Approximately 3,000 sheriffs in the U.S.',
      qualifications: 'Varies by state; often includes law enforcement certification, county residency, minimum age',
      electionInfo: 'Most sheriffs are directly elected',
      funFacts: [
        'The office of sheriff is over 1,000 years old, originating in England',
        'Sheriffs are elected in 46 states',
        'The National Sheriffs\' Association was founded in 1940',
        'Most states constitutionally define the office of sheriff',
        'In some states, sheriffs also collect taxes or conduct auctions'
      ],
      icon: Icons.local_police,
    ),
    
    'countyClerk': RoleInfo(
      title: 'County Clerk',
      level: GovernmentLevel.local,
      branch: GovernmentBranch.executive,
      description: 'The County Clerk maintains official county records, issues licenses, conducts elections, and provides administrative support to county government and courts.',
      responsibilities: [
        'Maintains vital records (births, deaths, marriages)',
        'Issues marriage licenses and business registrations',
        'Serves as chief election official in many counties',
        'Records property deeds and mortgages',
        'Maintains county commission records',
        'Processes passport applications in some counties',
        'Serves as clerk of the county court in some states'
      ],
      termYears: '4 years in most counties',
      termLimit: 'Varies by county',
      salary: 'Ranges from \$40,000 to \$150,000 depending on county',
      totalPositions: 'One per county in most states',
      qualifications: 'County resident, registered voter, minimum age',
      electionInfo: 'Elected in most counties, appointed in some',
      funFacts: [
        'One of the oldest governmental positions in the U.S.',
        'In some states, the position is combined with other functions',
        'County clerks often have different titles in different states',
        'Some county clerks also serve as the county recorder',
        'The International Association of Clerks, Recorders, Election Officials and Treasurers represents county clerks'
      ],
      icon: Icons.folder,
    ),
    
    'countyTreasurer': RoleInfo(
      title: 'County Treasurer',
      level: GovernmentLevel.local,
      branch: GovernmentBranch.executive,
      description: 'The County Treasurer is the chief financial officer of the county. The Treasurer collects taxes, manages county funds, invests county money, and disburses funds according to law and county commission directives.',
      responsibilities: [
        'Collects property taxes and other revenues',
        'Manages county funds and investments',
        'Disburses money for county expenditures',
        'Maintains records of county finances',
        'Issues financial reports to county commission',
        'Conducts tax sales for delinquent properties',
        'Distributes tax revenues to other local governments'
      ],
      termYears: '4 years in most counties',
      termLimit: 'Varies by county',
      salary: 'Ranges from \$40,000 to \$150,000 depending on county',
      totalPositions: 'One per county in most states',
      qualifications: 'County resident, registered voter, minimum age, sometimes financial experience',
      electionInfo: 'Elected in most counties, appointed in some',
      funFacts: [
        'County treasurers collectively manage billions in public funds',
        'The position dates back to colonial America',
        'In some counties, the treasurer also serves as tax collector',
        'County treasurers often manage funds for school districts and other local governments',
        'The National Association of County Collectors, Treasurers and Finance Officers represents these officials'
      ],
      icon: Icons.account_balance,
    ),
    
    'stateOfficial': RoleInfo(
      title: 'State Government Official',
      level: GovernmentLevel.state,
      branch: GovernmentBranch.various,
      description: 'State officials work in various capacities within state government, including elected, appointed, and civil service positions. They implement state laws and policies, manage state programs, and provide services to state residents.',
      responsibilities: [
        'Implements state laws and policies',
        'Manages state programs and services',
        'Oversees state departments and agencies',
        'Allocates state resources',
        'Represents state interests',
        'Coordinates with federal and local governments',
        'Addresses constituent needs and concerns'
      ],
      termYears: 'Varies by position',
      termLimit: 'Varies by position',
      salary: 'Varies widely by position and state',
      totalPositions: 'Thousands per state',
      qualifications: 'Varies by position',
      electionInfo: 'Some elected, most appointed or hired through civil service',
      funFacts: [
        'States employ about 5 million people collectively',
        'State governments have grown significantly since the New Deal era',
        'States administer many federal programs like Medicaid',
        'States have significant autonomy under the federal system',
        'State governments vary widely in size, structure, and responsibilities'
      ],
      icon: Icons.account_balance_wallet,
    ),
    
    'default': RoleInfo(
      title: 'Government Official',
      level: GovernmentLevel.various,
      branch: GovernmentBranch.various,
      description: 'Government officials serve in various capacities at the federal, state, and local levels. They implement laws, manage government operations, represent constituent interests, and provide public services.',
      responsibilities: [
        'Implements laws and policies',
        'Manages government programs and services',
        'Represents constituents',
        'Allocates public resources',
        'Collaborates with other government entities',
        'Addresses community needs',
        'Ensures public accountability'
      ],
      termYears: 'Varies by position',
      termLimit: 'Varies by position',
      salary: 'Varies by position and jurisdiction',
      totalPositions: 'Varies by position',
      qualifications: 'Typically includes citizenship, residency, and age requirements',
      electionInfo: 'Elected, appointed, or hired depending on position',
      funFacts: [
        'The U.S. has more than 90,000 governmental units',
        'About 15% of the U.S. workforce is employed in government',
        'Local government employs more people than state and federal combined',
        'The structure of government varies widely across jurisdictions',
        'Many local government positions are part-time or volunteer'
      ],
      icon: Icons.public,
    ),
  };
}

/// Enumeration of government levels
enum GovernmentLevel {
  federal,
  state,
  local,
  various
}

/// Enumeration of government branches
enum GovernmentBranch {
  executive,
  legislative,
  judicial,
  both,
  various
}

/// Class to hold comprehensive information about a government role
class RoleInfo {
  final String title;
  final GovernmentLevel level;
  final GovernmentBranch branch;
  final String description;
  final List<String> responsibilities;
  final String termYears;
  final String termLimit;
  final String salary;
  final dynamic totalPositions;
  final String qualifications;
  final String electionInfo;
  final List<String> funFacts;
  final IconData icon;
  
  RoleInfo({
    required this.title,
    required this.level,
    required this.branch,
    required this.description,
    required this.responsibilities,
    required this.termYears,
    required this.termLimit,
    required this.salary,
    required this.totalPositions,
    required this.qualifications,
    required this.electionInfo,
    required this.funFacts,
    required this.icon,
  });
  
  /// Get the government level as a display string
  String get levelString {
    switch (level) {
      case GovernmentLevel.federal:
        return 'Federal';
      case GovernmentLevel.state:
        return 'State';
      case GovernmentLevel.local:
        return 'Local';
      case GovernmentLevel.various:
        return 'Various';
    }
  }
  
  /// Get the government branch as a display string
  String get branchString {
    switch (branch) {
      case GovernmentBranch.executive:
        return 'Executive';
      case GovernmentBranch.legislative:
        return 'Legislative';
      case GovernmentBranch.judicial:
        return 'Judicial';
      case GovernmentBranch.both:
        return 'Executive & Legislative';
      case GovernmentBranch.various:
        return 'Various';
    }
  }
}