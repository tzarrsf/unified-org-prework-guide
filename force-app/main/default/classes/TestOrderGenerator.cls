/**
 * @description       : 
 * @author            : Tom Zarr
 * @group             : 
 * @last modified on  : 05-30-2026
 * @last modified by  : Tom Zarr
**/
public with sharing class TestOrderGenerator {

    public static void run() {

        // Queries

        List<SalesChannel> salesChannels = [SELECT Id FROM SalesChannel WHERE SalesChannelName = 'Workbench' LIMIT 1];
        List<Pricebook2> standardPricebooks = [SELECT Id FROM Pricebook2 WHERE Name = 'Standard Price Book' LIMIT 1];
        List<PricebookEntry> groundPricebookEntries = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'USPS Ground' OR Product2.Name LIKE 'Shipping%' LIMIT 1];
        List<OrderDeliveryMethod> groundDeliveryMethods = [SELECT Id FROM OrderDeliveryMethod WHERE Name = 'USPS Ground' OR Name = 'Fedex Ground' LIMIT 1];
        List<Product2> shippingChargeProducts = [SELECT Id FROM Product2 WHERE Name = 'USPS Ground' OR Name = 'Shipping Charge Product' LIMIT 1];

        // API Version

        String apiVersion = 'v64';

        // Replacement Map

        Map<String,String> replacements = new Map<String,String>{
            '{Your_Sales_Channel_Id}' =>
                salesChannels.isEmpty() ? null : String.valueOf(salesChannels[0].Id),

            '{Your_Standard_Pricebook_Id}' =>
                standardPricebooks.isEmpty() ? null : String.valueOf(standardPricebooks[0].Id),

            '{Your_Ground_Pricebook_Entry_Id}' =>
                groundPricebookEntries.isEmpty() ? null : String.valueOf(groundPricebookEntries[0].Id),

            '{Your_Ground_Delivery_Method_Id}' =>
                groundDeliveryMethods.isEmpty() ? null : String.valueOf(groundDeliveryMethods[0].Id),

            '{Your_Shipping_Charge_Product_Id}' =>
                shippingChargeProducts.isEmpty() ? null : String.valueOf(shippingChargeProducts[0].Id),

            '{Todays_Date_Zulu_Format}' =>
                Datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),

            '{Todays_Date_Short_Format}' =>
                DateTime.newInstance(
                    Date.today(),
                    Time.newInstance(0, 0, 0, 0)
                ).formatGMT('yyyy-MM-dd'),

            '{apiVersion}' => apiVersion
        };

        // JSON Template from Static Resource

        StaticResource staticResource = [
            SELECT Body
            FROM StaticResource
            WHERE Name = 'ConnectedCommerceTestOrderTemplate'
            LIMIT 1
        ];

        String jsonTemplate = staticResource.Body.toString();

        // Replacement

        String populatedJson = jsonTemplate;

        for (String token : replacements.keySet()) {
            String value = replacements.get(token);

            if (value != null) {
                populatedJson = populatedJson.replace(token, value);
            }
        }

        // Create File

        ContentVersion contentVersion = new ContentVersion(
            Title = 'ConnectedCommerce-TestOrder_' + apiVersion + '_withValues',
            PathOnClient = 'ConnectedCommerce-TestOrder_' + apiVersion + '_withValues.json',
            VersionData = Blob.valueOf(populatedJson)
        );

        insert contentVersion;

        contentVersion = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersion.Id
            LIMIT 1
        ];

        // Download Link

        System.debug(
            'Download the JSON here: ' +
            URL.getOrgDomainUrl().toExternalForm() +
            '/sfc/servlet.shepherd/document/download/' +
            contentVersion.ContentDocumentId
        );
    }
}