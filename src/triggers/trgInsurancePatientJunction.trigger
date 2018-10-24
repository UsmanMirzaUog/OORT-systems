/**
 * Created by krizia on 8/1/18.
 */

trigger trgInsurancePatientJunction on Insurance_Patient_Junction__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    System.debug('trgInsurancePatientJunction::: entered trigger');
    trgInsurancePatientJunctionHandler handler = new trgInsurancePatientJunctionHandler();


    if (Trigger.isBefore) {

    } else {//Trigger.isAfter
        if (Trigger.isInsert) {
            System.debug('trgInsurancePatientJunction::: after insert');
            trgInsurancePatientJunctionHandler.checkActiveStatus(Trigger.new, Trigger.newMap);
        } else if (Trigger.isUpdate) {
            System.debug('trgInsurancePatientJunction::: after update');
            if (checkRecursive.runOnce()) {
                System.debug('trgInsurancePatientJunction::: after update within recursive check and will run checkActiveStatus');
                trgInsurancePatientJunctionHandler.checkActiveStatus(Trigger.new, Trigger.newMap);
            }
        }
    }
}