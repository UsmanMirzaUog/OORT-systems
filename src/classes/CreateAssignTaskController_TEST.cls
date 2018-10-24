/**
 * Created by danielpulache on 11/13/17.
 * CreateAssignTaskController: 92%
 */
@isTest
public class CreateAssignTaskController_TEST {
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req)
        {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Test" : "Blah"}');
            res.setStatus('Success');
            res.setStatusCode(200);
            return res;
        }
    }
    @testSetup public static void SetUpData() {

        TestDataFactory.create_Oppties_with_Patient();
        TestDataFactory.createAllCustomSettings();
        TestDataFactory.create_Address_Payor_Provider();
        TestDataFactory.create_OpptyLineItems();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    }
    @isTest static void retrieveTaskInfo_TEST() {
        CreateAssignTaskController.Data d = CreateAssignTaskController.retrieveTaskInfo();
        CreateAssignTaskController controller = new CreateAssignTaskController();
        system.assert(!d.TaskSubjectList.isEmpty());
        system.assert(!d.TaskDocTypeList.isEmpty());
    }
    @isTest static void createTask() {
        Id ADMTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
        Id SalesTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Opp Note').getRecordTypeId();
        String patientId = [SELECT Id FROM Account WHERE isPersonAccount = true LIMIT 1].Id;
        String providerId = [SELECT Id FROM Provider__c LIMIT 1].Id;

        // public static void createTask(String patientId, String providerId, String ownerId, String taskPriority, String taskSubject, String dueDate, Boolean isUrgent, String urgentReason, String docType, String noteBody, String taskType) {
        CreateAssignTaskController.createTask(patientId, providerId, UserInfo.getUserId(), 'Test Priority', 'Test Subject', system.today().format(), true, 'Test Urgent Reason', 'Test Doc Type', 'Test ADM Note Body', 'ADM');
        CreateAssignTaskController.createTask(patientId, providerId, UserInfo.getUserId(), 'Test Priority', 'Test Subject', system.today().format(), false, '', 'Test Doc Type', 'Test ADM Note Body 2', 'ADM');
        CreateAssignTaskController.createTask(patientId, providerId, UserInfo.getUserId(), 'Test Priority', 'Test Subject', system.today().format(), false, '', 'Test Doc Type', 'Test ADM Note Body 3', 'ADM');
        List<Task> ADMNotes = [SELECT Id, Patient__c, Provider__c, OwnerId, Priority, Subject, ActivityDate, isUrgent__c, Urgent_Reason__c, Document_Type__c, Description, Request__c FROM Task WHERE RecordTypeId = :ADMTaskRecordTypeId ORDER BY CreatedDate ASC];

        CreateAssignTaskController.createTask(patientId, providerId, UserInfo.getUserId(), 'Test Priority', 'Test Subject', system.today().format(), false, '', '', 'Test Sales Note Body', 'Sales');
        List<Task> SalesNotes = [SELECT Id, Patient__c, Provider__c, OwnerId, Priority, Subject, ActivityDate, isUrgent__c, Urgent_Reason__c, Document_Type__c, Description FROM Task WHERE RecordTypeId = :SalesTaskRecordTypeId];

        system.assert([SELECT COUNT() FROM Task WHERE OwnerId =: UserInfo.getUserId()] > 0);
        System.assert(!ADMNotes.isEmpty());
        System.assertEquals('Test ADM Note Body', ADMNotes[0].Description);
        System.assertEquals(true, ADMNotes[0].isUrgent__c);
        System.assertEquals(false, ADMNotes[1].isUrgent__c);
        System.assertEquals(ADMNotes[1].Request__c, ADMNotes[2].Request__c);
        System.assert(!SalesNotes.isEmpty());
        System.assertEquals('Test Sales Note Body', SalesNotes[0].Description);
    }

    @isTest static void getTheProviders() {
        String patientId = [SELECT Id FROM Account WHERE isPersonAccount = true LIMIT 1].Id;

        CreateAssignTaskController catc = new CreateAssignTaskController();
        catc.getProviders();

        System.assert(catc.theProviders.size() > 0);
        System.assertEquals(false, catc.providerDisabled);
    } //@isTest static void getTheProviders()
}