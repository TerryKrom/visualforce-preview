public with sharing class CustomTimelineController {

    public class UpcomingOverdue {
        @AuraEnabled public List<ItemDTO> items = new List<ItemDTO>();
    }
    public class MonthGroup {
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String subLabel;
        @AuraEnabled public Boolean isOpen;
        @AuraEnabled public List<ItemDTO> items = new List<ItemDTO>();
    }
    public class ResponseDTO {
        @AuraEnabled public UpcomingOverdue UpcomingOverdue;
        @AuraEnabled public List<MonthGroup> Timeline;
    }
    public class ItemDTO {
        @AuraEnabled public String id;
        @AuraEnabled public String title;
        @AuraEnabled public String link;
        @AuraEnabled public String type;
        @AuraEnabled public String icon;
        @AuraEnabled public String owner;
        @AuraEnabled public String dueLabel;
        @AuraEnabled public String formattedDate;
        @AuraEnabled public Boolean isOpened;
        @AuraEnabled public String fromEmail;
        @AuraEnabled public String fromEmailHref;
        @AuraEnabled public String toEmail;
        @AuraEnabled public String toEmailHref;
        @AuraEnabled public Boolean isHtml;
        @AuraEnabled public String iframeUrl;
        @AuraEnabled public String body;
        @AuraEnabled public Boolean isReply;
    }

    @AuraEnabled(cacheable=true)
    public static ResponseDTO getTimeline(Id recordId, String objectType) {

        String profileName = [SELECT Name
                                FROM Profile
                                WHERE Id = :UserInfo.getProfileId()].Name;

        CustomTimelineService svc = new CustomTimelineService(profileName);
        List<CustomTimelineService.TimelineItem> raw =
            svc.get(recordId, objectType);

        UpcomingOverdue up   = new UpcomingOverdue();
        Map<String,MonthGroup> monthMap = new Map<String,MonthGroup>();

        Date today = Date.today();
        Integer todayYM = today.year()*12 + today.month();

        Boolean firstMonthDone = false;

        for (CustomTimelineService.TimelineItem it : raw) {

            if (it.type == 'Task' && it.isClosed == false) {

                ItemDTO dto = toDTO(it);
                
                if (it.occurDateTime != null) {
                    String labelDate = it.occurDateTime.format('MMM d', 'en_US');
                    if (it.occurDateTime.date() < today)
                        dto.dueLabel = 'Overdue ' + labelDate;
                    else
                        dto.dueLabel = 'Due ' + labelDate;
                } else {
                    dto.dueLabel = 'No date';
                }
                dto.icon = 'standard:task';
                up.items.add(dto);
                continue;
            }

            if (it.occurDateTime == null) continue; // segurança

            DateTime dt = it.occurDateTime.dateGmt();
            Integer ym = dt.year()*12 + dt.month();
            Integer diff = todayYM - ym;            // 0 = mês atual, 1 = mês anterior…

            String key = String.valueOf(dt.year()) + String.valueOf(dt.month()).leftPad(2, '0');

            if (!monthMap.containsKey(key)) {
                MonthGroup g = new MonthGroup();
                g.name  = dt.format('MMMM', 'en_US').toLowerCase() + dt.format('yyyy');
                g.label = dt.format('MMMM', 'en_US').capitalize() + ' • ' + dt.year();
                g.subLabel =
                    (diff == 0) ? 'Actual Month'
                  : (diff == 1) ? 'Last Month'
                  : diff + ' Months Ago';
                g.isOpen = !firstMonthDone; // só o mais recente inicia aberto
                firstMonthDone = true;
                monthMap.put(key, g);
            }
            MonthGroup grp = monthMap.get(key);
            ItemDTO dto = toDTO(it);
            dto.formattedDate = it.formattedDateTime;
            dto.icon = iconFor(it.type);
            dto.isReply = it.isReply;
            grp.items.add(dto);
        }

        /* 5. Ordena meses (desc) */
        List<String> sortedKeys = new List<String>(monthMap.keySet());
        sortedKeys.sort();
        
        List<MonthGroup> timeline = new List<MonthGroup>();
        for (Integer i = sortedKeys.size() - 1; i >= 0; i--) {   // descendente
            timeline.add(monthMap.get(sortedKeys[i]));
        }

        /* 6. Resultado final */
        ResponseDTO resp = new ResponseDTO();
        resp.UpcomingOverdue = up;
        resp.Timeline        = timeline;
        return resp;
    }

    /*──────────────────────────────────────────────────────────────
     * Helpers
     *────────────────────────────────────────────────────────────*/
    private static ItemDTO toDTO(CustomTimelineService.TimelineItem src) {
        ItemDTO d   = new ItemDTO();
        d.id        = src.id;
        d.title     = src.title;
        d.link      = src.link;
        d.type      = src.type;
        d.owner     = src.owner;
        d.isOpened  = src.isOpened;
        d.fromEmail = src.fromEmail;
        d.fromEmailHref = src.fromEmailHref;
        d.toEmail   = src.toEmail;
        d.toEmailHref   = src.toEmailHref;
        d.isHtml    = src.isHtml;
        d.iframeUrl = src.iframeUrl;
        d.body      = src.body;
        d.isReply   = src.isReply;
        return d;
    }

    private static String iconFor(String type) {
        switch on type {
            when 'Task'   { return 'standard:task'; }
            when 'Email'  { return 'standard:email'; }
            when 'Event'  { return 'standard:event'; }
            when else     { return 'standard:record'; }
        }
    }
}