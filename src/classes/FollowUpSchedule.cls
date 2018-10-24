public class FollowUpSchedule implements Schedulable {
    
    public void execute(SchedulableContext SC){
        Integer enqueuedJobs = [SELECT COUNT() FROM AsyncApexJob WHERE JobType='BatchApex' AND Status IN ('Processing','Preparing','Queued')] ;
        if (enqueuedJobs <5){
            FollowUpBatch batchone = new FollowUpBatch();
            database.executebatch(batchone,3);        
        }
    }
}