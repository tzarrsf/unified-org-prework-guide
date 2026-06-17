SalesChannel channel;

List<SalesChannel> existingChannels = [
    SELECT Id
    FROM SalesChannel
    WHERE SalesChannelName = 'Workbench'
    LIMIT 1
];

if (existingChannels.isEmpty()) {
    channel = new SalesChannel(
        SalesChannelName = 'Workbench',
        Description = 'Workbench'
    );
    insert channel;
} else {
    channel = existingChannels[0];
}

System.debug('SalesChannel Id: ' + channel.Id);