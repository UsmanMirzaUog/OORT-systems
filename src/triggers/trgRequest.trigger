/**
 * Created by isaac on 4/22/18.
 */

trigger trgRequest on Request__c (after insert, after update) {
    trgRequestHandler handler = new trgRequestHandler(trigger.new, trigger.old, trigger.newMap, trigger.oldMap);
 //KHB   if (trgRequestHandler.hasProcessed == false) {
//    if (checkRecursive.runOnce()) {
        if (trigger.isAfter) {
            if (trigger.isInsert) {
                handler.updateTasks(); // Trigger recalc of Location's Num_of_Patients
            }
            if (trigger.isUpdate) {
//                if (checkRecursive.runOnce()) {
                    handler.updateTasks(); // Trigger recalc of Location's Num_of_Patients
//                }
            }
        }
//    }
}