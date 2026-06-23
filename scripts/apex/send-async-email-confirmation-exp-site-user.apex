// Purpose: Send a verification email to an Experience Cloud user, resolved from Contact first.

String contactFirstName       = 'Lauren';
String contactLastName        = 'Bailey';
String userEmail              = 'tzarr@salesforce.com';
String templateDeveloperName  = 'Async_Email_Verification';
String experienceCloudSiteName = 'B2B Store';

if (String.isBlank(contactFirstName) || String.isBlank(contactLastName) || String.isBlank(userEmail)) {
    throw new IllegalArgumentException('First name, last name, and user email cannot be blank.');
}

if (String.isBlank(experienceCloudSiteName)) {
    throw new IllegalArgumentException('Experience Cloud site name cannot be blank.');
}

Pattern emailPattern = Pattern.compile('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$');
if (!emailPattern.matcher(userEmail).matches()) {
    throw new IllegalArgumentException('Invalid email address format: ' + userEmail);
}

// Look up the Contact first.
List<Contact> contacts = [
    SELECT Id, FirstName, LastName
    FROM Contact
    WHERE FirstName = :contactFirstName
      AND LastName  = :contactLastName
    LIMIT 1
];

if (contacts.isEmpty()) {
    throw new IllegalArgumentException(
        'No Contact found for First Name="' + contactFirstName +
        '", Last Name="' + contactLastName + '".'
    );
}

Contact targetContact = contacts[0];

// Find the underlying User for that Contact.
List<User> users = [
    SELECT Id, ContactId, UserType, IsActive, Email
    FROM User
    WHERE ContactId = :targetContact.Id
    AND Email = :userEmail
    LIMIT 1
];

if (users.isEmpty()) {
    throw new IllegalArgumentException(
        'No User found for Contact Id ' + targetContact.Id +
        ' and Email ' + userEmail +
        '. This contact does not appear to have an Experience Cloud user.'
    );
}

User targetUser = users[0];

// Ensure this is an Experience Cloud user, not an internal user.
if (String.isBlank(targetUser.UserType) || targetUser.UserType == 'Standard' || targetUser.ContactId == null) {
    throw new IllegalArgumentException(
        'The matched User is an internal user (UserType=' + targetUser.UserType +
        '). This script only supports Experience Cloud users.'
    );
}

Id emailTemplateId = null;
if (String.isNotBlank(templateDeveloperName)) {
    List<EmailTemplate> templates = [
        SELECT Id
        FROM EmailTemplate
        WHERE DeveloperName = :templateDeveloperName
        LIMIT 1
    ];

    if (templates.isEmpty()) {
        throw new IllegalArgumentException('Email Template not found: ' + templateDeveloperName);
    }

    emailTemplateId = templates[0].Id;
}

List<Network> networks = [
    SELECT Id, Name, UrlPathPrefix
    FROM Network
    WHERE Name = :experienceCloudSiteName
    LIMIT 1
];

if (networks.isEmpty()) {
    throw new IllegalArgumentException('Network not found: ' + experienceCloudSiteName);
}

Network targetNetwork = networks[0];
Id networkId = targetNetwork.Id;

// Salesforce uses this as the site-relative start path for the Experience Cloud user.
String startUrl = targetNetwork.UrlPathPrefix;

if (String.isBlank(startUrl)) {
    throw new IllegalArgumentException(
        'Could not determine startUrl dynamically from the Experience Cloud site.'
    );
}

System.debug('Contact Id: ' + targetContact.Id);
System.debug('User Id: ' + targetUser.Id);
System.debug('User Type: ' + targetUser.UserType);
System.debug('Template Id: ' + emailTemplateId);
System.debug('Network Id: ' + networkId);
System.debug('Start URL: ' + startUrl);

Boolean sent = System.UserManagement.sendAsyncEmailConfirmation(
    targetUser.Id,
    emailTemplateId,
    networkId,
    startUrl
);

System.debug('Verification email sent? ' + sent);