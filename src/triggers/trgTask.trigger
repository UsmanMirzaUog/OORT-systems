trigger trgTask on Task (before insert, after insert, before update, after update) {
    public static Set<Id> alreadyProcessed = new Set<Id>();
    trgTaskHandler handler = new trgTaskHandler(trigger.new, trigger.old, trigger.newMap, trigger.oldMap);

//    if (checkRecursive.runOnce()){
//    if (!alreadyProcessed.contains(trigger.New[0].Id)) {
        if (trigger.isBefore) {
            if (trigger.isInsert) {
                handler.groupTasksUnderLocationBasedOnAddress();
            } else if (trigger.isUpdate) {
                handler.groupTasksUnderLocationBasedOnAddress();
            }
        } else if (trigger.isAfter) { //trigger.isAfter
            if (trigger.isInsert) {
                System.debug('>>>>> Task Trigger::AFTER INSERT::Update Last Contact Date on Patient and update Location Num of Pts');
                handler.trackPatientLastContactDate();
                handler.updateNumberOfPatients();
                handler.updateRelatedRequests();
                handler.sendNoteToSolaraHub(Trigger.New);
                handler.updateTrackerIDOnOpp(Trigger.New);
                handler.setFollowUpDateOnOpp();
                handler.updateDexcomFields();
            } else if (trigger.isUpdate) {
                handler.updateNumberOfPatients();
                handler.updateFollowUpDate();
                if (checkRecursive.runOnce()) {
                    handler.updateADMCompletedRequest();
                }
            }
        }
//        trgTaskHandler.hasProcessed = true;


//        for (Task t : trigger.New){
//            alreadyProcessed.add(t.Id);
//        }
//    }
}