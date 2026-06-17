// Get Standard Price Book
Pricebook2 standardPb = [
    SELECT Id, IsActive
    FROM Pricebook2
    WHERE IsStandard = true
    LIMIT 1
];

if (!standardPb.IsActive) {
    standardPb.IsActive = true;
    update standardPb;
}

// Get or create USPS Ground product
List<Product2> products = [
    SELECT Id
    FROM Product2
    WHERE ProductCode = 'USPS_Ground'
    LIMIT 1
];

Product2 shippingProduct;

if (products.isEmpty()) {
    shippingProduct = new Product2(
        Name = 'USPS Ground',
        ProductCode = 'USPS_Ground',
        Family = 'Shipping',
        IsActive = true
    );
    insert shippingProduct;
    System.debug('Created Product2: ' + shippingProduct.Id);
} else {
    shippingProduct = products[0];
}

// Get or create PricebookEntry
List<PricebookEntry> entries = [
    SELECT Id
    FROM PricebookEntry
    WHERE Pricebook2Id = :standardPb.Id
    AND Product2Id = :shippingProduct.Id
    LIMIT 1
];

PricebookEntry pbe;

if (entries.isEmpty()) {
    pbe = new PricebookEntry(
        Pricebook2Id = standardPb.Id,
        Product2Id = shippingProduct.Id,
        UnitPrice = 0,
        IsActive = true
    );
    insert pbe;

    System.debug('Created PricebookEntry: ' + pbe.Id);
} else {
    pbe = entries[0];
}

System.debug('Standard Pricebook Id = ' + standardPb.Id);
System.debug('Shipping Product Id = ' + shippingProduct.Id);
System.debug('Ground PricebookEntry Id = ' + pbe.Id);