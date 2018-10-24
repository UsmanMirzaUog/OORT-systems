/**
 * Created by isaac on 9/12/17.
 */

public with sharing class extConsole_TopPanel_Providers {
    private final Opportunity mysObject;
    public List<Provider_Patient_Junction__c> providerList {get; set;}
    //public List<Insurance_Patient_Junction__c> providerList = new List<Insurance_Patient_Junction__c>();
    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public extConsole_TopPanel_Providers(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) stdController.addFields(new String[] {'AccountId'});
        this.mysObject = (Opportunity)stdController.getRecord();
        refreshProviderList();
    }

    public void refreshProviderList()
    {
        providerList = [SELECT Id, Name, Patient__c, Provider__r.Id, Provider__r.Name, Provider__r.Address__c, Provider__r.Address2__c,
                            Provider__r.City__c, Provider__r.State__c, Provider__r.Zip__c, Provider__r.NPI__c, Provider__r.Phone__c,
                            Provider__r.Fax__c, Provider__r.Email__c, Prescribing__c, Rendering__c, PCP__c
                        FROM Provider_Patient_Junction__c
                        WHERE Patient__c =:mysObject.AccountId];

        System.debug('*** Provider List = ' + providerList);
    }
}