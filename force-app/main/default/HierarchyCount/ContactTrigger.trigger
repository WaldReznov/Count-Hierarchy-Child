/**
 * Created by Uladzislau Yarshou on 30.09.21
**/

trigger ContactTrigger on Contact (after insert, after update, after delete, after undelete) {
	if(Trigger.isAfter && Trigger.isInsert) {
		ContactTriggerHandler.afterInsert(Trigger.oldMap, Trigger.newMap);
	} else if(Trigger.isAfter && Trigger.isUpdate) {
		ContactTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
	} else if(Trigger.isAfter && Trigger.isDelete) {
		ContactTriggerHandler.afterDelete(Trigger.newMap, Trigger.oldMap);
	}
}