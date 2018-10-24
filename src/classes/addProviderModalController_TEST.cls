@isTest
public with sharing class addProviderModalController_TEST {
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req)
        {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Test" : "Blah"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @testSetup static void setupTestData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        TestDataFactory.create_Oppties_with_Patient();
        TestDataFactory.create_Address_Payor_Provider();
        TestDataFactory.create_Requests();
        TestDataFactory.createUrgentRequestItems();
        TestDataFactory.createAllCustomSettings();
        TaskWorkQueueController controller = new TaskWorkQueueController();
    }
    @isTest
    public static void testSearchProvider(){
        String theUrl = 'http://13.64.71.110/api/patient/searchProviderByLastName?lastName=Smith';
        Test.setMock(HttpCalloutMock.class, new HttpRemoteCalloutMock());
        Test.startTest();
//        HttpRequest req = addProviderModalController.buildWebServiceRequest(theUrl);
//        HttpResponse res = HttpRemoteCalloutMock.respond(req);
//        List<addProviderModalController.Provider> returnedProviders = addProviderModalController.handleWebServiceResponse(res);
        List<addProviderModalController.Provider> returnedProviders = addProviderModalController.getProvidersByLastName(theUrl);

        Test.stopTest();

//        System.assertEquals(200, res.getStatusCode());
        System.assert(returnedProviders.size() > 1);
    }

    @isTest
    public static void testSearchProviderTimeout(){
        String theUrl = 'http://13.64.71.110/api/patient/searchProviderByLastName?lastName=Smith';
        Test.setMock(HttpCalloutMock.class, new HttpRemoteCalloutMock());
        Test.startTest();
        HttpRequest req = addProviderModalController.buildWebServiceRequest(theUrl);
        HttpResponse res = HttpRemoteCalloutMock.timeoutResponse(req);
        List<addProviderModalController.Provider> returnedProviders = addProviderModalController.handleWebServiceResponse(res);

        Test.stopTest();

        System.assertEquals(400, res.getStatusCode());
    }

    @isTest
    public static void testAddProvider(){
        Test.setMock(HttpCalloutMock.class, new HttpRemoteCalloutMock());
        Account testPatient = new Account(Name = 'Joe');
        insert testPatient;

        Provider__c existingProvider = new Provider__c(NPI__c = '1234567890');
        insert existingProvider;

        addProviderModalController.Provider newProvider = new addProviderModalController.Provider();
        newProvider.NPINumber = '0987654321';

        Test.startTest();
        addProviderModalController.addProvider(newProvider,String.valueOf(testPatient.Id));
        Test.stopTest();

        List<Provider__c> providers = [SELECT Id from Provider__c];

        System.assertEquals(3, providers.size());
    }

    @isTest
    public static void testAddDuplicateProvider(){
        Test.setMock(HttpCalloutMock.class, new HttpRemoteCalloutMock());
        Account testPatient = new Account(Name = 'Joe');
        insert testPatient;

        Provider__c existingProvider = new Provider__c(NPI__c = '1234567890');
        insert existingProvider;

        addProviderModalController.Provider newProvider = new addProviderModalController.Provider();
        newProvider.NPINumber = '1234567890';

        Test.startTest();
        addProviderModalController.addProvider(newProvider,String.valueOf(testPatient.Id));
        Test.stopTest();

        List<Provider__c> providers = [SELECT Id from Provider__c];

        System.assertEquals(2, providers.size());
    }

   /* @isTest
    static void testTopPanel(){
        Account testPatient = new Account(Name = 'Joe');
        insert testPatient;

        Opportunity theOpportunity = new Opportunity(Name = 'New Opportunity', CloseDate = Date.today().addDays(14), StageName = 'New', AccountId = testPatient.Id);
        INSERT theOpportunity;

        List<Provider__c> theProviderList = new List<Provider__c>();
        theProviderList.add(new Provider__c(Name = 'John Smith', NPI__c = '1234567890'));
        theProviderList.add(new Provider__c(Name = 'Beverly Crusher'));
        theProviderList.add(new Provider__c(Name = 'Marcus Welby'));
        INSERT theProviderList;

//        Provider_Patient_Junction__c ppj = new Provider_Patient_Junction__c(Provider__c = theProviderList.get(0).Id, Patient__c = testPatient.Id);
//        INSERT ppj;

        Test.setCurrentPage(Page.Console_OpportunityDetail);
        ApexPages.StandardController sc = new ApexPages.StandardController(theOpportunity);
        extConsole_TopPanel_Providers providerPanel = new extConsole_TopPanel_Providers(sc);

        addProviderModalController con = new addProviderModalController();
        con.searchString = 'hi';
        addProviderModalController.providerSearchString = 'smith';
        con.patient = testPatient;

        addProviderModalController.Provider theProvider = new addProviderModalController.Provider();
        theProvider.NPINumber = theProviderList.get(0).NPI__c;

//        providerPanel.refreshProviderList();
//        System.debug(providerPanel.providerList.size());
//        System.assertEquals(0, providerPanel.providerList.size());

        addProviderModalController.addProvider(theProvider, testPatient.Id);
        providerPanel.refreshProviderList();



        System.assertEquals(1, providerPanel.providerList.size());
    }*/
}