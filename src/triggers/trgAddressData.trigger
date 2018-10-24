/**
 * Created by isaac on 4/19/18.
 */

trigger trgAddressData on Address_Data__c (after update) {
    trgAddressDataHandler handler = new trgAddressDataHandler(trigger.new, trigger.old, trigger.newMap, trigger.oldMap);
    if(trigger.isAfter) {
        if (trigger.isUpdate) {
            handler.updatePrimaryBillingAddress();
            handler.updatePrimaryShippingAddress();
        }
    }
}