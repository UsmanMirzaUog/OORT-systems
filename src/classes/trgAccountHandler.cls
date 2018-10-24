/**
 * Created by danielpulache on 11/30/17.
 */

public with sharing class trgAccountHandler {
    private List<Account> triggerNew;
    private List<Account> triggerOld;
    private Map<Id, Account> triggerNewMap;
    private Map<Id, Account> triggerOldMap;
    private Map<String, Address_Data__c> mapLocationKeyToAddress;
    private Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();

    public trgAccountHandler(List<Account> triggerNew,
            List<Account> triggerOld,
            Map<Id, Account> triggerNewMap,
            Map<Id, Account> triggerOldMap) {
        this.triggerNew = triggerNew;
        this.triggerOld = triggerOld;
        this.triggerNewMap = triggerNewMap;
        this.triggerOldMap = triggerOldMap;
    }

    //on patient after insert
    public void createPrimaryAddressRecords(){
//        System.debug('***** trgAccountHandler::triggerNew: ' + triggerNew);
        List<Address_Data__c> primaryAddressesToInsert = new List<Address_Data__c>();
        for(Account a : triggerNew) {
            Address_Data__c billingAddress = new Address_Data__c(
                    Name = 'Primary Billing Address'
                    , Street__c = a.BillingStreet
                    , City__c = a.BillingCity
                    , State_Province__c = a.BillingState
                    , Zip_Postal_Code__c = a.BillingPostalCode
                    , Primary__c = true
                    , Account__c = a.Id
                    , Type__c = 'Billing'
            );
//            System.debug('***** trgAccountHandler::createPrimaryAddress::billingAddress: ' + billingAddress);
            Address_Data__c shippingAddress = new Address_Data__c(
                    Name = 'Primary Delivery Address'
                    , Street__c = a.shippingStreet
                    , City__c = a.shippingCity
                    , State_Province__c = a.shippingState
                    , Zip_Postal_Code__c = a.shippingPostalCode
                    , Primary__c = true
                    , Account__c = a.Id
                    , Type__c = 'Shipping'
            );
//            System.debug('***** trgAccountHandler::createPrimaryAddress::shippingAddress: ' + shippingAddress);

            primaryAddressesToInsert.add(billingAddress);
            primaryAddressesToInsert.add(shippingAddress);
        }

        try {
            insert primaryAddressesToInsert;
        } catch (Exception e) {
            System.debug('>>>>> Exception: ' + e);
        }
    }

    //on patient after update
    public void TrackLocationsLastPatientContactDate() {
        //Lists, Sets, and Maps
        List<Location__c> locationListToUpdate = new List<Location__c>();
        Set<Id> patientIdSet = new Set<Id>();
        Map<Id, Set<Id>> mapLocationIdToPatientIdSet = new Map<Id, Set<Id>>();
        Id ADMRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
        for(Account theNewPatient : triggerNew) {
            if(theNewPatient.RecordTypeId == personAccountRecordTypeId) {
                Account theOldPatient = triggerOldMap.get(theNewPatient.Id);
                if(theOldPatient.Last_Contact_Date__c != theNewPatient.Last_Contact_Date__c) { //Last Contact Date has changed
                    patientIdSet.add(theNewPatient.Id);
                }
            }
        }

        //Query Junction Object between Patient and Location aka Task
        Map<Id, Task> theTaskMap = new Map<Id, Task>([SELECT Id, WhatId, Location__c, Patient__c FROM Task WHERE Location__c != null AND RecordTypeId =: ADMRecordTypeId AND Patient__c IN : patientIdSet]);
        for(Task theTask : theTaskMap.values()) {
            if(!mapLocationIdToPatientIdSet.containsKey(theTask.Location__c)) {
                mapLocationIdToPatientIdSet.put(theTask.Location__c, new Set<Id>{theTask.Patient__c});
            } else {
                mapLocationIdToPatientIdSet.get(theTask.Location__c).add(theTask.Patient__c);
            }
        }
        //Query Locations based on the set of Locations retrieved from the last query
        Map<Id, Location__c> mapIdToLocation = new Map<Id, Location__c>([SELECT Id, Last_Patient_Contact_Date__c FROM Location__c WHERE Id IN : mapLocationIdToPatientIdSet.keySet()]);
        for(Location__c theLocation : mapIdToLocation.values()) {
            Set<Id> patientInLocationSet = mapLocationIdToPatientIdSet.get(theLocation.Id);
            Date theLastPatientContactDate;
            for(Id patientId : patientInLocationSet) {
                Account thePatient = triggerNewMap.get(patientId);
                if(theLastPatientContactDate == null || theLastPatientContactDate < thePatient.Last_Contact_Date__c) theLastPatientContactDate = thePatient.Last_Contact_Date__c;
            }
            //If date is not null and has a noteable change then update the Location's Last Patient Contact Date
            if(theLastPatientContactDate != null) {
                theLocation.Last_Patient_Contact_Date__c = theLastPatientContactDate;
                locationListToUpdate.add(theLocation);
            }
        }
        if(!locationListToUpdate.isEmpty()) UPDATE locationListToUpdate;
    }
    //on patient after update
    public void TrackPatientAddressInformation() {
        List<Address_Data__c> addressDataToInsert = new List<Address_Data__c>();
        List<Address_Data__c> addressDataToUpdate = new List<Address_Data__c>();
        List<Address_Data__c> addressDataToDelete = new List<Address_Data__c>();
        List<Address_Data__c> primaryAddressList = new List<Address_Data__c>();
        mapLocationKeyToAddress = new Map<String, Address_Data__c>();
        Map<Id, List<Address_Data__c>> mapPtIdToAddressDataList = new Map<Id, List<Address_Data__c>>();
        Map<Id, Address_Data__c> mapIdToAddressData = new Map<Id, Address_Data__c>([SELECT Id, Street__c, City__c, State_Province__c, Zip_Postal_Code__c, Location_Key__c, Account__c, Primary__c, Type__c FROM Address_Data__c WHERE Account__c IN : triggerNewMap.keySet()]);
        for(Address_Data__c theAddressData : mapIdToAddressData.values()) {
            /*
            *
            * Key depends on workflow rule on the Address Data Object. Make sure the format matches the format in the worklfow rule
            *
            * */
            String locationKey = theAddressData.Street__c+','+theAddressData.City__c+','+theAddressData.State_Province__c+','+theAddressData.Zip_Postal_Code__c;
            mapLocationKeyToAddress.put(locationKey, theAddressData);
        }

        // Create map of Patient Id to List of Primary Billing and Shipping Addresses
        for (Id ptId : triggerNewMap.keySet()) {
            System.debug('ptId = ' + ptId);
            primaryAddressList = new List<Address_Data__c>();
            for (Address_Data__c address : mapIdToAddressData.values()) {
                if (address.Primary__c == true && address.Account__c == ptId) {
                    primaryAddressList.add(address);
                }
            }
            mapPtIdToAddressDataList.put(ptId, primaryAddressList);
        }

//        System.debug('triggerOldMap: ' + triggerOldMap);
//        System.debug('triggerNewMap: ' + triggerNewMap);
//        System.debug('mapIdToAddressData: ' + mapIdToAddressData);
//        System.debug('>>> Id to Address List: ' + mapPtIdToAddressDataList);
        for(Account theNewPatient : triggerNew) {
            if(theNewPatient.RecordTypeId == personAccountRecordTypeId) {
                Account theOldPatient = triggerOldMap.get(theNewPatient.Id);
                if(theOldPatient.BillingStreet != theNewPatient.BillingStreet || theOldPatient.BillingCity != theNewPatient.BillingCity || theOldPatient.BillingState != theNewPatient.BillingState || theOldPatient.BillingPostalCode != theNewPatient.BillingPostalCode || theOldPatient.BillingCountry != theNewPatient.BillingCountry) {
                    system.debug('Billing address changed!');
//                    System.debug('-----> Old Pt: ' + theOldPatient);
//                    System.debug('-----> New Pt: ' + theNewPatient);
                    Address_Data__c theOldBillingAddress = createAddressData(theOldPatient.BillingStreet, theOldPatient.BillingCity, theOldPatient.BillingState, theOldPatient.BillingPostalCode, theOldPatient.Id);
                    Address_Data__c theNewBillingAddress = createAddressData(theNewPatient.BillingStreet, theNewPatient.BillingCity, theNewPatient.BillingState, theNewPatient.BillingPostalCode, theNewPatient.Id);

                    // Update - Old address changed to new address
                    if(theOldBillingAddress != null) {
//                        System.debug('Old Billing Address is not null --> ' + theOldBillingAddress);
                        theOldBillingAddress.Name = 'Primary Billing Address';
                        theOldBillingAddress.Type__c = 'Billing';
                        theOldBillingAddress.Primary__c = true;
                        addressDataToInsert.add(theOldBillingAddress);

                        // Rename old primary address to previous billing address
                        for(Address_Data__c theAddress : mapPtIdToAddressDataList.get(theNewPatient.Id)) {
                            if (theAddress.Primary__c == true && theAddress.Type__c == 'Billing') {
                                if (theAddress.Location_Key__c != ',,,') {
                                    theAddress.Name = 'Previous Billing Address';
                                    theAddress.Primary__c = false;
                                    addressDataToUpdate.add(theAddress);
                                } else {
                                    addressDataToDelete.add(theAddress);
                                }
                            }
                        }
                        addressDataToUpdate.add(theOldBillingAddress);
                    }

                    // Update - Address changed from Account
                    if(theNewBillingAddress != null){
//                        System.debug('New Billing Address is not null --> ' + theNewBillingAddress);
                        theNewBillingAddress.Name = 'Primary Billing Address';
                        theNewBillingAddress.Type__c = 'Billing';
                        theNewBillingAddress.Primary__c = true;
                        addressDataToInsert.add(theNewBillingAddress);

                        // Rename old primary address to previous billing address
                        for(Address_Data__c theAddress : mapPtIdToAddressDataList.get(theNewPatient.Id)) {
                            if (theAddress.Primary__c == true && theAddress.Type__c == 'Billing') {
                                if (theAddress.Location_Key__c != ',,,') {
                                    theAddress.Name = 'Previous Billing Address';
                                    theAddress.Primary__c = false;
                                    addressDataToUpdate.add(theAddress);
                                } else {
                                    addressDataToDelete.add(theAddress);
                                }
                            }
                        }
                    }
//                    System.debug('theoldbillingaddy: ' + theOldBillingAddress);
//                    System.debug('theNewbillingaddy: ' + theNewBillingAddress);
                }
                if(theOldPatient.ShippingStreet != theNewPatient.ShippingStreet || theOldPatient.ShippingCity != theNewPatient.ShippingCity || theOldPatient.ShippingState != theNewPatient.ShippingState || theOldPatient.ShippingPostalCode != theNewPatient.ShippingPostalCode || theOldPatient.ShippingCountry != theNewPatient.ShippingCountry) {
                    system.debug('Shipping address changed!');
                    Address_Data__c theOldShippingAddress = createAddressData(theOldPatient.ShippingStreet, theOldPatient.ShippingCity, theOldPatient.ShippingState, theOldPatient.ShippingPostalCode, theOldPatient.Id);
                    Address_Data__c theNewShippingAddress = createAddressData(theNewPatient.ShippingStreet, theNewPatient.ShippingCity, theNewPatient.ShippingState, theNewPatient.ShippingPostalCode, theNewPatient.Id);
                    // Update - Old address changed to new address
                    if(theOldShippingAddress != null) {
                        System.debug('Old Shipping Address is not null --> ' + theOldShippingAddress);
                        theOldShippingAddress.Name = 'Primary Shipping Address';
                        theOldShippingAddress.Type__c = 'Shipping';
                        theOldShippingAddress.Primary__c = true;
                        addressDataToInsert.add(theOldShippingAddress);

                        // Rename old primary address to previous billing address
                        for(Address_Data__c theAddress : mapPtIdToAddressDataList.get(theNewPatient.Id)) {
                            if (theAddress.Primary__c == true && theAddress.Type__c == 'Shipping') {
                                if (theAddress.Location_Key__c != ',,,') {
                                    theAddress.Name = 'Previous Delivery Address';
                                    theAddress.Primary__c = false;
                                    addressDataToUpdate.add(theAddress);
                                } else {
                                    addressDataToDelete.add(theAddress);
                                }
                            }
                        }
                    }
                    // Update - Address updated from Acct
                    if(theNewShippingAddress != null) {
                        System.debug('New Shipping Address is not null --> ' + theNewShippingAddress);
                        theNewShippingAddress.Name = 'Primary Delivery Address';
                        theNewShippingAddress.Type__c = 'Shipping';
                        theNewShippingAddress.Primary__c = true;
                        addressDataToInsert.add(theNewShippingAddress);
                        // Rename old primary address to previous billing address
                        for(Address_Data__c theAddress : mapPtIdToAddressDataList.get(theNewPatient.Id)) {
                            if (theAddress.Primary__c == true && theAddress.Type__c == 'Shipping') {
                                if (theAddress.Location_Key__c != ',,,') {
                                    theAddress.Name = 'Previous Delivery Address';
                                    theAddress.Primary__c = false;
                                    addressDataToUpdate.add(theAddress);
                                } else {
                                    addressDataToDelete.add(theAddress);
                                }
                            }
                        }
                    }

//                    System.debug('>>> theoldshippingaddy: ' + theOldShippingAddress);
//                    System.debug('>>> theNewshippingaddy: ' + theNewShippingAddress);
//                    updateShippingAddressDataRecord(theNewPatient);
                }
//                System.debug('addressDatatoInsert: ' + addressDataToInsert);
//                System.debug('addressDatatoUpdate: ' + addressDataToUpdate);
//                System.debug('addressDatatoDelete: ' + addressDataToDelete);
            }
        }

        if(!addressDataToInsert.isEmpty()) {
            INSERT addressDataToInsert;
            UPDATE addressDataToUpdate;
            DELETE addressDataToDelete;
        }
    }
    private Address_Data__c createAddressData(String street, String city, String state, String zip, Id accountId) {
        if(String.isBlank(street) || String.isBlank(city) || String.isBlank(state) || String.isBlank(zip)) return null;
        /*
        *
        * Key depends on workflow rule on the Address Data Object. Make sure the format matches the format in the worklfow rule
        *
        * */
        String locationKey = street+','+city+','+state+','+zip;
        if(mapLocationKeyToAddress.containsKey(locationKey)) return null;
        Address_Data__c theAddressData = new Address_Data__c();
        theAddressData.Street__c = street;
        theAddressData.City__c = city;
        theAddressData.State_Province__c = state;
        theAddressData.Zip_Postal_Code__c = zip;
        theAddressData.Account__c = accountId;
        return theAddressData;
    }
}