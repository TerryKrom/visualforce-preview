import { LightningElement, track, api } from 'lwc';
import { NavigationMixin }         from 'lightning/navigation';
import getTimeline                 from '@salesforce/apex/CustomTimelineController.getTimeline';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";

export default class CustomTimeline extends NavigationMixin(LightningElement) {
  @api recordId;
  @api objectType;

  @track showConfirmModal = false;
  emailToDelete = null;

  @track data = {
    UpcomingOverdue: { items: [] },
    Timeline: []
  };

  connectedCallback() {
    this.loadTimeline();
  }

  loadTimeline() {
    getTimeline({
      recordId:   this.recordId,
      objectType: this.objectType
    })
    .then(result => {
      this.data = result
        ? result
        : { UpcomingOverdue: { items: [] }, Timeline: [] };
    })
    .catch(error => {
      console.error('Error getting timeline', error);
      this.data = { UpcomingOverdue: { items: [] }, Timeline: [] };
    });
  }

  get hasData() {
    return (
      this.data.UpcomingOverdue.items.length > 0 ||
      this.data.Timeline.some(sec => sec.items.length > 0)
    );
  }

  handleIsAccordeonOpen(event) {
    const sectionLabel = event.currentTarget.dataset.month;
    this.data = {
      ...this.data,
      Timeline: this.data.Timeline.map(sec => {
        if (sec.label === sectionLabel) {
          return { ...sec, isOpen: !sec.isOpen };
        }
        return sec;
      })
    };
  }

  handleEmailOpen(event) {
    const id = event.currentTarget.dataset.id;
    this.updateEmailItem(id, { isOpened: true });
  }

  handleEmailClose(event) {
    const id = event.currentTarget.dataset.id;
    this.updateEmailItem(id, { isOpened: false });
  }

  updateEmailItem(id, updates) {
    this.data = {
      ...this.data,
      Timeline: this.data.Timeline.map(sec => {
        const updatedItems = sec.items.map(item =>
          item.id === id ? { ...item, ...updates } : item
        );
        return { ...sec, items: updatedItems };
      })
    };
  }

  handleAction(event) {
    const action        = event.detail.value;
    const emailMessageId = event.currentTarget.dataset.id;
    const quickActionByMode = {
      reply:    'EmailMessage._Reply',
      replyAll: 'EmailMessage._ReplyAll'
    };
    const apiName = quickActionByMode[action];
    if (!apiName) { return; }

    this[NavigationMixin.Navigate]({
      type:       'standard__quickAction',
      attributes: { apiName },
      state:      { recordId: emailMessageId }
    });
  }

  handleSendEmail() {
    const pageRef = {
      type:       'standard__quickAction',
      attributes: { apiName: 'Global.SendEmailCustom' },
      state:      {
        recordId:           this.recordId,
        defaultFieldValues: encodeDefaultFieldValues({
          HtmlBody: "Pre-populated text for the email body.",
          Subject:  "Pre-populated Subject of the Email",
          To:       "target@example.com"
        })
      }
    };
    this[NavigationMixin.Navigate](pageRef);
  }
}
