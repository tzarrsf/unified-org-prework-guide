// Execute Anonymous

List<SalesChannel> salesChannels = [SELECT Id FROM SalesChannel WHERE SalesChannelName = 'Workbench' LIMIT 1];
List<Pricebook2> standardPricebooks = [SELECT Id FROM Pricebook2 WHERE Name = 'Standard Price Book' LIMIT 1];
List<PricebookEntry> groundPricebookEntries = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'USPS Ground' OR Product2.Name LIKE 'Shipping%' LIMIT 1];
List<OrderDeliveryMethod> groundDeliveryMethods = [SELECT Id FROM OrderDeliveryMethod WHERE Name = 'USPS Ground' OR Name = 'Fedex Ground' LIMIT 1];
List<Product2> shippingChargeProducts = [SELECT Id FROM Product2 WHERE Name = 'USPS Ground' OR Name = 'Shipping Charge Product' LIMIT 1];

Map<Integer, List<String>> rows = new Map<Integer, List<String>>{
    1 => new List<String>{
        '{Your_Sales_Channel_Id}',
        salesChannels.isEmpty() ? 'N/A' : String.valueOf(salesChannels[0].Id),
        salesChannels.isEmpty() ? 'No record found - create a Workbench Sales Channel first.' : '1 record found'
    },
    2 => new List<String>{
        '{Your_Standard_Pricebook_Id}',
        standardPricebooks.isEmpty() ? 'N/A' : String.valueOf(standardPricebooks[0].Id),
        standardPricebooks.isEmpty() ? 'No record found - create or enable the Standard Price Book first.' : '1 record found'
    },
    3 => new List<String>{
        '{Your_Ground_Pricebook_Entry_Id}',
        groundPricebookEntries.isEmpty() ? 'N/A' : String.valueOf(groundPricebookEntries[0].Id),
        groundPricebookEntries.isEmpty() ? 'No record found - create the Ground Pricebook Entry first.' : '1 record found'
    },
    4 => new List<String>{
        '{Your_Ground_Delivery_Method_Id}',
        groundDeliveryMethods.isEmpty() ? 'N/A' : String.valueOf(groundDeliveryMethods[0].Id),
        groundDeliveryMethods.isEmpty() ? 'No record found - create the Ground Delivery Method first.' : '1 record found'
    },
    5 => new List<String>{
        '{Your_Shipping_Charge_Product_Id}',
        shippingChargeProducts.isEmpty() ? 'N/A' : String.valueOf(shippingChargeProducts[0].Id),
        shippingChargeProducts.isEmpty() ? 'No record found - create the Shipping Charge Product first.' : '1 record found'
    },
    6 => new List<String>{
        '{Todays_Date_Zulu_Format}',
        Datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),
        'Generated'
    },
    7 => new List<String>{
        '{Todays_Date_Short_Format}',
        DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0)).formatGMT('yyyy-MM-dd'),
        'Generated'
    }
};

List<String> markdownRows = new List<String>{
    '| Payload Key | Value from SOQL / Apex | Status |',
    '|---|---|---|'
};

List<String> csvRows = new List<String>{
    'Payload Key,Value from SOQL / Apex,Status'
};

for (List<String> rowData : rows.values()) {
    markdownRows.add('| ' + rowData[0] + ' | ' + rowData[1] + ' | ' + rowData[2] + ' |');

    csvRows.add(
        '"' + rowData[0].replace('"', '""') +
        '","' + rowData[1].replace('"', '""') +
        '","' + rowData[2].replace('"', '""') + '"'
    );
}

System.debug('\n' + String.join(markdownRows, '\n'));

ContentVersion contentVersion = new ContentVersion(
    Title = 'Payload_Values',
    PathOnClient = 'Payload_Values.csv',
    VersionData = Blob.valueOf(String.join(csvRows, '\n'))
);

insert contentVersion;

contentVersion = [
    SELECT ContentDocumentId
    FROM ContentVersion
    WHERE Id = :contentVersion.Id
    LIMIT 1
];

System.debug(
    'Download the CSV here: ' +
    URL.getOrgDomainUrl().toExternalForm() +
    '/sfc/servlet.shepherd/document/download/' +
    contentVersion.ContentDocumentId
);