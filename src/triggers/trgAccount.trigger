/**
 * Created by danielpulache on 11/30/17.
 */

trigger trgAccount on Account (after update, after insert) {
    trgAccountHandler handler = new trgAccountHandler(trigger.new, trigger.old, trigger.newMap, trigger.oldMap);
    if(trigger.isAfter) {
        if(trigger.isInsert){
            handler.createPrimaryAddressRecords();
        }
    }
    if(trigger.isAfter) {
        if (trigger.isUpdate) {
//            handler.updatePrimaryAddressRecords();
            handler.TrackPatientAddressInformation();
            handler.TrackLocationsLastPatientContactDate();
        } //else if(trigger.isInsert) {
//
//        }
    }
//    } else if(trigger.isBefore) {
//        if(trigger.isUpdate) {
//
//        } else if(trigger.isInsert) {
//
//        }
//    }
}