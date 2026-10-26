/// Error messages shared by several forms, word for word from
/// docs/06_forms_and_validation.md (note the curly apostrophe in "don’t" and
/// "can’t", and the dash in the "Other" messages).
class ValidationStrings {
  ValidationStrings._();

  // Names, email, phone
  static const fullName = 'Enter your first and last name.';
  static const emailRequired = 'Enter a valid email';
  static const emailInvalid = 'Enter a valid email, like name@example.com';
  static const emailLive = 'Enter a valid email, like name@example.com';
  static const phoneRequired = 'Please enter your phone number.';
  static const phoneInvalid = 'Enter a 9-digit Saudi number, like 5X XXX XXXX';
  static const phoneEdit = phoneInvalid;
  static const linkedin =
      'Enter a LinkedIn profile link, like linkedin.com/in/your-name';

  // Password
  static const passwordRequired = 'Enter your password';
  static const passwordIncorrect = 'Incorrect password. Try again.';
  static const confirmMismatch = 'Passwords don’t match';
  static const ruleLength = 'At least 8 characters';
  static const ruleUpper = 'One uppercase letter';
  static const ruleLower = 'One lowercase letter';
  static const ruleNumber = 'One number';
  static const ruleSpecial = 'One special character (! @ # \$)';

  // Selections
  static const city = 'Please select your city.';
  static const sectors = 'Select at least one sector.';
  static const bioRequired = 'Please write a short bio.';
  static const chooseOne = 'Please choose one.';
  static const required = 'Required';
  static const selectAtLeastOneStage = 'Select at least one stage.';
  static const selectAtLeastOneModel = 'Select at least one commerce model.';
  static const selectAtLeastOne = 'Select at least one.';
  static const selectAtLeastOneOption = 'Select at least one option.';

  // Investor
  static const gainRequired =
      'Tell founders what you are looking for — it can’t be blank.';
  static const bringRequired =
      'Tell founders what you can offer — it can’t be blank.';
  static const roundRange = 'The minimum can’t be more than the maximum.';
  static const roundMinEmpty = 'Enter the minimum amount.';
  static const roundMinLow = 'The minimum must be at least SAR 1,000.';
  static const roundMaxEmpty = 'Enter the maximum amount.';
  static const selectOne = 'Please select one.';

  // Verify email step
  static const verifyWrongEmail = 'This isn’t the email you signed up with.';
  static const verifyNotVerified =
      'Your email isn’t verified yet. Open the link we sent you, then try again.';

  // Toasts used by forms
  static const fixFields = 'Please fix the highlighted fields';
  static const fillRequired = 'Please fix the highlighted fields';
  static const memberNameRequired = 'Please enter their full name.';
  static const memberEmailRequired = 'Please enter their email.';
  static const memberEmailInvalid =
      'Enter a valid email, like name@example.com';
  static const memberRoleRequired = 'Please enter the role.';
  static const memberContributionRequired = 'Please describe the contribution.';
  static const memberIsInvestor =
      'This email belongs to an investor account, which can’t join a team.';
  static const memberDuplicate = 'This person is already on the team.';
  static const founderRowIncomplete =
      'Add your role and contribution: tap the pencil.';
  static const saveMemberFirst = 'Save or cancel the team member first';

  // "Other" write-ins (noun: "sector", "stage", "commerce model", ...)
  /// Under a chip group.
  static String otherChips(String noun) =>
      'Please type your other $noun — it can’t be blank.';

  /// Under a select field.
  static String otherSelect(String noun) =>
      'Tell us your other $noun — it can’t be blank.';

  /// Inside the picker sheet after tapping Done with a blank write-in.
  static String otherSheet(String noun) =>
      'Please type your $noun — it can’t be blank.';

  /// The write-in placeholder inside the picker sheet.
  static String otherSheetHint(String noun) => 'Describe your other $noun';

  // ---- Add / Edit startup (docs/06 section 8) ----
  static const startupName = 'Please enter a startup name.';
  static const startupDescription = 'Please describe your startup.';
  static const startupSector = 'Please select a sector.';
  static const startupStage = 'Please select a stage.';
  static const startupModel = 'Please select a commerce model.';
  static const startupCity = 'Please select your headquarters.';
  static const foundedRequired = 'Please enter the year you were founded.';
  static String foundedRange(int last) =>
      'Enter a year between 1900 and $last.';
  static const websiteInvalid =
      'Enter a valid website, like example.com or https://example.com';
  static const problem = 'Please describe the problem.';
  static const solution = 'Please describe your solution.';
  static const targetCustomers = 'Please describe your target customers.';
  static const marketSize = 'Please enter your target market size.';
  static const marketSizeZero = 'Target market size must be more than 0.';
  static const different = 'Please explain what makes your startup unique.';
  static const growth = 'Please describe your expected growth.';
  static const capital = 'Please enter your current capital.';
  static const revenue =
      'Please enter the expected revenue for all three years.';
  static const funding = 'Please enter the amount you’re raising.';
  static const valuation = 'Please enter your current valuation.';
  static const revenueNow =
      'Please enter your revenue. Enter 0 if you haven’t made any yet.';
  static const burn =
      'Please enter your monthly burn rate. Enter 0 if you earn more than you spend.';
  static const businessModel = 'Please explain your business model.';
  static const raisedEmpty =
      'Please enter an amount. Enter 0 if you haven’t raised anything yet.';
  static const raisedTooMuch =
      'This can’t be more than the amount you’re raising.';
  static const partnerTypes = 'Select at least one partner type.';
  static const supportTypes = 'Select at least one support type.';

  // ---- Valuation calculator ----
  static const calcFunding = 'Enter the amount you want to raise.';
  static const calcEquity = 'Enter a percentage above 0 and below 100.';
  static const calcOwnership = 'Enter a percentage between 0 and 100.';
}
