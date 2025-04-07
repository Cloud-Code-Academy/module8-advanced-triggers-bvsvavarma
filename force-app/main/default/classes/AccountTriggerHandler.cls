public class AccountTriggerHandler extends TriggerHandler{
    public override void beforeInsert(){
        AccountHelper.setTypeProspect(Trigger.new);
        AccountHelper.addressCopy(Trigger.new);
        AccountHelper.setRating(Trigger.new);
    } 
    public override void afterInsert(){
        AccountHelper.defaultContact(Trigger.old);
    }
}