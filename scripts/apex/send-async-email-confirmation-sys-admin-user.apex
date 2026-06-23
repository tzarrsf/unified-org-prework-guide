// Purpose: Send a verification email to an INTERNAL user.
// TODO: ↓ Update this before running
String userEmail = 'tzarr@salesforce.com';

if (String.isBlank(userEmail)) {
    throw new IllegalArgumentException('Email address cannot be blank.');
}

Pattern emailPattern = Pattern.compile(
    '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
);
if (!emailPattern.matcher(userEmail).matches()) {
    throw new IllegalArgumentException('Invalid email address format: ' + userEmail);
}

// Lookup user
List<User> users = [
    SELECT Id
    FROM User
    WHERE Email = :userEmail
    LIMIT 1
];

if (users.isEmpty()) {
    throw new IllegalArgumentException(
        'No User found with email ' + userEmail
    );
}

User targetUser = users[0];

System.debug('User Id: ' + targetUser.Id);

// Internal-user email verification.
// No Experience Cloud site, network, template, or custom start URL.
Boolean sent = System.UserManagement.sendAsyncEmailConfirmation(
    targetUser.Id,
    null, // emailTemplateId - not needed for internal users
    null, // networkId - not needed for internal users
    null  // startUrl - not needed for internal users
);

System.debug('Verification email sent? ' + sent);