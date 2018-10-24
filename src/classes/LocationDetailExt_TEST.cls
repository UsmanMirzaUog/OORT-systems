/**
 * Created by danielpulache on 11/16/17.
 * LocationDetailExt: 96%
 */
@isTest
public class LocationDetailExt_TEST {
    private static LocationDetailExt extension;
    private static List<Location__c> locaitonList;

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req)
        {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('Record created successfully!');
            res.setStatusCode(200);
            return res;
        }
    }

    @testsetup static void setupTestData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        TestDataFactory.create_Oppties_with_Patient();
        TestDataFactory.create_Address_Payor_Provider();
        TestDataFactory.create_Requests();
        TestDataFactory.create_Locations();
        TestDataFactory.create_LocationADMTasks();
        TestDataFactory.create_LocationCallLogActivities();
        TestDataFactory.create_LocationRules();
        TestDataFactory.createAllCustomSettings();
    }
    @isTest static void initExtension() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        List<Location__c> locations = [SELECT Id FROM Location__c];
        system.debug('locations = ' + locations);
        ApexPages.StandardController controller = new ApexPages.StandardController(locations[2]);
        extension = new LocationDetailExt(controller);

    }
    @isTest static void remoteActionGetItems() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        initExtension();
        system.assert(!LocationDetailExt.getCallLogItems(extension.theLocationDetails.Id).isEmpty());
        system.assert(!LocationDetailExt.getLocationRules(extension.theLocationDetails.Id).isEmpty());

        // Complete the first address, so tasks get updated to Request_Complete__c true, so something shows up
        // Task items only show up if the Request has been completed or the task is urgent
        List<Request__c> requests = [SELECT Id, Name, Completed__c FROM Request__c];
        requests[0].Completed__c = true;
        update requests;

        //system.assert(!LocationDetailExt.getTasksItems(extension.theLocationDetails.Id).isEmpty());
    }
    @isTest static void saveTheRecord_Test() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        initExtension();
        extension.theLocationDetails.Phone__c = '987456123';
        extension.saveTheRecord();
        system.assert([SELECT Phone__c FROM Location__c WHERE Id =: extension.theLocationDetails.Id].Phone__c == '987456123');
    }
    @isTest static void getPatientList_TEST() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        initExtension();
        List<SelectOption> options = extension.getPatientList();
        System.debug('*** getPatientList_TEST::options = ' + options);
        system.assert(options.size() > 0);
    }
    @isTest static void getCallLogModalDetails_TEST() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        initExtension();
        List<LocationDetailExt.CallLogItem> callLogItems = LocationDetailExt.getCallLogItems(extension.theLocationDetails.Id);
        system.assert(!callLogItems.isEmpty());
        System.debug('>>>>> call Log items: ' + callLogItems);
        Task callLogDetail = LocationDetailExt.getCallLogModalDetails(callLogItems[0].Id);
        System.debug('>>>>> detail: ' + callLogDetail);
        System.assertEquals('Outcome 0', callLogDetail.Call_Outcome__c);
        System.assertEquals('Disposition 0', callLogDetail.Call_Disposition__c);
        System.assertEquals('Test Description 0', callLogDetail.Description);
        System.assertEquals('Test Subject0', callLogDetail.Subject);
    }
    @isTest static void logCall_TEST() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        initExtension();

        List<Account> patients = [SELECT Id, Name FROM Account];

        Test.startTest();
        String resultString = LocationDetailExt.logCall(patients[0].Id, true, 'Hello World', extension.theLocation.Id, 'Call Disposition', 'Call Outcome', false, null);
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Patient__c, Description, Subject, Call_Outcome__c, Call_Disposition__c FROM Task WHERE Call_Outcome__c = 'Call Outcome'];

        System.debug('*** tasks = ' + tasks);

        System.assertEquals('Success', resultString);
        System.assertEquals(patients[0].Id, tasks[0].Patient__c);
        System.assertEquals('Hello World', tasks[0].Description);
        System.assertEquals('Call Disposition', tasks[0].Call_Disposition__c);
        System.assertEquals('Call Outcome', tasks[0].Call_Outcome__c);
    }


    //#157318652 KHB notes templates populate the text body
    @isTest static void setTemplate_TEST() {
        Notes_Template__c nt = new Notes_Template__c(
                Call_Disposition__c = 'Captured Order',
                Template__c = 'Just try and test me, punk'
        );
        INSERT nt;

        String temp = LocationDetailExt.setTemplate('Captured Order');
        System.assert(temp == nt.Template__c);

        String temp2 = LocationDetailExt.setTemplate('Status Update');
        System.assert(temp2 == '');
    }

    @isTest static void getTaskItems_TEST() {
        Id ADMNoteRecordType = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
        List<Task> admTasks = [SELECT Id, Request_Completed__c, isUrgent__c, Status, Location__c FROM Task WHERE RecordTypeId =: ADMNoteRecordType];
        For (Task adm : admTasks) {
            adm.Request_Completed__c = true;
            adm.isUrgent__c = true;
            adm.Status = 'Open';
        }
        UPDATE admTasks;

        Location__c l = [SELECT Id FROM Location__c WHERE Id =: admTasks[0].Location__c LIMIT 1];
        List<LocationDetailExt.TaskItem> admTaskList = LocationDetailExt.getTasksItems(String.valueOf(l.Id));
        System.assert(admTaskList.size() > 0);
    }
}