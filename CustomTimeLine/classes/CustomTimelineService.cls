public with sharing class CustomTimelineService {

    private final String profileName;
    private Boolean hasTask;
    private Boolean hasEvent;
    private Boolean hasEmail;

    public CustomTimelineService(String profileName) {
        List<ProfileTimeLine__c> pts = [SELECT Id, ProfileName__c, HasEmail__c, HasEvent__c, HasTask__c FROM ProfileTimeLine__c WHERE ProfileName__c = :profileName];
        if (pts.size() > 0) {
            this.hasTask  = pts[0].HasTask__c;
            this.hasEvent = pts[0].HasEvent__c;
            this.hasEmail = pts[0].HasEmail__c;
        } else {
            System.debug('Todos são all');
            this.hasTask  = true;
            this.hasEvent = true;
            this.hasEmail = true;
        }
    }

    public List<TimelineItem> get(Id recordId, String objectType) {

        List<TimelineItem> items = new List<TimelineItem>();

        switch on objectType {
            when 'Account' {
                if (this.hasTask) { items.addAll( buildTaskItems(   getAccountTasks (recordId) ) );}
                if (this.hasEvent) { items.addAll( buildEventItems(  getAccountEvents(recordId) ) );}
                if (this.hasEmail) { items.addAll( buildEmailItems(  getAccountEmails(recordId) ) );}
                
            }
            when 'Contact' {
                if (this.hasTask) { system.debug('Contact task'); items.addAll( buildTaskItems(   getContactTasks (recordId) ) );}
                if (this.hasEvent) { system.debug('Contact event'); items.addAll( buildEventItems(  getContactEvents(recordId) ) );}
                if (this.hasEmail) { system.debug('Contact email'); items.addAll( buildEmailItems(  getContactEmails(recordId) ) );}
            }
            when else {                      
                if (this.hasTask) { items.addAll( buildTaskItems(   getCaseTasks (recordId) ) );}
                if (this.hasEvent) { items.addAll( buildEventItems(  getCaseEvents(recordId) ) );}
                if (this.hasEmail) { items.addAll( buildEmailItems(  getCaseEmails(recordId) ) );}
            }
        }

        items.sort(); 
        return items;
    }

    private List<EmailMessage> getAccountEmails(Id accountId) {

        Set<Id> contactIds = new Map<Id, Contact>(
            [SELECT Id FROM Contact WHERE AccountId = :accountId]
        ).keySet();

        Set<Id> emailTaskIds = contactIds.isEmpty()
            ? new Set<Id>()
            : new Map<Id, Task>(
                  [SELECT Id
                     FROM Task
                    WHERE WhoId IN :contactIds
                      AND TaskSubtype = 'Email']
              ).keySet();

        return [
            SELECT  Id, Subject, FromAddress, CreatedDate, TextBody,
                    FromName, ToAddress, HtmlBody,
                    CreatedBy.Account.Name, CreatedBy.Contact.Name,
                    CreatedBy.Name, RelatedToId, ParentId
              FROM  EmailMessage
             WHERE  RelatedToId = :accountId
                 OR RelatedToId IN :contactIds
                 OR ActivityId  IN :emailTaskIds
             ORDER BY CreatedDate DESC
             LIMIT 100
        ];
    }
    private List<Task> getAccountTasks(Id accountId) {

        Set<Id> contactIds = new Map<Id, Contact>(
            [SELECT Id FROM Contact WHERE AccountId = :accountId]
        ).keySet();

        return [
            SELECT  Id, Subject, Description, ActivityDate, CreatedDate,
                    Owner.Name, Status, Priority, WhatId, WhoId
              FROM  Task
             WHERE  TaskSubtype IN ('Task','Call')
                AND (WhatId = :accountId OR  WhoId IN :contactIds)
             ORDER BY CreatedDate DESC
             LIMIT 100
        ];
    }
    private List<Event> getAccountEvents(Id accountId) {

        Set<Id> contactIds = new Map<Id, Contact>(
            [SELECT Id FROM Contact WHERE AccountId = :accountId]
        ).keySet();

        return [
            SELECT  Id, Subject, Description, StartDateTime, ActivityDate,
                    CreatedDate, Owner.Name, Location, WhatId, WhoId
              FROM  Event
             WHERE  WhatId = :accountId
                OR  WhoId IN :contactIds
             ORDER BY CreatedDate DESC
             LIMIT 100
        ];
    }

    private List<EmailMessage> getContactEmails(Id contactId) {

        Set<Id> emailTaskIds = new Map<Id, Task>(
            [SELECT Id
               FROM Task
              WHERE WhoId = :contactId
                AND TaskSubtype = 'Email']
        ).keySet();

        return [
            SELECT  Id, Subject, FromAddress, CreatedDate, TextBody,
                    FromName, ToAddress, HtmlBody,
                    CreatedBy.Account.Name, CreatedBy.Contact.Name,
                    CreatedBy.Name, RelatedToId, ParentId
              FROM  EmailMessage
             WHERE  RelatedToId = :contactId
                 OR ActivityId  IN :emailTaskIds
             ORDER BY CreatedDate DESC
             LIMIT 50
        ];
    }
    private List<Task> getContactTasks(Id contactId) {

        return [
            SELECT  Id, Subject, Description, ActivityDate, CreatedDate,
                    Owner.Name, Status, Priority, WhatId, WhoId, IsClosed
              FROM  Task
             WHERE  WhoId =: contactId
               AND  TaskSubtype IN ('Task','Call')
             ORDER BY CreatedDate DESC
             LIMIT 50
        ];
    }
    private List<Event> getContactEvents(Id contactId) {

        return [
            SELECT  Id, Subject, Description, StartDateTime, ActivityDate,
                    CreatedDate, Owner.Name, Location, WhatId, WhoId
              FROM  Event
             WHERE  WhoId = :contactId
             ORDER BY CreatedDate DESC
             LIMIT 50
        ];
    }
    private List<EmailMessage> getCaseEmails(Id recordId) {
        return [
            SELECT  Id, Subject, FromAddress, CreatedDate, TextBody,
                    FromName, ToAddress, HtmlBody,
                    CreatedBy.Account.Name, CreatedBy.Contact.Name,
                    CreatedBy.Name, RelatedToId, ParentId
              FROM  EmailMessage
             WHERE  RelatedToId = :recordId
                 OR ParentId    = :recordId
             ORDER BY CreatedDate DESC
             LIMIT 50
        ];
    }
    private List<Task> getCaseTasks(Id recordId) {
        return [
            SELECT  Id, Subject, Description, ActivityDate, CreatedDate,
                    Owner.Name, Status, Priority, WhatId, WhoId
              FROM  Task
             WHERE  WhatId = :recordId
             ORDER BY CreatedDate DESC
             LIMIT 50
        ];
    }
    private List<Event> getCaseEvents(Id recordId) {
        return [
            SELECT  Id, Subject, Description, StartDateTime, ActivityDate,
                    CreatedDate, Owner.Name, Location, WhatId, WhoId
              FROM  Event
             WHERE  WhatId = :recordId
             ORDER BY CreatedDate DESC
             LIMIT 50
        ];
    }
    private List<TimelineItem> buildEmailItems(List<EmailMessage> emails) {
        List<TimelineItem> listOut = new List<TimelineItem>();
        for (EmailMessage em : emails) listOut.add( createEmailItem(em) );
        return listOut;
    }
    private List<TimelineItem> buildTaskItems(List<Task> tasks) {
        List<TimelineItem> listOut = new List<TimelineItem>();
        for (Task t : tasks) listOut.add( createTaskItem(t) );
        return listOut;
    }
    private List<TimelineItem> buildEventItems(List<Event> events) {
        List<TimelineItem> listOut = new List<TimelineItem>();
        for (Event e : events) listOut.add( createEventItem(e) );
        return listOut;
    }
    private static TimelineItem createEmailItem(EmailMessage em) {

        TimelineItem ti = new TimelineItem();
        ti.id    = em.Id;
        ti.type  = 'Email';
        ti.title = String.isBlank(em.Subject)
                   ? 'Email: ' + em.FromAddress + ' – ' + em.ToAddress
                   : em.Subject;
        ti.occurDateTime = em.CreatedDate;
        ti.link   = '/' + em.Id;

        ti.owner =
              !String.isBlank(em.FromName)                       ? em.FromName
            : (em.CreatedBy.Contact != null &&
               !String.isBlank(em.CreatedBy.Contact.Name))       ? em.CreatedBy.Contact.Name
            : (em.CreatedBy.Account != null &&
               !String.isBlank(em.CreatedBy.Account.Name))       ? em.CreatedBy.Account.Name
            : em.CreatedBy.Name;

        ti.body      = !String.isBlank(em.HtmlBody) ? em.HtmlBody
                    : !String.isBlank(em.TextBody)  ? em.TextBody
                    : '(no text)';
        ti.isHtml    = !String.isBlank(em.HtmlBody);
        ti.fromEmail = em.FromAddress;
        ti.toEmail   = em.ToAddress;
        ti.fromEmailHref = em.FromAddress != null ? 'mailto:' + em.FromAddress : null;
        ti.toEmailHref   = em.ToAddress   != null ? 'mailto:' + em.ToAddress   : null;
        ti.isRelated = !String.isBlank(em.RelatedToId);
        ti.isOpened  = false;
        ti.isReply  = (em.ParentId == null) ? false : true;

        ti.iframeUrl = System.Label.Base_Org_URL +
                       '/apex/EmailMessagePreview?id=' + em.Id;
        ti.formattedDateTime = formatDate(ti.occurDateTime);
        return ti;
    }
    private static TimelineItem createTaskItem(Task t) {

        TimelineItem ti = new TimelineItem();
        ti.id    = t.Id;
        ti.type  = 'Task';
        ti.title = String.isBlank(t.Subject) ? 'Task' : t.Subject;
        ti.occurDateTime =
              t.ActivityDate != null
            ? DateTime.newInstance(t.ActivityDate, Time.newInstance(0,0,0,0))
            : null;
        ti.link  = '/' + t.Id;
        ti.owner = t.Owner != null ? t.Owner.Name : '';
        ti.body  = String.isBlank(t.Description) ? '(no description)' : t.Description;

        ti.isHtml   = false;
        ti.isRelated = (t.WhatId != null);
        ti.isOpened  = false;
        ti.formattedDateTime = formatDate(ti.occurDateTime);
        ti.isClosed  = t.IsClosed;
        return ti;
    }
    private static TimelineItem createEventItem(Event e) {

        TimelineItem ti = new TimelineItem();
        ti.id    = e.Id;
        ti.type  = 'Event';
        ti.title = String.isBlank(e.Subject) ? 'Event' : e.Subject;
        ti.occurDateTime =
              e.StartDateTime != null ? e.StartDateTime
            : e.ActivityDate  != null ? DateTime.newInstance(e.ActivityDate,
                                                             Time.newInstance(0,0,0,0))
            : e.CreatedDate;
        ti.link  = '/' + e.Id;
        ti.owner = e.Owner != null ? e.Owner.Name : '';
        ti.body  = String.isBlank(e.Description) ? '(no description)' : e.Description;

        ti.isHtml   = false;
        ti.isRelated = (e.WhatId != null);
        ti.isOpened  = false;
        ti.formattedDateTime = formatDate(ti.occurDateTime);
        return ti;
    }
    private static String formatDate(DateTime dt) {
        return dt == null ? ''
             : dt.format('MMM d, yyyy h:mm a', 'America/Sao_Paulo');
    }
    public class TimelineItem implements Comparable {

        public String   id;
        public String   type;
        public String   title;
        public DateTime occurDateTime;
        public String   link;
        public String   owner;
        public String   body;
        public Boolean  isOpened;
        public String   fromEmail;
        public String   toEmail;
        public String   fromEmailHref;
        public String   toEmailHref;
        public Boolean  isHtml;
        public Boolean  isRelated;
        public String   iframeUrl;
        public String   formattedDateTime;
        public Boolean  isClosed;
        public Boolean  isReply;

        /* Construtor padrão */
        public TimelineItem() {}

        /* Ordenação decrescente por data/hora */
        public Integer compareTo(Object o) {
            TimelineItem other = (TimelineItem)o;
            if (this.occurDateTime == other.occurDateTime) return 0;
            return this.occurDateTime > other.occurDateTime ? -1 : 1;
        }
    }
}