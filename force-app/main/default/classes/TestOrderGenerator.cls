/**
 * @description       : 
 * @author            : Tom Zarr
 * @group             : 
 * @last modified on  : 06-17-2026
 * @last modified by  : Tom Zarr
**/
public with sharing class TestOrderGenerator {

    private static Id getOrCreateWorkbenchSalesChannelId() {
        List<SalesChannel> channels = [
            SELECT Id, SalesChannelName, Description
            FROM SalesChannel
            WHERE SalesChannelName = 'Workbench'
            LIMIT 10
        ];

        for (SalesChannel sc : channels) {
            if (sc.Description == 'Workbench') {
                return sc.Id;
            }
        }

        System.debug(LoggingLevel.WARN,
            'SalesChannel "Workbench" with Description "Workbench" not found. Creating it now.'
        );

        SalesChannel workbenchChannel = new SalesChannel(
            SalesChannelName = 'Workbench',
            Description = 'Workbench'
        );
        insert workbenchChannel;

        return workbenchChannel.Id;
    }

    private static Id getOrCreateShippingProductId() {
        List<Product2> products = [
            SELECT Id, Name, ProductCode, Family, IsActive
            FROM Product2
            WHERE ProductCode = 'USPS_Ground'
            LIMIT 10
        ];

        for (Product2 p : products) {
            if (p.Name == 'USPS Ground' &&
                p.ProductCode == 'USPS_Ground' &&
                p.Family == 'Shipping' &&
                p.IsActive == true) {
                return p.Id;
            }
        }

        System.debug(LoggingLevel.WARN,
            'Product "USPS Ground" not found. Creating it now.'
        );

        Product2 shippingProduct = new Product2(
            Name = 'USPS Ground',
            ProductCode = 'USPS_Ground',
            Family = 'Shipping',
            IsActive = true
        );
        insert shippingProduct;

        return shippingProduct.Id;
    }

    private static Id getOrCreateStandardPricebookId() {
        List<Pricebook2> standardPricebooks = [
            SELECT Id, IsStandard, IsActive
            FROM Pricebook2
            WHERE IsStandard = true
            LIMIT 1
        ];

        if (!standardPricebooks.isEmpty()) {
            if (!standardPricebooks[0].IsActive) {
                standardPricebooks[0].IsActive = true;
                update standardPricebooks[0];
            }
            return standardPricebooks[0].Id;
        }

        throw new AuraHandledException('Standard Price Book was not found.');
    }

    private static Id getOrCreateGroundDeliveryMethodId(Id shippingProductId) {
        List<OrderDeliveryMethod> deliveryMethods = [
            SELECT Id, Name, ReferenceNumber, Carrier, ClassOfService, ProductId, IsActive
            FROM OrderDeliveryMethod
            WHERE Name = 'USPS Ground'
            LIMIT 10
        ];

        for (OrderDeliveryMethod odm : deliveryMethods) {
            if (odm.ReferenceNumber == 'USPS_Ground' &&
                odm.Carrier == 'USPS' &&
                odm.ClassOfService == 'Ground' &&
                odm.ProductId == shippingProductId &&
                odm.IsActive == true) {
                return odm.Id;
            }
        }

        System.debug(LoggingLevel.WARN,
            'OrderDeliveryMethod "USPS Ground" not found. Creating it now.'
        );

        OrderDeliveryMethod deliveryMethod = new OrderDeliveryMethod(
            Name = 'USPS Ground',
            ReferenceNumber = 'USPS_Ground',
            Carrier = 'USPS',
            ClassOfService = 'Ground',
            ProductId = shippingProductId,
            IsActive = true
        );
        insert deliveryMethod;

        return deliveryMethod.Id;
    }

    private static Id getOrCreateGroundPricebookEntryId(Id standardPricebookId, Id shippingProductId) {
        List<PricebookEntry> entries = [
            SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive
            FROM PricebookEntry
            WHERE Pricebook2Id = :standardPricebookId
            AND Product2Id = :shippingProductId
            LIMIT 10
        ];

        for (PricebookEntry pbe : entries) {
            if (pbe.IsActive == true) {
                return pbe.Id;
            }
        }

        System.debug(LoggingLevel.WARN,
            'PricebookEntry for "USPS Ground" not found. Creating it now.'
        );

        PricebookEntry entry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = shippingProductId,
            UnitPrice = 0,
            IsActive = true
        );
        insert entry;

        return entry.Id;
    }

    public static void run() {

        // Queries / Create if needed

        Id salesChannelId = getOrCreateWorkbenchSalesChannelId();
        Id shippingProductId = getOrCreateShippingProductId();
        Id standardPricebookId = getOrCreateStandardPricebookId();

        Id groundDeliveryMethodId = getOrCreateGroundDeliveryMethodId(shippingProductId);
        Id groundPricebookEntryId = getOrCreateGroundPricebookEntryId(standardPricebookId, shippingProductId);

        // API Version

        String apiVersion = 'v66.0';

        // Replacement Map

        Map<String,String> replacements = new Map<String,String>{
            '{Your_Sales_Channel_Id}' =>
                String.valueOf(salesChannelId),

            '{Your_Standard_Pricebook_Id}' =>
                String.valueOf(standardPricebookId),

            '{Your_Ground_Pricebook_Entry_Id}' =>
                String.valueOf(groundPricebookEntryId),

            '{Your_Ground_Delivery_Method_Id}' =>
                String.valueOf(groundDeliveryMethodId),

            '{Your_Shipping_Charge_Product_Id}' =>
                String.valueOf(shippingProductId),

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
            Title = 'ConnectedCommerce-TestOrder_' + apiVersion + '_withValuesFromOptionA',
            PathOnClient = 'ConnectedCommerce-TestOrder_' + apiVersion + '_withValuesFromOptionA.json',
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