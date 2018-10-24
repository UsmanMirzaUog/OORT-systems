public with sharing class extConsole_TopPanel_Insurance {

	private final Opportunity mysObject;
    public List<Insurance_Patient_Junction__c> policyList {get; set;}
    //public List<Insurance_Patient_Junction__c> patientList = new List<Insurance_Patient_Junction__c>();
    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public extConsole_TopPanel_Insurance(ApexPages.StandardController stdController) {
        if(!Test.isRunningTest()) stdController.addFields(new String[] {'AccountId'});
        this.mysObject = (Opportunity)stdController.getRecord();
        refreshPolicyList();
    }

    public void refreshPolicyList()
    {
        policyList = [SELECT Id, Insurance__r.Name, Insurance__r.Id, 
                             Policy_Level__c, Policy_Id__c, Group_Number__c, Start_Date__c, End_Date__c
                                FROM Insurance_Patient_Junction__c
                                WHERE Account__r.Id =:mysObject.AccountId
                                AND (Start_Date__c <= TODAY AND (End_Date__c >= TODAY OR End_Date__c = null))];

        System.debug(policyList);
        
    }
    public PageReference redirect()
    {
        PageReference pr = new PageReference('https://solaradev-dev-ed.my.salesforce.com/a01/e?retURL=%2Fa01%2Fo');
        return pr;
    }
}