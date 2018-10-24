public with sharing class extConsole_TopPanel_PatientsContacts {

    private final Opportunity mysObject;
    public List<Account> patientContactList {get; set;}
    public List<patientContactWrapper> patientContacts {get; set;}
    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public extConsole_TopPanel_PatientsContacts(ApexPages.StandardController stdController) {
        if(!Test.isRunningTest()) stdController.addFields(new String[] {'AccountId'});
        this.mysObject = (Opportunity)stdController.getRecord();
        refreshPatientContacts();
    }
    public void Save()
    {
        refreshPatientContacts();
    }

    public void refreshPatientContacts()
    {
        patientContactList = [SELECT Id, Name, Responsible_Party__c, Primary_Contact__c, Preferred_Name__c, 
                              Preferred_Communication__pc, PersonHomePhone, PersonEmail, Active__pc,
                              (SELECT Id, Contact.Primary_Contact__c, Contact.Responsible_Party__c,Contact.Name,Contact.Preferred_Communication__c, 
                              Contact.Phone, Contact.Email, Contact.Status__c, Account.Preferred_Communication__pc, Account.Active__pc FROM AccountContactRelations WHERE AccountId = :mysObject.AccountId) FROM Account
                              WHERE Id = :mysObject.AccountId];
        system.debug(patientContactList);


        List<patientContactWrapper> pcwList = new List<patientContactWrapper>();

        for (Account a : patientContactList) {
            patientContactWrapper thePatient = new patientContactWrapper();
            if (a.Primary_Contact__c == true) thePatient.pc = true;
            if (a.Responsible_Party__c == true) thePatient.rp = true;
            if (a.Name != null) thePatient.pfName = a.Name;
            if (a.Preferred_Communication__pc != null) thePatient.pcm = a.Preferred_Communication__pc;
            if (a.PersonHomePhone != null) thePatient.phone = a.PersonHomePhone;
            if (a.PersonEmail != null) thePatient.email = a.PersonEmail;
            if (a.Active__pc != null) thePatient.status = a.Active__pc;
            if (a.Id != null) thePatient.pId = a.Id;
            pcwList.add(thePatient);
            for (AccountContactRelation c : a.AccountContactRelations) {
                patientContactWrapper theContact = new patientContactWrapper();
                theContact.pc = c.Contact.Primary_Contact__c;
                theContact.rp = c.Contact.Responsible_Party__c;
                if (c.Contact.Name != null) theContact.pfName = c.Contact.Name;
                if (c.Contact.Preferred_Communication__c != null) theContact.pcm = c.Contact.Preferred_Communication__c;
                if (c.Contact.Phone != null) theContact.phone = c.Contact.Phone;
                if (c.Contact.Email != null) theContact.email = c.Contact.Email;
                if (c.Account.Active__pc != null) theContact.status = c.Account.Active__pc;
                if (c.Id != null) theContact.pId = c.Id;
                pcwList.add(theContact);               
            }
        }

        system.debug ('the list:: ' + pcwList);

        if (pcwList.size() > 0) this.patientContacts = pcwList;                               
    }

    public class patientContactWrapper
    {
        public Boolean pc {get; set;}
        public Boolean rp {get; set;}       
        public String pfName {get; set;}
        public String pcm {get; set;}
        public String phone {get; set;}
        public String email {get; set;}
        public String status {get; set;}
        public String pId {get; set;}
    }
}