/**
 * Created by isaac on 4/19/18.
 */

public with sharing class trgAddressDataHandler {
    private List<Address_Data__c> triggerNew;
    private List<Address_Data__c> triggerOld;
    private Map<Id, Address_Data__c> triggerNewMap;
    private Map<Id, Address_Data__c> triggerOldMap;
    private Map<String, Address_Data__c> mapLocationKeyToAddress;

    public trgAddressDataHandler(List<Address_Data__c> triggerNew,
            List<Address_Data__c> triggerOld,
            Map<Id, Address_Data__c> triggerNewMap,
            Map<Id, Address_Data__c> triggerOldMap) {
        this.triggerNew = triggerNew;
        this.triggerOld = triggerOld;
        this.triggerNewMap = triggerNewMap;
        this.triggerOldMap = triggerOldMap;
    }
    
    public void updatePrimaryBillingAddress() {
        System.debug('>>>>>> updatePrimaryBillingAddress()');
        List<Address_Data__c> historicalBillingList = new List<Address_Data__c>();
        for (Address_Data__c newAddress : triggerNew) {
            Address_Data__c oldAddress = triggerOldMap.get(newAddress.Id);
            System.debug('***** old addy before the if: ' + oldAddress);
            System.debug('***** new addy before the if: ' + newAddress);
            if (oldAddress.Primary__c == true && oldAddress.Type__c == 'Billing' && newAddress.Street__c != oldAddress.Street__c) {
                if (oldAddress.Street__c != null && oldAddress.City__c != null && oldAddress.State_Province__c != null && oldAddress.Zip_Postal_Code__c != null) {
                    System.debug('>>>>>>>> Creating Previous Billing Address <<<<<<<<<');
                    Address_Data__c billingHistory = new Address_Data__c(
                            Name = 'Previous Billing Address'
                    , Account__c = oldAddress.Account__c
                    , Street__c = oldAddress.Street__c
                    , City__c = oldAddress.City__c
                    , State_Province__c = oldAddress.State_Province__c
                    , Zip_Postal_Code__c = oldAddress.Zip_Postal_Code__c
                    , Primary__c = false
                    , Type__c = oldAddress.Type__c
                    );
                    historicalBillingList.add(billingHistory);
                }
            }
        }
        System.debug('*** Billing Addresses: ' + historicalBillingList);
        if(historicalBillingList.size() > 0) {
            System.debug('>>>>>> INSERTING Billing address <<<<<<');
            insert historicalBillingList;
        }
    }

    public void updatePrimaryShippingAddress() {
        System.debug('>>>>>> updatePrimaryShippingAddress()');
        List<Address_Data__c> historicalShippingList = new List<Address_Data__c>();
        for (Address_Data__c newAddress : triggerNew) {
            Address_Data__c oldAddress = triggerOldMap.get(newAddress.Id);
            System.debug('***** old addy: ' + oldAddress);
            System.debug('***** new addy: ' + newAddress);
            if (oldAddress.Primary__c == true && oldAddress.Type__c == 'Shipping' && newAddress.Street__c != oldAddress.Street__c) {
                if (oldAddress.Street__c != null && oldAddress.City__c != null && oldAddress.State_Province__c != null && oldAddress.Zip_Postal_Code__c != null) {
                    System.debug('>>>>>>>> Creating Previous Shipping Address <<<<<<<<<');
                    Address_Data__c shippingHistory = new Address_Data__c(
                            Name = 'Previous Shipping Address'
                    , Account__c = oldAddress.Account__c
                    , Street__c = oldAddress.Street__c
                    , City__c = oldAddress.City__c
                    , State_Province__c = oldAddress.State_Province__c
                    , Zip_Postal_Code__c = oldAddress.Zip_Postal_Code__c
                    , Primary__c = false
                    , Type__c = oldAddress.Type__c
                    );
                    historicalShippingList.add(shippingHistory);
                }
            }
        }

        System.debug('*** Shipping Addresses: ' + historicalShippingList);
        if(historicalShippingList.size() > 0) insert historicalShippingList;
    }
}