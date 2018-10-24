/**
 * Created by danielpulache on 10/24/17.
 */
@isTest
public class batchSyncProductTable_TEST {
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            String bodyString =
                    '[' +
                            '{' +
                                '"ItemDescr": "test",' +
                                '"ItemGroup": "test",' +
                                '"ItemID": "test",' +
                                '"ItemKey": "test",' +
                                '"ItemName": "test",' +
                                '"ItemStatus": "test",' +
                                '"ItemType": "test",' +
                                '"KitItem": "test",' +
                                '"Lotted": "test",' +
                                '"ManufacturerID": "test",' +
                                '"ManufacturerName": "test",' +
                                '"NickName": "test",' +
                                '"ProcCode": "test",' +
                                '"RetailPurchAmount": "test",' +
                                '"RetailRentalAmount": "test",' +
                                '"SaleType": "test",' +
                                '"SupercedeItemKey": "test",' +
                                '"User1": "test",' +
                                '"User2": "test",' +
                                '"User3": "test",' +
                                '"User4": "test",' +
                                '"VendorItemID": "test",' +
                                '"VendorItemName": "test",' +
                                '"VendorName": "test",' +
                                '"Weight": "test"' +
                            '}' +
                    ']';
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(bodyString);
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest static void doBatchAction() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        database.executeBatch(new batchSyncProductTable('testEndpoint'));
        Test.stopTest();

        system.assert([SELECT COUNT() FROM Product2]>0);
        System.assert([SELECT COUNT() FROM PricebookEntry]>0);
    }
    @isTest static void doCoverEachProductLineItem() {
        batchSyncProductTable b = new batchSyncProductTable('testEndpoint');
        batchSyncProductTable.productData productDataObject = new batchSyncProductTable.productData();
        productDataObject.ItemDescr = 'test';
        productDataObject.ItemGroup = 'test';
        productDataObject.ItemID = 'test';
        productDataObject.ItemKey = 'test';
        productDataObject.ItemName = 'test';
        productDataObject.ItemStatus = 'test';
        productDataObject.ItemType = 'test';
        productDataObject.KitItem = 'test';
        productDataObject.Lotted = 'test';
        productDataObject.ManufacturerID = 'test';
        productDataObject.ManufacturerName = 'test';
        productDataObject.NickName = 'test';
        productDataObject.ProcCode = 'test';
        productDataObject.RetailPurchAmount = 'test';
        productDataObject.RetailRentalAmount = 'test';
        productDataObject.SaleType = 'test';
        productDataObject.SupercedeItemKey = 'test';
        productDataObject.User1 = 'test';
        productDataObject.User2 = 'test';
        productDataObject.User3 = 'test';
        productDataObject.User4 = 'test';
        productDataObject.VendorItemID = 'test';
        productDataObject.VendorItemName = 'test';
        productDataObject.VendorName = 'test';
        productDataObject.Weight = 'test';
    }
}