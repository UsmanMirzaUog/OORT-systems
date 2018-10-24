public with sharing class patientModalController { //KHB added with sharing
    public Account patient {get; set;} //The patient record that will come from the component attribute
    public Address_Data__c primaryBillingAddress {
        get {
            if (!gotPrimaryBilling) {
                primaryBillingAddress = getPrimaryBillingAddress();
            }
            return primaryBillingAddress;
        }
        set;
    }
    public Address_Data__c primaryShippingAddress {
        get {
            if (!gotPrimaryShipping) {
                primaryShippingAddress = getPrimaryShippingAddress();
            }
            return primaryShippingAddress;
        }
        set;
    }
    public Contact primaryContact {
        get {
            if (!gotPrimaryContact) {
                primaryContact = getPrimaryContact();
            }
            return primaryContact;
        }
        set;
    }
    public contact responsibleParty {
        get {
            if (!gotResponsibleContact) {
                responsibleParty = getResponsibleParty();
            }
            return responsibleParty;
        }
        set;
    }

    public Address_Data__c insertAddress {get; set;}
    public Address_Data__c[] addresses {
        get {
            if (!gotAddress) {
                addresses = getAddresses();
            }
            return addresses;
        }
        set;
    }
//    public Address_Data__c address {get; set;}
//    public Address_Data__c[] addAddresses {get; set;}

    @testVisible private Boolean gotPrimaryBilling = false;
    @testVisible private Boolean gotPrimaryShipping = false;
    @testVisible private Boolean gotPrimaryContact = false;
    @testVisible private Boolean gotResponsibleContact = false;
    @testVisible private Boolean gotAddress = false;

    //Start Constructor
    public patientModalController(){
        addresses = new Address_Data__c[]{};
        insertAddress = new Address_Data__c(Name = 'New Address');
    }

    public Address_Data__c getPrimaryBillingAddress(){
        System.debug('*** getPrimaryBillingAddress :: pt ID' + patient);
        List<Address_Data__c> primaryBillingList = [SELECT Street__c, City__c, State_Province__c, Zip_Postal_Code__c FROM Address_Data__c WHERE Account__c = :patient.Id AND Primary__c = true AND Type__c = 'Billing' LIMIT 1];
        System.debug('***** billing address: ' + primaryBillingList.size());
        if (String.isNotBlank(patient.Id)) {
            gotPrimaryBilling = true;
        }
        return primaryBillingList.isEmpty() ? new Address_Data__c() : primaryBillingList[0];
    }

    public Address_Data__c getPrimaryShippingAddress(){
        List<Address_Data__c> primaryShippingList = [SELECT Street__c, City__c, State_Province__c, Zip_Postal_Code__c FROM Address_Data__c WHERE Account__c = :patient.Id AND Primary__c = true AND Type__c = 'Shipping' LIMIT 1];
        if (String.isNotBlank(patient.Id)) {
            gotPrimaryShipping = true;
        }
        return primaryShippingList.isEmpty() ? new Address_Data__c() : primaryShippingList[0];
    }

    public Contact getPrimaryContact(){
        AccountContactRelation[] output = [
                SELECT Contact.FirstName, Contact.LastName, Contact.Birthdate, Contact.Gender__c, Contact.Active__c,
                        Contact.Relationship_to_Patient__c, Contact.MobilePhone, Contact.Phone, Contact.Email, Contact.Preferred_Communication__c,
                        Contact.Preferred_Name__c, Contact.Primary_Contact__c, Contact.Responsible_Party__c
                FROM AccountContactRelation WHERE AccountId = :patient.Id AND Contact.Primary_Contact__c = true
        ];
        if (String.isNotBlank(patient.Id)) {
            gotPrimaryContact = true;
        }

        return output.isEmpty() ? new Contact() : output[0].Contact;
    }

    public Contact getResponsibleParty(){
        AccountContactRelation[] output = [
                SELECT Contact.Id, Contact.FirstName, Contact.LastName, Contact.Birthdate, Contact.Gender__c, Contact.Active__c,
                        Contact.Relationship_to_Patient__c, Contact.MobilePhone, Contact.Phone, Contact.Email, Contact.Preferred_Communication__c,
                        Contact.Preferred_Name__c, Contact.Primary_Contact__c, Contact.Responsible_Party__c
                FROM AccountContactRelation WHERE AccountId = :patient.Id AND Contact.Responsible_Party__c = true
        ];

        if (String.isNotBlank(patient.Id)) {
            gotResponsibleContact = true;
        }
//        System.debug('>>>>> Responsible Party: ' + JSON.serialize(output));
        return output.isEmpty() ? new Contact() : output[0].Contact;
    }

    public Address_Data__c[] getAddresses(){
        Address_Data__c[] output = [SELECT Name, City__c, State_Province__c, Street__c, Zip_Postal_Code__c
        FROM Address_Data__c where Account__c = :patient.Id AND Primary__c != true order by name];

        if (String.isNotBlank(patient.Id)) {
            gotAddress = true;
        }
        return output;
    }

    public void addAddressRow() {
        insertAddress.Account__c =  patient.Id;
        if(insertAddress.Name == NULL) insertAddress.Name = 'New Address';
        System.debug('***** Address Name: ' + insertAddress.Name);
        insert insertAddress;
        insertAddress = new Address_Data__c(Name = 'New Address');
        gotAddress = false;
    }

    public void doSave(){
        System.debug(JSON.serialize(primaryContact));
        System.debug(JSON.serialize(responsibleParty));
        Id patientRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();

        try{
            if (String.isNotBlank(primaryContact.LastName) && !patient.Primary_Contact__c) {
                primaryContact.Primary_Contact__c = true;
//                System.debug('Is pc.Id blank?  = ' + String.isBlank(primaryContact.Id));
//                System.debug('pc = ' + primaryContact);
                if (String.isBlank(primaryContact.Id)) {
                    Account p = new Account(
                            FirstName = primaryContact.FirstName,
                            LastName = primaryContact.LastName,
                            PersonBirthdate = primaryContact.Birthdate,
                            Gender__pc = primaryContact.Gender__c,
                            Active__pc = primaryContact.Active__c,
                            Relationship_to_Patient__pc = primaryContact.Relationship_to_Patient__c,
                            PersonMobilePhone = primaryContact.MobilePhone,
                            Phone = primaryContact.Phone,
                            PersonEmail = primaryContact.Email,
                            Preferred_Communication__pc = primaryContact.Preferred_Communication__c,
                            Preferred_Name__pc = primaryContact.Preferred_Name__c,
                            Primary_Contact__pc = primaryContact.Primary_Contact__c,
                            Responsible_Party__pc = primaryContact.Responsible_Party__c,
                            RecordTypeId = patientRecordTypeId
                    );
                    insert p;
                    p = [SELECT PersonContactId from Account where Id = :p.Id];
                    insert new AccountContactRelation(ContactId = p.PersonContactId, AccountId = patient.Id);
                    primaryContact = getPrimaryContact();
                }
                else update primaryContact;
            }
            if (String.isNotBlank(responsibleParty.LastName) && !primaryContact.Responsible_Party__c && !patient.Responsible_Party__c) {
                responsibleParty.Responsible_Party__c = true;
                if (String.isBlank(responsibleParty.Id)) {
                    Account p = new Account(
                            FirstName = responsibleParty.FirstName,
                            LastName = responsibleParty.LastName,
                            PersonBirthdate = responsibleParty.Birthdate,
                            Gender__pc = responsibleParty.Gender__c,
                            Active__pc = responsibleParty.Active__c,
                            Relationship_to_Patient__pc = responsibleParty.Relationship_to_Patient__c,
                            PersonMobilePhone = responsibleParty.MobilePhone,
                            Phone = responsibleParty.Phone,
                            PersonEmail = responsibleParty.Email,
                            Preferred_Communication__pc = responsibleParty.Preferred_Communication__c,
                            Preferred_Name__pc = responsibleParty.Preferred_Name__c,
                            Primary_Contact__pc = responsibleParty.Primary_Contact__c,
                            Responsible_Party__pc = responsibleParty.Responsible_Party__c,
                            RecordTypeId = patientRecordTypeId
                    );
                    insert p;
                    p = [SELECT PersonContactId from Account where Id = :p.Id];
                    insert new AccountContactRelation(ContactId = p.PersonContactId, AccountId = patient.Id);
                    responsibleParty = getResponsibleParty();
                }
                else update responsibleParty;
            }
            update patient;
            List<Address_Data__c> updateAddresses = new List<Address_Data__c>();
            List<Address_Data__c> insertAddresses = new List<Address_Data__c>();
            if (addresses != null) updateAddresses.addAll(addresses);
            updateAddresses.add(primaryBillingAddress);
            updateAddresses.add(primaryShippingAddress);
            System.debug('*** doSave()::updateAddreses: ' + updateAddresses);
            update updateAddresses;
        }catch(Exception e){
            System.debug(e);
            throw e;
        }
//        PageReference page = ApexPages.currentPage();
//        System.debug('********* Redirect URL: ' + page);
//        page.setRedirect(true);
//        return page;
    }
}